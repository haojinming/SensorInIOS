//
//  MediaRecorder.swift
//  SeamlessDemo
//
//  Created by utrc on 22/01/2018.
//  Copyright © 2018 utrc. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage
import ImageIO

class MediaRecorder: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVAudioRecorderDelegate{
    
    static let shared = MediaRecorder.init()
    
    private let session = AVCaptureSession.init()
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder : AVAudioRecorder!
    
    public var ambientLight : Double = 0.0
    public var audioURL : URL!
    
    override init() {
    }
    
    //get ambient light brightbess value from camera
    public func updateAmbientLight(){
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
            if granted && AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == AVAuthorizationStatus.authorized{
                //input of camera
                if let cameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back){
                    do{
                        let deviceInput = try AVCaptureDeviceInput.init(device: cameraDevice)
                        if self.session.canAddInput(deviceInput){
                            self.session.addInput(deviceInput)
                        }
                    }catch{
                        let infoStr = "Error occurs when record video."
                        print(infoStr)
                    }
                }
                
                //ouput of camera
                let deviceOutput = AVCaptureVideoDataOutput.init()
                deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
                if self.session.canAddOutput(deviceOutput){
                    self.session.addOutput(deviceOutput)
                }else{
                    let infoStr = "Cannot add ouput of camera."
                    print(infoStr)
                }
                self.session.startRunning()
            }
            else{
                let infoStr = "Camera is not available."
                print(infoStr)
            }
        }
    }
    public func stopCaptureSession(){
        session.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let metaDataDict = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let metaData = NSMutableDictionary.init(dictionary: metaDataDict!)
        let exifMetaData = metaData.object(forKey: kCGImagePropertyExifDictionary) as! NSDictionary
        let brightness = exifMetaData.object(forKey: kCGImagePropertyExifBrightnessValue) as! Double
        self.ambientLight = brightness
    }
    
    public func startRecordAudio(){
        let audioSetting = [AVSampleRateKey : Float(8000.0),
                            AVFormatIDKey : Int32(kAudioFormatMPEG4AAC),
                            AVNumberOfChannelsKey : 1,
                            AVEncoderAudioQualityKey : Int32(AVAudioQuality.medium.rawValue)] as [String : Any]
        self.audioSession.requestRecordPermission { (granted) in
            if granted{
                //not store audio file
                let recordURL = URL.init(fileURLWithPath: "/dev/null")
                /*
                 //store audio file
                 var recordURL = self.createAudioURL()
                 if recordURL == nil{
                 recordURL = self.getTempAudioFile()
                 if recordURL == nil{
                 recordURL = URL.init(fileURLWithPath: "/dev/null")
                 }
                 }*/
                do{
                    try self.audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
                    try self.audioRecorder = AVAudioRecorder(url: recordURL, settings: audioSetting)
                    self.audioRecorder.delegate = self
                    self.audioRecorder.isMeteringEnabled = true
                    self.audioRecorder.prepareToRecord()
                }catch{
                    let infoStr = "Audio recorder fails to record audio."
                    print(infoStr)
                    return
                }
                if !self.audioRecorder.isRecording{
                    do{
                        try self.audioSession.setActive(true)
                        self.audioRecorder.record()
                        self.audioURL = recordURL
                        
                        let infoStr = "Start to record audio."
                    }catch{
                        let errorInfo = String(describing: error)
                        let infoStr = "Cann't active audio record session." + errorInfo
                        print(infoStr)
                    }
                }else{
                    let infoStr = "Cannot start record audio because it has beed started."
                    print(infoStr)
                }
            }
            else{
                let infoStr = "Audio recorder does not get user' permission."
                print(infoStr)
            }
        }
    }
    
    public func stopRecordAudio(){
        if audioRecorder != nil && audioRecorder.isRecording{
            audioRecorder.stop()
            do{
                try self.audioSession.setActive(false)
            }catch{
                let infoStr = "Cannot disable audio session."
                print(infoStr)
            }
        }
    }
    
    public func getAudiodecibel() -> Double{
        var result = 0.0
        if self.audioRecorder != nil && self.audioRecorder.isRecording{
            self.audioRecorder.updateMeters()
            result = Double(self.audioRecorder.averagePower(forChannel: 0))
        }
        return result
    }
    
    private func createAudioURL() -> URL?{
        var result : URL?
        /*
        if let currentFolder = currentExpFolder{
            let audioName = Utils.getAudioFileName()
            result = currentFolder.appendingPathComponent(audioName)
        }else{
            result = nil
        }*/
        
        return result
    }
}
