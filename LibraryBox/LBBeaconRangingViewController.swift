//
//  LBBeaconRangingViewController.swift
//  LibraryBox
//
//  Created by David Haselberger on 23/05/16.
//  Copyright © 2016 Evenly Distributed LLC. All rights reserved.
//

import Foundation
import UIKit


///View controller class for the custom beacon ranging view
class LBBeaconRangingViewController: UIViewController
{
    /**
     Checks device orientation when loaded by calling self.checkOrientation()
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkOrientation()
    }
    
    /**
     Calls self.view.setNeedsDisplay() to redraw graphics context.
    */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.setNeedsDisplay()
    }
    
    /**
     Checks device orientation after rotating the device.
    */
    override func viewWillTransitionToSize(size: CGSize,
                                           withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        // Code here will execute before the rotation begins.
        // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
        coordinator.animateAlongsideTransition({ (context) -> Void in
        },
        completion: { (context) -> Void in
            self.checkOrientation()
            // Code here will execute after the rotation has finished.
                                                // Equivalent to placing it in the deprecated method -[didRotateFromInterfaceOrientation:]
        }) }

    
        /**
        Checks device orientation to calculate y-axis offset.
        */
        private func checkOrientation()
        {
            let orientation: UIInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
            let aView = self.view as? LBBeaconRangingView
            switch orientation
            {
            case UIInterfaceOrientation.Portrait:
                aView!.yOffset = 80.0
            case UIInterfaceOrientation.LandscapeLeft:
                aView!.yOffset = 40.0
            case UIInterfaceOrientation.LandscapeRight:
                aView!.yOffset = 40.0
            default:
                aView!.yOffset = 80.0
            }
            self.view.setNeedsDisplay()
        }
    
}