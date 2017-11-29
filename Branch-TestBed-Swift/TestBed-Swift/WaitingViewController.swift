//
//  WaitingViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 7/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import UIKit

class WaitingViewController: UIViewController {
    
    private static var globalWaitingViewController: WaitingViewController? = nil
    private static let waitingViewDefaultHangTime: TimeInterval = 2.3
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var label: UILabel!
    var maxLabelRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var backgroundView: UIView? = nil
    var parentView: UIView? = nil
    var parentTransform: CGAffineTransform = CGAffineTransform.identity
    
    class func instanceFromNib() -> WaitingViewController {
        return UINib(nibName: "WaitingViewController", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! WaitingViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.maxLabelRect = self.label.bounds
    }
    
    // MARK - View Lifecycle
    
    override func didReceiveMemoryWarning() {
        self.backgroundView?.removeFromSuperview()
        self.backgroundView = nil
        self.activityIndicator = nil
        self.label = nil
        super.didReceiveMemoryWarning()
    }

    static let kScale: CGFloat = 0.9950
    
    func showWithParent(parentView: UIView,
                        message: String,
                        activityIndicator showActivity: Bool,
                        disableTouches: Bool) {
        self.parentView?.transform = self.parentTransform
        self.parentView = parentView
        
        // Force the view to load
        let frame: CGRect = self.view.frame
        self.view.frame = frame
        
        var activityRect: CGRect = CGRect.zero
        var labelRect: CGRect = CGRect.zero
        
        if (showActivity) {
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            activityRect = self.activityIndicator.bounds
        } else {
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
        }
        
        let kIndent: CGFloat = 40.0
        
        if (message.count > 0) {
            self.label.text = message
            labelRect.size = self.label.sizeThatFits(self.maxLabelRect.size)
            labelRect.size.width += 2.0 * kIndent
        }
        
        labelRect = self.centerRectOverRect(rectToCenter: labelRect, overRect: activityRect)
        labelRect.origin.y = activityRect.origin.y + activityRect.size.height
        var viewRect: CGRect = activityRect.union(labelRect)
        viewRect = viewRect.insetBy(dx: -kIndent, dy: -kIndent)
        
        let screenRect: CGRect = UIScreen.main.bounds
        self.view.frame = centerRectOverRect(rectToCenter: viewRect, overRect: screenRect)
        self.view.layer.cornerRadius = 5.0
        self.view.layer.borderWidth = 0.5
        self.view.layer.borderColor = UIColor.gray.cgColor
        self.view.alpha = 1.0
        
        self.activityIndicator.frame = activityRect.offsetBy(dx: -viewRect.origin.x, dy: -viewRect.origin.y)
        self.label.frame = labelRect.offsetBy(dx: -viewRect.origin.x, dy: -viewRect.origin.y)
        
        self.backgroundView?.removeFromSuperview()
        self.backgroundView = nil
        
        if (disableTouches) {
            self.backgroundView = UIView.init(frame: parentView.bounds)
            self.backgroundView?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            self.backgroundView?.addSubview(self.view)
            parentView.addSubview(self.backgroundView!)
        } else {
            //      ZDebugAssertWithMessage(NO, @"Not implemented.")
            self.view.frame = centerRectOverRect(rectToCenter: viewRect, overRect: screenRect)
            parentView.addSubview(self.view)
            //      [self.view addGestureRecognizer:
            //          [[ZWildCardGestureRecognizer alloc]
            //              initWithTarget:self
            //              action:@selector(tapGoAway:)]]
        }
        
        // self.label.font = [APStyle currentStyle].applicationFont
        
        UIView.setAnimationsEnabled(false)
        self.backgroundView?.alpha = 0.0
        UIView.setAnimationsEnabled(true)
        
        self.view.setNeedsLayout()
        self.view.setNeedsDisplay()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.parentTransform = (self.parentView?.transform)!
        self.view.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
        
        UIView.animate(withDuration: 0.4, delay: 0.01, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            self.parentView?.transform = (self.parentView?.transform.scaledBy(x: WaitingViewController.kScale, y: WaitingViewController.kScale))!
            self.view.transform = CGAffineTransform(scaleX: 1.0 / WaitingViewController.kScale, y: 1.0 / WaitingViewController.kScale)
            self.backgroundView?.alpha = 1.0
        }, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.parentView?.transform = self.parentTransform
        self.view.transform = CGAffineTransform.identity
        super.viewDidDisappear(animated)
    }
    
    func tapGoAway(gesture: UIGestureRecognizer) {
        hide()
    }
    
    static func showWithMessage(message: String,
                         activityIndicator showActivity: Bool,
                         disableTouches disable: Bool) {
        
        if (WaitingViewController.globalWaitingViewController == nil) {
            WaitingViewController.globalWaitingViewController = WaitingViewController()
        }
        
        let appWindow: UIWindow = UIApplication.shared.keyWindow!
        
        globalWaitingViewController?.showWithParent(
            parentView:appWindow,
            message:message,
            activityIndicator:showActivity,
            disableTouches:disable)
    }
    
    func hide() {
        if (self.isViewLoaded) {
            self.view.removeFromSuperview()
            self.backgroundView?.removeFromSuperview()
            UIView.animate(withDuration: 0.6, delay: 0.010, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                self.parentView?.transform = self.parentTransform
            }, completion: { (done) in
                self.parentView = nil
            })
        }
    }
    
    static func hide() {
        globalWaitingViewController?.hide()
        globalWaitingViewController = nil
    }
    
    static func show() {
        self.showWithMessage(message: "", activityIndicator: true, disableTouches: true)
    }
    
    static func hideWithMessage(message: String) {
        showWithMessage(message: message, activityIndicator:false, disableTouches:false)
    
        afterSecondsPerformBlock(seconds: waitingViewDefaultHangTime) {
            UIView.animate(withDuration: 1.0,
                           animations: { globalWaitingViewController?.view.alpha = 0.0 },
                           completion: { (finished) in WaitingViewController.hide() })
        }
    }
    
    static func showWithMessage(message: String,
                         forSeconds time: TimeInterval) {
        
        showWithMessage(message: message, activityIndicator:false, disableTouches:false)
        if (time <= 0.0) {
            afterSecondsPerformBlock(seconds: waitingViewDefaultHangTime) {
                UIView.animate(withDuration: 1.0,
                               animations: { globalWaitingViewController?.view.alpha = 0.0 },
                               completion: { (finished) in WaitingViewController.hide() })}
        }
    }

    func centerRectOverRect(rectToCenter: CGRect, overRect: CGRect) -> CGRect {
        return CGRect(x: overRect.origin.x + ((overRect.size.width - rectToCenter.size.width) / 2.0),
                          y: overRect.origin.y + ((overRect.size.height - rectToCenter.size.height) / 2.0),
                          width: rectToCenter.size.width,
                          height: rectToCenter.size.height)
    }
    
    typealias CompletionBlock = () -> Void
    
    static func afterSecondsPerformBlock(seconds: TimeInterval, completion: @escaping CompletionBlock) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }

}
