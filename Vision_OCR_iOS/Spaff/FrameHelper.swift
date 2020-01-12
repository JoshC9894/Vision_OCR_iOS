//
//  FrameHelper.swift
//  Spaff
//
//  Created by Joshua Colley on 23/05/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//

import Foundation
import UIKit
import Vision

class FrameHelper {
    static func getFrame(rect: VNRectangleObservation, frame: CGRect) -> CGRect {
        let transform = CGAffineTransform(scaleX: 1,
                                          y: -1).translatedBy(x: 0 - 40,
                                                              y: -frame.height)
        
        let translate = CGAffineTransform.identity.scaledBy(x: frame.width + 80,
                                                            y: frame.height)
        
        return rect.boundingBox.applying(translate).applying(transform)
    }
    
    static func cropTo(frame: CGRect, image: UIImage) -> UIImage? {
        let context = CIContext()
        if let ciImage = image.ciImage {
            let cgImage = context.createCGImage(ciImage.oriented(.right),
                                                from: CGRect(origin: CGPoint(x: 0, y: 0),
                                                             size: image.size))
            guard let croppedImage = cgImage?.cropping(to: frame) else { return nil }
            return UIImage(cgImage: croppedImage)
        }
        return nil
    }
    
    static func cropImage(image: UIImage, observation: VNRectangleObservation?) -> UIImage? {
        
        let maxX: CGFloat = (observation?.boundingBox.maxX)!
        let minX: CGFloat = (observation?.boundingBox.minX)!
        let maxY: CGFloat = (observation?.boundingBox.maxY)!
        let minY: CGFloat = (observation?.boundingBox.minY)!
        
        let xCord = maxX * image.size.width
        let yCord = (1 - minY) * image.size.height
        let width = (minX - maxX) * image.size.width
        let height = (minY - maxY) * image.size.height
        
        let frame = CGRect(x: xCord,
                           y: yCord,
                           width: width,
                           height: height)
        
        let context = CIContext()
        if let ciImage = image.ciImage {
            let cgImage = context.createCGImage(ciImage.oriented(.right), from: CGRect(origin: CGPoint(x: 0, y: 0),
                                                                                       size: image.size))
            guard let croppedImage = cgImage?.cropping(to: frame) else { return nil }
            return UIImage(cgImage: croppedImage)
        }
        return nil
    }
}
