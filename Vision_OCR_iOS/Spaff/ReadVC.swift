//
//  ReadVC.swift
//  Spaff
//
//  Created by Joshua Colley on 23/05/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//

import UIKit
import Vision
import TesseractOCR

class ReadVC: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    var buffer: CVPixelBuffer?
    var image: UIImage?
    
    // MARK: - View Life-Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if let buffer = self.buffer {
            self.image = UIImage(ciImage: CIImage(cvImageBuffer: buffer), scale: 1.0, orientation: .right)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        detectRect()
    }
    
    // MARK: - Rectangle Detection
    fileprivate func detectRect() {
        let rectRequests = VNDetectRectanglesRequest { (request, error) in
            if error == nil {
                self.rectRequestHandler(request: request)
            }
        }
        if let buffer = self.buffer {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer,
                                                            orientation: .right,
                                                            options: [:])
            try? imageRequestHandler.perform([rectRequests])
        }
    }
    
    fileprivate func rectRequestHandler(request: VNRequest) {
        guard let observations = request.results else { return }
        let result = observations.map({ $0 as? VNRectangleObservation })
        
        DispatchQueue.main.async {
            result.forEach({ (rect) in
                if let rect = rect {
                    if let image = self.image {
                        let croppedImage = FrameHelper.cropImage(image: image, observation: rect)
                        self.imageView.image = croppedImage
                        self.ocr()
                    }
                }
            })
        }
    }
    
    // MARK: - OCR
    fileprivate func ocr() {
        if let tesseract = G8Tesseract.init(language: "eng") {
            tesseract.engineMode = .tesseractCubeCombined
            tesseract.pageSegmentationMode = .auto
            tesseract.image = self.imageView.image?.g8_blackAndWhite()
            tesseract.recognize()
            
            DispatchQueue.main.async {
                self.textView.text = tesseract.recognizedText
            }
        }
    }
    
    
    // MARK: - Actions
    @IBAction func dismissAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
