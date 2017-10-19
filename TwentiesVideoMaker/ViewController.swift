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
import SwiftyJSON
import SwiftScanner
import RecordButton
import SwiftyTimer
import FCAlertView

class ViewController: SwiftyCamViewController {
    
    var outputURLs:[URL] = []
    
    lazy var recordButton : RecordButton = {
        let recordButton:RecordButton = RecordButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        recordButton.addTarget(self, action: #selector(self.record), for: .touchDown)
        recordButton.addTarget(self, action: #selector(self.stop), for: .touchUpInside)
        
        return recordButton
    }()
    
    var progressTimer : Timer!
    var progress : CGFloat! = 0
    
    var overallProgress: Double = 0 {
        didSet {
            print(overallProgress)
        }
    }
    
    var waveExportProgress: Double = 0.0
    var processAudioProgress: Double = 0.0
    var slidesProgress: Double = 0.0
    var reconstructionProgress: Double = 0.0
    
    var asset:AVAsset!
    
    var exportTimer:Timer!
    
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

        cameraDelegate = self
        flashEnabled = false
        defaultCamera = .front
        videoQuality = .resolution1280x720

        self.view.addSubview(self.recordButton)
        self.view.addSubview(self.progressView)
        
        constrain(self.recordButton) { (view) in
            view.bottom == view.superview!.bottom - 40
            view.height == 100
            view.width == 100
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
    
    @objc func record() {
        self.progressTimer = Timer.every(0.05.seconds) {
            self.updateProgress()
        }
        
        self.startVideoRecording()
    }
    
    func updateProgress() {
        
        let maxDuration = CGFloat(5) // max duration of the recordButton
        
        progress = progress + (CGFloat(0.05) / maxDuration)
        recordButton.setProgress(progress)
        
        if progress >= 1 {
            progressTimer.invalidate()
        }
        
    }
    
    @objc func stop() {
        self.progressView.isHidden = false
        
        self.progressTimer.invalidate()
        self.stopVideoRecording()
        self.progress = 0.0
    }
    
    func editVideo(url1:URL, url2:URL) {
//        let videoEditor:LLVideoEditor = LLVideoEditor(videoURL: url1)
        
        let manager:URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let outputURL:URL = manager.appendingPathComponent("TwentiesVideo").appendingPathExtension("mov")
        
        ExporterController.export(outputURL, fromOutput: [url2], handler: { (url) in
            print("handled")
        })
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
    
    func applyOverlay(filename: String) {
//        init_filters("UnsafePointer<Int8>!")
//        apply_filters(filename)
    }
    
    func progressHandler(time: CMTime) {
        self.waveExportProgress = Double(100 * (CMTimeGetSeconds(time) / CMTimeGetSeconds(self.asset.duration)))
        self.overallProgress += self.waveExportProgress
    }
    
    func resetProgress() {
        self.progressView.isHidden = true
        self.overallProgress = 0.0
        self.waveExportProgress = 0.0
        self.processAudioProgress = 0.0
        self.slidesProgress = 0.0
        self.reconstructionProgress = 0.0
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
    
    func cluster() {
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        // Called when stopVideoRecording() is called and the video is finished processing
        // Returns a URL in the temporary directory where video is stored
        
        outputURLs.append(url)
        
        let recorderViewController:RecorderViewController = RecorderViewController()
        
        self.asset = AVURLAsset(url: url)
        
        let alphaViewController:AlphaViewController = AlphaViewController()
        alphaViewController.loadVideoContent(url.path, handler: { (aString) in
            print("created")
            
            var renderSettings:RenderSettings = RenderSettings()
            renderSettings.size = CGSize(width: 720, height: 1280)
            
            let imageAnimator:ImageAnimator = ImageAnimator(renderSettings: renderSettings)
            
            var i = 0
            var path:String = NSTemporaryDirectory().appending("Poster\(i)@2x.png")
            while FileManager().fileExists(atPath: path) {
                imageAnimator.images.append(UIImage(contentsOfFile: path)!)
                i += 1
                path = NSTemporaryDirectory().appending("Poster\(i)@2x.png")
            }
            
            imageAnimator.render(completion: {
                print("finally finished")
                
                // remove everything
                var i = 0
                var path:String = NSTemporaryDirectory().appending("Poster\(i)@2x.png")
                while FileManager().fileExists(atPath: path) {
                    try! FileManager().removeItem(at: URL(fileURLWithPath: path))
                    i += 1
                    path = NSTemporaryDirectory().appending("Poster\(i)@2x.png")
                }
                
                try! FileManager().removeItem(at: url)
            }, progressHandler: { (time) in
                self.reconstructionProgress = Double(100 * (CMTimeGetSeconds(time) / CMTimeGetSeconds(self.asset.duration)))
                self.overallProgress += self.reconstructionProgress
            })
        })
        
        return
        
        // 1. Get audio from recorded video
        let exportSession:AVAssetExportSession = AudioExporter.getAudioFromVideo(asset) { (exportSession) in
            
            // 2. Convert audio to text
            AudioExporter.exportAsset(asWaveFormat: exportSession?.outputURL!.path, progressHandler: self.progressHandler, handler: { (newAudioPath) in
                
                
                self.processAudioProgress += 50.0
                self.overallProgress += self.processAudioProgress
                
                recorderViewController.processAudio(newAudioPath, handler: { (data) in
                    self.processAudioProgress += 50.0
                    self.overallProgress += self.processAudioProgress
                    
                    let json = JSON(data: data!)
                    
                    var phrases:[String] = []

                    if let words = json["results"][0]["alternatives"][0].dictionary {
                        //Now you got your value
                        
                        if let wordArray = words["words"]?.array {
                            var previousStartTime:Float = 0.0
                            var phrase:[String] = []
                            
                            for (i, word) in wordArray.enumerated() {
                                
                                
                                let scanner = StringScanner(word["startTime"].string!)
                                let startTime = try! scanner.scanFloat()

                                let endTime = try! StringScanner(word["endTime"].string!).scanFloat()

                                if previousStartTime != 0.0 && previousStartTime < startTime - 5 {
                                    phrases.append(phrase.joined(separator: " "))
                                    phrase = [word["word"].string!]
                                } else {
                                    phrase.append(word["word"].string!)
                                }

                                if (i == wordArray.count-1 && phrases.count == 0) {
                                    phrases.append(phrase.joined(separator: " "))
                                }

                                previousStartTime = endTime
                            }
                        }
                    } else {
                        print("nope")
                        let alert:FCAlertView = FCAlertView()
                        alert.makeAlertTypeWarning()
                        alert.showAlert(inView: self,
                                        withTitle: "Error!",
                                        withSubtitle: "There was an error creating your video",
                                        withCustomImage: nil,
                                        withDoneButtonTitle: "Okay",
                                        andButtons: nil)

                        alert.colorScheme = UIColor(hex: "#8C9AFF")
                        
                        self.resetProgress()
                    }
                    
                    for phrase in phrases {
                        // 3. Convert text to images for display as the speech card
                        let image:UIImage = self.imageFromText(text: phrase as NSString, font: UIFont.systemFont(ofSize: 20), maxWidth: 720, color: .orange)
                        
                        var renderSettings:RenderSettings = RenderSettings()
                        renderSettings.size = CGSize(width: 720, height: 1280)
                        
                        let imageAnimator:ImageAnimator = ImageAnimator(renderSettings: renderSettings)
                        for i in 0...30 {
                            imageAnimator.images.append(image)
                        }
                        
                        // 4. Render out the text speech files as video files
                        let queue = DispatchQueue(label: "com.paubins.renderQueue")
                        
                        imageAnimator.render(completion: {
                            print("completed")
                            self.outputURLs.append(imageAnimator.settings.outputURL)
                            
                            if self.outputURLs.count == phrases.count + 1 {
                                let outputFileName = UUID().uuidString
                                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                                
                                ExporterController.export(URL(fileURLWithPath: outputFilePath), fromOutput: self.outputURLs, handler: { (url) in
                                    
                                    let alphaViewController:AlphaViewController = AlphaViewController()
                                    alphaViewController.loadVideoContent(url?.path, handler: { (aString) in
                                        print("created")
                                        
                                        var renderSettings:RenderSettings = RenderSettings()
                                        renderSettings.size = CGSize(width: 720, height: 1280)
                                        
                                        let imageAnimator:ImageAnimator = ImageAnimator(renderSettings: renderSettings)
                                        
                                        for i in 0...21 {
                                            imageAnimator.images.append(UIImage(contentsOfFile: "Poster\(i)@2x")!)
                                        }
                                        
                                        imageAnimator.render(completion: {
                                            print("finally finished")
                                        }, progressHandler: { (time) in
                                            self.reconstructionProgress = Double(100 * (CMTimeGetSeconds(time) / CMTimeGetSeconds(self.asset.duration)))
                                            self.overallProgress += self.reconstructionProgress
                                        })
                                    })
                                })
                                self.outputURLs = []
                            }
                        }, progressHandler: { (time) in
                            self.slidesProgress = Double(100 * (CMTimeGetSeconds(time) / CMTimeGetSeconds(self.asset.duration)))
                            self.overallProgress += self.slidesProgress
                        })
                    }
                })
            })
        }
        
        self.exportTimer = Timer.every(0.2.second) {
            if (self.progressView.progress == 1) {
                self.exportTimer.invalidate()
                return
            }
            
            // check progress of initial export of audio
            if (exportSession.progress < 1 || self.overallProgress == 0.0) {
                 self.overallProgress = Double(Double(exportSession.progress) * 100)
            }
            
//            self.progressView.progress = self.overallProgress/800
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
