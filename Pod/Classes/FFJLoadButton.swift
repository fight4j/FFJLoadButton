//
//  FFJLoadButton.swift
//  FFJLoadButton
//
//  Created by zhang on 1/5/16.
//  Copyright © 2016 zhang. All rights reserved.
//

import UIKit

let kCircleFrameWidthRatio: CGFloat = 0.3
let kAnimationLoadFailKey = "animation_load_fali_key"
let kAnimationLoadFailValue = "animation_load_fali_value"

enum FFJLoadButtonStatus: Int {
    case Ready, Loading, LoadSucceed, LoadFailed
}

public class FFJLoadButton: UIButton {
    private var currentStatus: FFJLoadButtonStatus = .Ready
    private var isCircleAnimating = false
    
    private var titleLayer: CATextLayer!
    private var circleLayer: CAShapeLayer!
    private var circleLayerCenterPoint: CGPoint!
    private var circleLayerRadius: CGFloat!
    
    public var readyTitle       = "Initial Title" {
        didSet {
            if currentStatus == .Ready {
                titleLayer.string = readyTitle
            }
            self.updateTitleFrame()
            self.updateTitlePosition()
        }
    }
    public var loadingTitle     = "Loading..."
    public var loadSucceedTitle = "Success!"
    public var loadFailedTitle  = "Failed!"
    public var ffjTitleFont: UIFont! {
        didSet {
            self.updateTitleFrame()
            self.updateTitlePosition()
            titleLayer.font = CGFontCreateWithFontName(ffjTitleFont.fontName as CFString)
            titleLayer.fontSize = ffjTitleFont.pointSize
        }
    }
    
    // TODO: - font, convenience init, title frame, public, animation incomplete
    // MARK: - Life cycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.clipsToBounds = true

        self.titleLayer = createTitleLayer()
        self.ffjTitleFont = UIFont.systemFontOfSize(22)
        self.titleLayer.string = self.readyTitle
        self.layer.addSublayer(titleLayer)
        self.circleLayer = createCircleLayer()
        for subLayer in [titleLayer, circleLayer] {
            subLayer.contentsScale = UIScreen.mainScreen().scale
            subLayer.contentsGravity = kCAGravityCenter
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(resetCircleLoadAnimation), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func createTitleLayer() -> CATextLayer {
        let layer: CATextLayer = CATextLayer.init()
        layer.alignmentMode = kCAAlignmentCenter
        return layer
    }
    
    func createCircleLayer() -> CAShapeLayer {
        let width: CGFloat = CGRectGetWidth(self.frame)
        let height: CGFloat = CGRectGetHeight(self.frame)
        self.circleLayerRadius = min(width, height) / 2 * 0.7
        
        let circle: CAShapeLayer = CAShapeLayer.init()
        circle.frame = CGRectMake(0, 0, 2 * self.circleLayerRadius, 2 * self.circleLayerRadius)
        circle.position = CGPointMake(kCircleFrameWidthRatio * width - self.circleLayerRadius, height / 2)
        self.circleLayerCenterPoint = CGPointMake(CGRectGetMidX(circle.bounds), CGRectGetMidY(circle.bounds))
        circle.fillColor = UIColor.clearColor().CGColor
        circle.strokeColor = UIColor.whiteColor().CGColor
        circle.lineWidth = 1
        return circle
    }
    
    //MARK:- Public method
    public func startLoad() {
        self.currentStatus = .Loading
        self.pushTitleAnimation()
        CATransaction.setCompletionBlock { () -> Void in
            self.startCircleLoadAnimation()
        }
        self.updateTitlePosition()
        self.userInteractionEnabled = false
    }
    
    public func endLoad(success: Bool) {
        if success {
            self.currentStatus = .LoadSucceed
            self.stopCircleLoadAnimation()
            self.startTitleTransition(self.loadSucceedTitle)
            self.checkMarkDrawAnimation()
        }
        else {
            self.currentStatus = .LoadFailed
            self.stopCircleLoadAnimation()
            self.startTitleTransition(self.loadFailedTitle)
            self.exclamationMarkAnimation()
        }
        self.updateTitlePosition()
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            self.currentStatus = .Ready
            self.startTitleTransition(self.readyTitle)
            self.circleLayer.removeFromSuperlayer()
            self.updateTitlePosition()
            self.userInteractionEnabled = true
        }
    }
    
    // MARK: - Animations
    func pushTitleAnimation() {
        let transition: CATransition = CATransition()
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        self.titleLayer.actions = ["string": transition]
        CATransaction.setAnimationDuration(0.5)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseInEaseOut))
        self.titleLayer.string = self.loadingTitle
    }
    
    func startCircleLoadAnimation() {
        self.circleLayer.path = UIBezierPath.init(arcCenter: self.circleLayerCenterPoint, radius: self.circleLayerRadius, startAngle: 0, endAngle: CGFloat(2.0 * M_PI), clockwise: true).CGPath
        self.layer.addSublayer(self.circleLayer)
        
        let rotationAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = rotationAnimation.fromValue!.doubleValue + (2.0 * M_PI)
        rotationAnimation.duration = 2
        rotationAnimation.repeatCount = Float.infinity
        
        let headAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeStart")
        headAnimation.duration = 1.0
        headAnimation.fromValue = 0
        headAnimation.toValue = 0.15
        headAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let tailAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        tailAnimation.duration = 1.0
        tailAnimation.fromValue = 0
        tailAnimation.toValue = 1.0
        
        let endHeadAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeStart")
        endHeadAnimation.beginTime = 1.0
        endHeadAnimation.duration = 0.5
        endHeadAnimation.fromValue = 0.15
        endHeadAnimation.toValue = 1.0
        endHeadAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let animations: CAAnimationGroup = CAAnimationGroup()
        animations.duration = 1.5
        animations.animations = [headAnimation, tailAnimation, endHeadAnimation]
        animations.repeatCount = Float.infinity
        
        self.circleLayer.addAnimation(rotationAnimation, forKey: "animation_rotation")
        self.circleLayer.addAnimation(animations, forKey: "animation_stroke")
        
        self.isCircleAnimating = true
    }
    
    func stopCircleLoadAnimation() {
        if !self.isCircleAnimating {
            return
        }
        self.circleLayer.removeAllAnimations()
        self.isCircleAnimating = false
    }
    
    func resetCircleLoadAnimation() {
        if !self.isCircleAnimating {
            return
        }
        self.stopCircleLoadAnimation()
        self.startCircleLoadAnimation()
    }
    
    func checkMarkDrawAnimation() {
        let bezierPath: UIBezierPath = UIBezierPath.init(arcCenter: self.circleLayerCenterPoint, radius: self.circleLayerRadius, startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: true)
        let bounds: CGRect = self.circleLayer.bounds
        bezierPath.moveToPoint(CGPointMake(CGRectGetMinX(bounds) + 0.27083 * CGRectGetWidth(bounds), CGRectGetMinY(bounds) + 0.54167 * CGRectGetHeight(bounds)))
        bezierPath.addLineToPoint(CGPointMake(CGRectGetMinX(bounds) + 0.41667 * CGRectGetWidth(bounds), CGRectGetMinY(bounds) + 0.68750 * CGRectGetHeight(bounds)))
        bezierPath.addLineToPoint(CGPointMake(CGRectGetMinX(bounds) + 0.75000 * CGRectGetWidth(bounds), CGRectGetMinY(bounds) + 0.35417 * CGRectGetHeight(bounds)))
        bezierPath.lineCapStyle = .Square
        self.circleLayer.path = bezierPath.CGPath
        
        let pathAnimation: CABasicAnimation = CABasicAnimation.init(keyPath: "strokeEnd")
        pathAnimation.fromValue = 0
        pathAnimation.toValue = 1
        self.circleLayer.addAnimation(pathAnimation, forKey: "animation_strokeEnd")
    }
    
    func exclamationMarkAnimation() {
        let bezierPath: UIBezierPath = UIBezierPath.init(arcCenter: self.circleLayerCenterPoint, radius: self.circleLayerRadius, startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: true)
        let bounds: CGRect = self.circleLayer.bounds
        bezierPath.moveToPoint(CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds) + 0.15 * CGRectGetHeight(bounds)))
        bezierPath.addLineToPoint(CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds) + 0.65 * CGRectGetHeight(bounds)))
        bezierPath.moveToPoint(CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds) + 0.75 * CGRectGetHeight(bounds)))
        bezierPath.addLineToPoint(CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds) + 0.82 * CGRectGetHeight(bounds)))
        bezierPath.lineCapStyle = .Square
        self.circleLayer.path = bezierPath.CGPath
        
        let pathAnimation: CABasicAnimation = CABasicAnimation.init(keyPath: "strokeEnd")
        pathAnimation.fromValue = 0
        pathAnimation.toValue = 1
        pathAnimation.delegate = self
        pathAnimation.setValue(kAnimationLoadFailValue, forKey: kAnimationLoadFailKey)
        self.circleLayer.addAnimation(pathAnimation, forKey:"animation_load_fail")
    }
    
    func exclamationMarkShakeAnimation() {
        let rotationAnimation = CABasicAnimation.init(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = -M_PI_4 / 3
        rotationAnimation.toValue = M_PI_4 / 3
        rotationAnimation.duration = 0.1
        rotationAnimation.repeatCount = 3
        
        self.circleLayer.addAnimation(rotationAnimation, forKey: "animation_rotation_fail")
    }
    
    func startTitleTransition(title: String) {
        let transition: CATransition = CATransition()
        self.titleLayer.actions = ["string": transition]
        CATransaction.setAnimationDuration(0.4)
        self.titleLayer.string = title
    }
    
    func updateTitlePosition() {
        switch self.currentStatus {
            case .Ready:
                self.titleLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
            default:
                self.titleLayer.position = CGPointMake(kCircleFrameWidthRatio * CGRectGetWidth(self.bounds) + CGRectGetMidX(self.titleLayer.bounds), CGRectGetMidY(self.bounds))
        }
    }
    
    func updateTitleFrame() {
        let titleRect: CGRect = (readyTitle as NSString).boundingRectWithSize(self.bounds.size, options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: ffjTitleFont], context: nil)
        titleLayer.frame = CGRectMake(0, 0, CGRectGetWidth(titleRect) + 20, CGRectGetHeight(titleRect))
    }
    
    override public func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if anim.valueForKey(kAnimationLoadFailKey) as! String == kAnimationLoadFailValue {
            self.exclamationMarkShakeAnimation()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
}
