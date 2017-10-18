//
//  ViewController.swift
//  TwentiesVideoMaker
//
//  Created by Patrick Aubin on 10/17/17.
//  Copyright © 2017 Patrick Aubin. All rights reserved.
//

import UIKit
import SwiftyCam
import Cartography
import KDCircularProgress
import LLVideoEditor

class ViewController: SwiftyCamViewController {
    
    lazy var recordButton:UIButton = {
        let button:UIButton = UIButton(frame: .zero)
        button.setTitle("Record", for: .normal)
        button.addTarget(self, action: #selector(self.record), for: .touchUpInside)
        return button
    }()
    
    lazy var progressView:KDCircularProgress = {
        let progress:KDCircularProgress = KDCircularProgress(frame: .zero)
        progress.startAngle = -90
        progress.progressThickness = 0.2
        progress.trackThickness = 0.6
        progress.clockwise = true
        progress.gradientRotateSpeed = 2
        progress.roundedCorners = false
        progress.glowMode = .forward
        progress.glowAmount = 0.9
        progress.set(colors: UIColor.cyan ,UIColor.white, UIColor.magenta, UIColor.white, UIColor.orange)
        progress.center = CGPoint(x: view.center.x, y: view.center.y + 25)
        progress.isHidden = true
        
        return progress
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        cameraDelegate = self
        
        self.view.addSubview(self.recordButton)
        self.view.addSubview(self.progressView)
        
        constrain(self.recordButton) { (view) in
            view.bottom == view.superview!.bottom
            view.height == 50
            view.centerX == view.superview!.centerX
        }
        
        constrain(self.progressView) { (view) in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY
            view.width == 150
            view.height == 150
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func record(sender: UIButton) {
        if (self.isVideoRecording) {
            self.stopVideoRecording()
        } else {
            self.startVideoRecording()
        }
    }
    
    func editVideo(url1:URL, url2:URL) {
//        let videoEditor:LLVideoEditor = LLVideoEditor(videoURL: url1)
        
        let manager:URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let outputURL:URL = manager.appendingPathComponent("TwentiesVideo").appendingPathExtension("mov")
        
//        videoEditor.export(to: outputURL, completionBlock: { [weak self] (exportSession) in
//            if let strongSelf = self {
//                DispatchQueue.main.async(execute: {
//                    if exportSession?.status == AVAssetExportSessionStatus.completed {
////                        UISaveVideoAtPathToSavedPhotosAlbum((outputURL.path), self, nil, nil)
//                        let shareViewController:ViewShareVideoViewController = ViewShareVideoViewController()
//                        shareViewController.player.url = outputURL
//                        
//                        strongSelf.present(shareViewController, animated: true)
//                    }
//                    else {
//                        print(exportSession?.error?.localizedDescription ?? "error")
//                        print(exportSession?.error.debugDescription)
//                    }
//                })
//            }
//            
//        })
        
        ExporterController.export(outputURL, fromOutput: [url2])
    }
    
    func sizeOfAttributeString(str: NSAttributedString, maxWidth: CGFloat) -> CGSize {
        let size = str.boundingRect(with: CGSize(width: maxWidth, height: 1000), options:(NSStringDrawingOptions.usesLineFragmentOrigin), context:nil).size
        return size
    }
    
    func imageFromText(text:NSString, font:UIFont, maxWidth:CGFloat, color:UIColor) -> UIImage {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraph.alignment = .center
        
        let attributedString = NSAttributedString(string: text as String, attributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: color, NSAttributedStringKey.paragraphStyle:paragraph])
        
        let size = sizeOfAttributeString(str: attributedString, maxWidth: maxWidth)
        UIGraphicsBeginImageContextWithOptions(size, false , 0.0)
        attributedString.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension ViewController : SwiftyCamViewControllerDelegate {
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        // Called when takePhoto() is called or if a SwiftyCamButton initiates a tap gesture
        // Returns a UIImage captured from the current session
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        // Called when startVideoRecording() is called
        // Called if a SwiftyCamButton begins a long press gesture
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        // Called when stopVideoRecording() is called
        // Called if a SwiftyCamButton ends a long press gesture
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        // Called when stopVideoRecording() is called and the video is finished processing
        // Returns a URL in the temporary directory where video is stored
        
        let recorderViewController:RecorderViewController = RecorderViewController()
        
        let asset:AVAsset = AVURLAsset(url: url)
        
        // 1. Get audio from recorded video
        AudioExporter.getAudioFromVideo(asset) { (exportSession) in
            
            // 2. Convert audio to text
            recorderViewController.processAudio(exportSession?.outputURL!.path)
            
            // 3. Convert text to images for display as the speech card
            let image:UIImage = self.imageFromText(text: "Test", font: UIFont.systemFont(ofSize: 20), maxWidth: 720, color: .orange)
            
            var renderSettings:RenderSettings = RenderSettings()
            renderSettings.size = CGSize(width: 720, height: 1280)
            
            let imageAnimator:ImageAnimator = ImageAnimator(renderSettings: renderSettings)
            for i in 0...30 {
                imageAnimator.images.append(image)
            }
            
            // 4. Render out the text speech files as video files
            imageAnimator.render(completion: {
                print("completed")
                print("\(imageAnimator.settings.outputURL)")
                
                // 5. Combine speech video files with recorded video
                self.editVideo(url1: imageAnimator.settings.outputURL, url2: imageAnimator.settings.outputURL)
            })
            
        }
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        // Called when a user initiates a tap gesture on the preview layer
        // Will only be called if tapToFocus = true
        // Returns a CGPoint of the tap location on the preview layer
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        // Called when a user initiates a pinch gesture on the preview layer
        // Will only be called if pinchToZoomn = true
        // Returns a CGFloat of the current zoom level
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        // Called when user switches between cameras
        // Returns current camera selection
    }
}
