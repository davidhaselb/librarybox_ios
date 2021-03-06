//DEPRECATED - test environment

import UIKit
import Foundation


class testBeacon
{
    var proximity: Int = 0
    var accuracy: Double = 0.0
    
    init(newProximity:Int, newAccuracy:Double)
    {
        self.proximity = newProximity
        self.accuracy = newAccuracy
    }
}


let beacon1 = testBeacon(newProximity: 1,newAccuracy: 3)
let beacon2 = testBeacon(newProximity: 1,newAccuracy: 8)
let beacon3 = testBeacon(newProximity: 1,newAccuracy: 14)
let beacon4 = testBeacon(newProximity: 2,newAccuracy: 30)
let beacon5 = testBeacon(newProximity: 2,newAccuracy: 55)
let beacon6 = testBeacon(newProximity: 0,newAccuracy: -2)

var beacons: [testBeacon] = [beacon1, beacon2, beacon3, beacon4, beacon5, beacon6]
var sortedBeacons = beacons.sortInPlace({ $0.accuracy < $1.accuracy})

class RangingView: UIView
{
    //labels
    //color adjustments
    @IBInspectable var endColor: UIColor = UIColor.darkGrayColor()
    @IBInspectable var startColor: UIColor = UIColor.lightGrayColor()
    @IBInspectable let shadow:UIColor = UIColor.blackColor().colorWithAlphaComponent(0.80)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?;!(coder aDecoder: NSCoder) {

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        super.init(coder: aDecoder)!
    }
    
    func convertToLogScale(data: Double, screenY0:CGFloat, screenY1:CGFloat, dataY0:Double, dataY1:CGFloat) ->CGFloat{
        
        return screenY0 + (log(CGFloat(data)) - log(CGFloat(dataY0))) / (log(CGFloat(dataY1)) - log(CGFloat(dataY0))) * (screenY1 - screenY0)
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let startPGradient = CGPoint.zero
        let endPGradient = CGPoint(x:0, y:self.bounds.height)
        let startPoint: CGPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect)+25)
        let endPoint: CGPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect)-25)
        let context = UIGraphicsGetCurrentContext()
        let colors = [startColor.CGColor, endColor.CGColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations:[CGFloat] = [0.0, 1.0]
        let gradient = CGGradientCreateWithColors(colorSpace,
                                                  colors,
                                                  colorLocations)
        CGContextDrawLinearGradient(context,
                                    gradient,
                                    startPGradient,
                                    endPGradient,
                                    CGGradientDrawingOptions.DrawsAfterEndLocation)
        CGContextSaveGState(context)
        let flipVertical:CGAffineTransform = CGAffineTransformMake(1,0,0,-1,0,rect.size.height)
        CGContextConcatCTM(context, flipVertical)
        let shadowOffset = CGSizeMake(2.0, 2.0)
        let shadowBlurRadius: CGFloat = 5
        CGContextSetShadowWithColor(context,
                                    shadowOffset,
                                    shadowBlurRadius,
                                    shadow.CGColor)
        CGContextBeginTransparencyLayer(context, nil)
        let linePath: UIBezierPath = UIBezierPath()
        linePath.moveToPoint(startPoint)
        linePath.addLineToPoint(endPoint)
        linePath.lineWidth = 6.0
        linePath.lineCapStyle = CGLineCap.Round
        UIColor.whiteColor().setStroke()
        linePath.stroke()
        
        for aBeacon in sortedBeacons
        {
            if(aBeacon.accuracy >= 0.0)
            {
                print(aBeacon.accuracy)
                let beaconY: CGFloat = self.convertToLogScale(aBeacon.accuracy, screenY0:startPoint.y, screenY1:endPoint.y, dataY0:1.0, dataY1:80.0)
                print(beaconY)
                let centerPoint = CGPointMake(CGRectGetMidX(rect), beaconY)
                var startAngle: CGFloat = CGFloat(Float(2 * M_PI))
                var endAngle: CGFloat = 0.0
                let strokeWidth: CGFloat = 3.0
                let radius = CGFloat((CGFloat(rect.size.width/5) - CGFloat(strokeWidth)) / 2)
                UIColor.whiteColor().setStroke()
                print(aBeacon.proximity)
                switch aBeacon.proximity {
                case 0:
                    UIColor.clearColor().setFill()
                case 1:
                    UIColor.blueColor().setFill()
                case 2:
                    UIColor.lightGrayColor().setFill()
                default:
                    UIColor.clearColor().setFill()
                }
                startAngle = startAngle - CGFloat(Float(M_PI_2))
                endAngle = endAngle - CGFloat(Float(M_PI_2))
                let circlePath: UIBezierPath = UIBezierPath()
                circlePath.addArcWithCenter(centerPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                circlePath.lineWidth=strokeWidth
                circlePath.fill()
                circlePath.stroke()
            }
        }
        CGContextEndTransparencyLayer(context)
        CGContextRestoreGState(context)
    }
}


let myView = RangingView(frame:CGRectMake(0,0,150,600))
