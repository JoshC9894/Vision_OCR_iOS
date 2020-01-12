//
//  CaptureVC.swift
//  Spaff
//
//  Created by Joshua Colley on 23/05/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//

import UIKit
import AVKit
import Vision

class CaptureVC: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    
    var videoInput: AVCaptureDeviceInput!
    var videoOutput: AVCaptureVideoDataOutput!
    
    var cameraOutput = AVCapturePhotoOutput()
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    
    var cvBuffer: CVPixelBuffer?
    var cmSampleBuffer: CMSampleBuffer?
    var rectFrame: CGRect?
    var rect: VNRectangleObservation?
    
    // MARK: - View Life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        captureButton.layer.cornerRadius = captureButton.frame.height / 2
        startLiveVideo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.session.startRunning()
        detectRect()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.session.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        videoView.layer.sublayers?[0].frame = videoView.bounds
    }
    
    
    // MARK: - Actions
    @IBAction func captureButtonAction(_ sender: Any) {
        performSegue(withIdentifier: "captureToRead", sender: self)
    }
}


// MARK: - Video Layer
extension CaptureVC {
    fileprivate func startLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.high
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        // Input
        if self.videoInput == nil {
            self.videoInput = try? AVCaptureDeviceInput(device: device)
            self.session.addInput(self.videoInput)
        }
        
        // Output
        if self.videoOutput == nil {
            self.videoOutput = AVCaptureVideoDataOutput()
            let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
            
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            self.videoOutput.setSampleBufferDelegate(self, queue: queue)
            
            self.session.addOutput(self.videoOutput)
        }
        
        // Start Capture Session
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.videoGravity = .resizeAspectFill
        videoView.layer.addSublayer(layer)
    }
}


// MARK: - Video Output Delegate
extension CaptureVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let cvBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        self.cmSampleBuffer = sampleBuffer
        self.cvBuffer = cvBuffer
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: cvBuffer,
                                                        orientation: .right,
                                                        options: requestOptions)
        try? imageRequestHandler.perform(self.requests)
    }
}


// MARK: - Prepare for Segue
extension CaptureVC {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ReadVC {
            destination.buffer = self.cvBuffer
        }
    }
}


// MARK: - Rectangle Detection
extension CaptureVC {
    fileprivate func detectRect() {
        let rectRequests = VNDetectRectanglesRequest { (request, error) in
            if error == nil {
                self.rectRequestHandler(request: request)
            }
        }
        self.requests = [rectRequests]
    }
    
    fileprivate func rectRequestHandler(request: VNRequest) {
        guard let observations = request.results else { return }
        let result = observations.map({ $0 as? VNRectangleObservation })
        
        DispatchQueue.main.async {
            self.videoView.layer.sublayers?.removeSubrange(1...)
            result.forEach({ (rect) in
                if let rect = rect {
                    let frame = FrameHelper.getFrame(rect: rect,
                                                     frame: self.videoView.frame)
                    self.rectFrame = frame
                    self.rect = rect
                    let layer = CALayer()
                    layer.borderColor = UIColor.yellow.cgColor
                    layer.borderWidth = 4.0
                    layer.frame = frame
                    self.videoView.layer.addSublayer(layer)
                }
            })
        }
    }
}

