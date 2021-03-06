//
//  LBMapPinningTableViewController.swift
//  LibraryBox
//
//  Created by David Haselberger on 03/06/16.
//  Copyright © 2016 Evenly Distributed LLC. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import AddressBookUI
import CloudKit

//AeroGearOAuth2 library used for authenticating to Google Fusion Table Service
//import AeroGearHttp
//import AeroGearOAuth2

import PKHUD


protocol LBAddressPinningDelegate
{
    func pinningSuccessful()
}

///UITableViewController class to manage static UITableView for pinning LibraryBox addresses. Checks if address in textview is valid placemark, if there is already a LibraryBox pinned to the current location - and enables to pin a location if a valid, unique address is found for pinning.
class LBMapPinningTableViewController: UITableViewController
{
    //Outlets to views in static tableview cells
    @IBOutlet weak var boxAddress: UITextView!
    @IBOutlet weak var boxTypeSelection: UISegmentedControl!
    @IBOutlet weak var pinButton: UIButton!
    @IBOutlet weak var boxAddressFeedback: UILabel!
    
    ///The current location of the user (received through "prepareForSegue" in LBMainViewController)
    var currentLocationOfUser: CLLocation!
    
    ///The current box map annotations (received through "prepareForSegue" in LBMainViewController)
    var currentBoxLocations: [MKAnnotation] = []
    
    //A placemark that is received by checking the current location
    var placemarkForPinning: CLPlacemark!

    //The http request of AeroGearOAuth2
    //var http: Http!
    
    var delegate: LBAddressPinningDelegate?
    
    /**
     Setup of navigation bar, gesture recognizer to hide keyboard on tapping outside of textview, pinning button. Checks if there is a current user location. If so, tries to retrieve a placemark from it.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Navigation bar setup
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(cancelPinning))
        self.navigationItem.rightBarButtonItem = cancelButton
        self.navigationItem.title = "Box Address"
        
        //Tap gesture recognizer to hide keyboard when tapping outside of textview
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.tableView.addGestureRecognizer(gestureRecognizer)
        
        //Sets pinning button enabled boolean to false.
        self.pinButton.isEnabled = false
        
        //Sets the delegate of the textview to self.
        self.boxAddress.delegate = self
        
        //check if there is a current location of the user. If so, try to get a placemark for the location.
        if currentLocationOfUser != nil
        {
            self.getPlacemarkFromLocation(location: currentLocationOfUser)
        }
        
        //Instantiate http class of AeroGearHttp framework and assign to variable http.
        //http = Http()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /**
     Function to hide keyboard on tap outside of textview.
    */
    func hideKeyboard()
    {
        self.boxAddress.resignFirstResponder()
    }
    
    /**
     Retrieves a placemark from a location. The address of the placemark is presented on the textview. The function validateAddressText() is called.
    */
    func getPlacemarkFromLocation(location: CLLocation){
        if let theLoc: CLLocation = location
        {
            CLGeocoder().reverseGeocodeLocation(theLoc, completionHandler:
                {(placemarks, error) in
                    if (error != nil) {print("reverse geocode fail: \(error!.localizedDescription)")}
                    let pm = placemarks! as [CLPlacemark]
                    if pm.count > 0 {
                        let addressString = self.getAddressFromPlaceMark(unsafePlaceMark: pm[0])
                        self.boxAddress.text = addressString
                        self.validateAddressText()
                    }
            })
        }
    }
    
    /**
     Returns an (optional) address string from a CLPlacemark.
     
     - returns: (optional) address string from a CLPlacemark
    */
    func getAddressFromPlaceMark(unsafePlaceMark: CLPlacemark? )->String?{
        if let placeMark = unsafePlaceMark{
            if let address=placeMark.addressDictionary?["FormattedAddressLines"] as? [String]
            {
                let addressString = address.joined(separator: ",")
                return addressString
            }
        }
        return nil
    }
    
    /**
     Dismisses the view controller. In the completion handler, the Google Fusion Table service is called via REST API to set a new row record. If no authentication with a Google account happened yet, users are taken to Safari to authenticate online.
     */
    @IBAction func pinBox(sender: UIButton) {
        if let locationForPinning = self.placemarkForPinning.location
        {
            delay(delay: 0.1)
            {
                HUD.show(.progress)
            }
            let recordType: String = "BoxLocations"
            let myRecord = CKRecord(recordType: recordType)
            if let recordAddress: String = self.getAddressFromPlaceMark(unsafePlaceMark: self.placemarkForPinning)!
            {
                if(!recordAddress.isEmpty)
                {
                    myRecord.setObject(recordAddress as CKRecordValue, forKey:"Address")
                }
            }
            if let type:String = self.boxTypeSelection.titleForSegment(at: self.boxTypeSelection.selectedSegmentIndex)!
            {
                    if(!type.isEmpty)
                    {
                        myRecord.setObject(type as CKRecordValue, forKey:"BoxType")
                    }
            }
            if let location: CLLocation = locationForPinning
            {
                myRecord.setObject(location, forKey:"Location")
            }
            let publicDatabase = CKContainer.default().publicCloudDatabase
            publicDatabase.save(myRecord) { record, error in
                DispatchQueue.main.async() {
                    if error == nil{
                        print("success")
                    }
                    
                    if let error = error where error.code == 14 {
                        publicDatabase.fetch(withRecordID: myRecord.recordID) {
                            rec, nsError  in
                            
                            if let rec = rec {
                                for key in myRecord.allKeys() {
                                    rec[key] = myRecord[key]
                                    //                                rec.setObject(myRecord.objectForKey(key), forKey:"key")
                                }
                                //
                                publicDatabase.save(myRecord) {
                                    record, error in
                                    
                                    self.processResult(record: rec, error: nsError as! NSError)
                                    
                                }
                            }
                        }
                    } else {
                        self.processResult(record: record, error: error as! NSError)
                    }
                    
                }
            }
//            let googleConfig = GoogleConfig(
//
//                //LBGoogleAPIAccessService.clientId() returns the client ID of the service for the app in the scope
//                clientId: LBGoogleAPIAccessService.clientId(),
//                scopes:["https://www.googleapis.com/auth/fusiontables"])
//            let gdModule =  OAuth2Module(config: googleConfig)
//            self.http.authzModule = gdModule
//            
//            //If access is granted, a new row is set in the Fusion Table associated with LibraryBox locations
//            gdModule.requestAccess { (response:AnyObject?, error:NSError?) -> Void in
//                
//                //The acces API key of the app to the service
//                let accessKey:String = LBGoogleAPIAccessService.accessKey()
//                
//                //The content of the Description column in the Fusion Table row
//                let addressTitle:String = self.getAddressFromPlaceMark(self.placemarkForPinning)!
//                
//                //The content of the type column in the Fusion Table row
//                let type:String = self.boxTypeSelection.titleForSegmentAtIndex(self.boxTypeSelection.selectedSegmentIndex)!
//                
//                //The SQL query to add the new row in Fusion Table (INSERT INTO table-id (Column, *) VALUES (Value for column, *)
//                let sqlQuery:String = "INSERT INTO 1ICTFk4jdIZIneeHOvhWOcvsZxma_jSqcAWNwuRlK (Description, Latitude, Longitude, Type) VALUES ('\(addressTitle)',\(locationForPinning.coordinate.latitude),\(locationForPinning.coordinate.longitude),'\(type)');"
//                
//                //Transfer sqlQuery string to a URL query string
//                let queryURL: String = sqlQuery.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
//                
//                //The complete URL path string for the Fusion Table query
//                let pathString:String = "https://www.googleapis.com/fusiontables/v2/query?sql=INSERT INTO 1ICTFk4jdIZIneeHOvhWOcvsZxma_jSqcAWNwuRlK (Description, Location, Type) VALUES ('\(addressTitle)', '\(locationForPinning.coordinate.latitude), \(locationForPinning.coordinate.longitude)', '\(type)');&key=\(accessKey)".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
//                
//                //The http request to the REST API of the Fusion Table service
//                self.http.request(.POST, path: pathString, parameters: ["sql":queryURL, "key":accessKey], credential: nil, responseSerializer: StringResponseSerializer(), completionHandler: {(response, error) in
//                    
//                    //Error checking for http request
//                    if (error != nil) {
//                        delay(0.1)
//                        {
//                            HUD.hide()
//                        }
//                        let alert:UIAlertController = UIAlertController(title: "Error", message: "\(error)", preferredStyle: UIAlertControllerStyle.Alert)
//                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
//                        self.presentViewController(alert, animated: true, completion: nil)
//                        print("Error uploading file: \(error)")
//                    } else {
//                        HUD.flash(.Success, delay: 1.0)
//                        self.delegate?.pinningSuccessful()
//                        delay(2.0)
//                        {
//                            HUD.hide()
//                            print("Successfully posted: " + response!.description)
//                            self.dismissViewControllerAnimated(true, completion:{
//                            })
//                        }
//                    }
//                })
//            }
        }
        
    }
    
    func processResult(record: CKRecord?, error: NSError?) {

        HUD.flash(.success, delay: 1.0)
            self.delegate?.pinningSuccessful()
        delay(delay: 2.0)
            {
                HUD.hide()
                print("Successfully posted!")
                self.dismiss(animated: true, completion:{
                })
            }
    }
    
    /**
     Dismiss the tableview controller
    */
    @IBAction func cancelPinning()
    {
        self.dismiss(animated: true, completion:{
            
        })

    }
    
    
    /**
     Address text in the text view is checked for validity.
     */
    func validateAddressText()
    {
        let addressText = self.boxAddress.text
        
        //Data detection for text view string -> addresses found are added to an array of String dictionaries
        let types: NSTextCheckingResult.CheckingType = [.address]
        let detector = try? NSDataDetector(types: types.rawValue)
        var addresses: [[NSTextCheckingKey:String]] = []
        detector?.enumerateMatches(in: addressText!, options: [], range: NSMakeRange(0, (addressText as! NSString).length)) { (result, flags, _) in
            addresses.append((result?.addressComponents)!)
            print(result?.addressComponents)
        }
        
        //If the address array is not empty, look up, if a CLPlacemark can be retrieved from the first address in the array
        if(addresses.count > 0)
        {
            CLGeocoder().geocodeAddressDictionary(addresses[0], completionHandler: {(placemarks, error) in
                if (error != nil) {print("forward geodcode fail: \(error!.localizedDescription)")}
                let pm = placemarks! as [CLPlacemark]
                if pm.count > 0 {
                    
                    //if more placemarks can be found, use the first one found
                    if let currentAddress = self.getAddressFromPlaceMark(unsafePlaceMark: pm[0])
                    {
                        
                        //check if the placemark is already pinned on the map, if not update feedback label and enable the pinning button
                        if !self.checkForDublicatePinning(place: pm[0])
                        {
                            self.updateAddressFeedback(text: "\u{2705} '\(currentAddress)' valid")
                            self.placemarkForPinning = pm[0]
                            self.pinButton.isEnabled = true
                            
                        } else
                        {
                            if(self.currentBoxLocations.count < 1)
                            {
                                self.updateAddressFeedback(text: "\u{274C} Currently no box locations available. Please try again later")
                            }
                            else
                            {
                            //if a pin is found at the location, the user is informed and the pinning button not enabled
                                self.updateAddressFeedback(text: "\u{274C} '\(currentAddress)' already on map")
                                self.pinButton.isEnabled = false
                            }
                        }
                    }else
                    {
                        //if no valid placemark can be retrieved, the user is informed and the pinning button not enabled
                        self.updateAddressFeedback(text: "\u{274C} No valid address found")
                        self.pinButton.isEnabled = false
                    }
                }
            })
        }else
        {
            //if no  address can be retrieved, the user is informed and the pinning button not enabled
            self.updateAddressFeedback(text: "\u{274C} No valid address found")
            self.pinButton.isEnabled = false
        }
    }
    
    /**
     Returns a bool signifying if the location is already annotated on the map. 
     
     - returns: Bool signifying if the location is already annotated on the map -> true if it is, false if it is not
     */
    func checkForDublicatePinning(place: CLPlacemark) -> Bool
    {
        var isDublicate: Bool = true
        for boxLoc in currentBoxLocations
        {
            let locationOfPlace = place.location
            let pinLoc = CLLocation(latitude: boxLoc.coordinate.latitude, longitude: boxLoc.coordinate.longitude)
            if let distance = locationOfPlace?.distance(from: pinLoc)
            {
                if (distance < 15.0)
                {
                    isDublicate = true
                    break
                }
                else
                {
                    isDublicate = false
                }
            }
        }
        return isDublicate
    }
    
    /**
     Update the text label that presents the user feedback
    */
    func updateAddressFeedback(text: String)
    {
        boxAddressFeedback.text=text
    }
    
}



///Delegate functions of UITextView -> set pinButton enabled attribute to false when editing, validate the address entered when editing ended.
extension LBMapPinningTableViewController: UITextViewDelegate
{

    func textViewDidBeginEditing(textView: UITextView) {
        self.pinButton.isEnabled = false
    }
    
    
    func textViewDidEndEditing(textView: UITextView) {
        self.validateAddressText()
    }

}
