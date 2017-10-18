//
//  ShareViewController.swift
//  FakeFaceTime
//
//  Created by Patrick Aubin on 10/8/17.
//  Copyright © 2017 com.paubins.FakeFaceTime. All rights reserved.
//

import Foundation
import Player
import Cartography
import DynamicButton
import FCAlertView
import Hue

extension UIView {
    func makeCircular() {
        self.layer.cornerRadius = min(self.frame.size.height, self.frame.size.width) / 2.0
    }
}

protocol ViewShareVideoViewControllerDelegate {
    func deleteCurrentVideo()
}

class ViewShareVideoViewController : UIViewController {
    
    var isPlaying:Bool = false
    
    var delegate:ViewShareVideoViewControllerDelegate!
    
    lazy var player:Player! = {
        let player = Player()
        player.playbackDelegate = self
        player.playbackResumesWhenEnteringForeground = false
        return player
    }()
    
    lazy var playButton:DynamicButton = {
        let dynamicButton:DynamicButton = DynamicButton(style: .play)
        dynamicButton.bounceButtonOnTouch = true
        dynamicButton.lineWidth           = 6
        dynamicButton.strokeColor         = .white
        dynamicButton.highlightStokeColor = .white
        dynamicButton.addTarget(self, action: #selector(self.play), for: .touchUpInside)
        return dynamicButton
    }()
    
    lazy var shareButton:DynamicButton = {
        let dynamicButton:DynamicButton = DynamicButton(style: .horizontalMoreOptions)
        dynamicButton.bounceButtonOnTouch = true
        dynamicButton.lineWidth           = 6
        dynamicButton.strokeColor         = .white
        dynamicButton.highlightStokeColor = .white
        dynamicButton.addTarget(self, action: #selector(self.share), for: .touchUpInside)
        return dynamicButton
    }()
    
    lazy var closeButton:DynamicButton = {
        let dynamicButton:DynamicButton = DynamicButton(style: .arrowLeft)
        dynamicButton.bounceButtonOnTouch = true
        dynamicButton.lineWidth           = 6
        dynamicButton.strokeColor         = .white
        dynamicButton.highlightStokeColor = .white
        dynamicButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)
        return dynamicButton
    }()
    
    lazy var buttonContainerView:UIView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let view:UIView = UIView(frame: .zero)
//        view.addSubview(blurEffectView)

        view.addSubview(self.playButton)
        
//        constrain(blurEffectView) { (view) in
//            view.top == view.superview!.top
//            view.left == view.superview!.left
//            view.right == view.superview!.right
//            view.bottom == view.superview!.bottom
//        }
        
        constrain(self.playButton) { (view) in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY
            
            view.height == 50
            view.width == 50
        }
        
        return view
    }()
    
    lazy var activityController:UIActivityViewController = {
        let activityController:UIActivityViewController = UIActivityViewController(activityItems: [self.player.url], applicationActivities: nil)
        activityController.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            print("farts")
            if(completed) {
                let alert:FCAlertView = FCAlertView()
                alert.makeAlertTypeSuccess()
                alert.showAlert(inView: self,
                                withTitle: "Saved!",
                                withSubtitle: "Your video saved!",
                                withCustomImage: nil,
                                withDoneButtonTitle: "👌",
                                andButtons: nil)
//                alert.delegate = self

                //            Answers.logCustomEvent(withName: "Exported video", customAttributes: [:])

                alert.colorScheme = UIColor(hex: "#8C9AFF")
            }
        }
        
        return activityController
    }()
    
    lazy var gestureRecognizer:UITapGestureRecognizer = {
        let gestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapped))
        
        return gestureRecognizer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.player.view)
        self.view.addSubview(self.buttonContainerView)
        self.view.addSubview(self.shareButton)
        self.view.addSubview(self.closeButton)
        
        constrain(self.player.view) { (view) in
            view.top == view.superview!.top
            view.left == view.superview!.left
            view.right == view.superview!.right
            view.bottom == view.superview!.bottom
        }
        
        constrain(self.buttonContainerView) { (view) in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY
            
            view.height == 100
            view.width == 100
        }
        
        constrain(self.shareButton) { (view) in
            view.left == view.superview!.right - 60
            view.top == view.superview!.top + 20
            
            view.height == 40
            view.width == 40
        }
        
        constrain(self.closeButton) { (view) in
            view.left == view.superview!.left + 20
            view.top == view.superview!.top + 20
            
            view.height == 40
            view.width == 40
        }
        
        self.player.view.addGestureRecognizer(self.gestureRecognizer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.buttonContainerView.makeCircular()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.buttonContainerView.alpha = 1.0
            self.shareButton.alpha = 1.0
            self.closeButton.alpha = 1.0
        })
        
        self.playButton.setStyle(.play, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (self.isPlaying) {
            self.play(sender: self.playButton)
        }
    }
    
    @objc func play(sender: DynamicButton) {
        if (!self.isPlaying) {
            UIView.animate(withDuration: 0.3, animations: {
                self.buttonContainerView.alpha = 0.0
                self.shareButton.alpha = 0.0
                self.closeButton.alpha = 0.0
            })
            self.playButton.setStyle(.pause, animated: true)
            self.player.playFromCurrentTime()
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.buttonContainerView.alpha = 1.0
                self.shareButton.alpha = 1.0
                self.closeButton.alpha = 1.0
            })
            self.playButton.setStyle(.play, animated: true)
            self.player.pause()
        }
        
        self.isPlaying = !self.isPlaying
    }
    
    @objc func share(sender: DynamicButton) {
        self.present(self.activityController, animated: true) {
            print("presented share controller")
        }
    }
    
    @objc func close(sender:DynamicButton) {
        self.dismiss(animated: true) {
            print("dismissed")
            self.player.stop()
            self.player.url = nil
            self.isPlaying = false
        }
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        self.play(sender: self.playButton)
    }
}

extension ViewShareVideoViewController: PlayerPlaybackDelegate {
    
    public func playerPlaybackWillStartFromBeginning(_ player: Player) {
        
    }
    
    public func playerPlaybackDidEnd(_ player: Player) {
        self.play(sender: self.playButton)
    }
    
    public func playerCurrentTimeDidChange(_ player: Player) {

    }
    
    public func playerPlaybackWillLoop(_ player: Player) {

    }
    
}
