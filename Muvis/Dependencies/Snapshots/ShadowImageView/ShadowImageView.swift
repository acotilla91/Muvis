//
//  ShadowImageView.swift
//  ShadowImageView
//
//  Created by olddonkey on 2017/4/29.
//  Copyright © 2017年 olddonkey. All rights reserved.
//
// Source: https://github.com/olddonkey/ShadowImageView

import UIKit
import CoreGraphics
import Nuke

@objc protocol ShadowImageViewDelegate: class {
    @objc optional func shadowImageViewDidUpdateImageFrame(_ shadowImageView: ShadowImageView)
    @objc optional func shadowImageViewDidUpdateBlurFrame(_ shadowImageView: ShadowImageView)    
}

@IBDesignable
public class ShadowImageView: ImageDisplayingView {
    
    private(set) var imageView = UIImageView()
    private(set) var blurredImageView = UIImageView()
    
    weak var delegate: ShadowImageViewDelegate?

    /// Gaussian Blur radius, larger will make the back ground shadow lighter (warning: do not set it too large, 2 or 3 for most cases)
    @IBInspectable
    public var blurRadius: CGFloat = 3 {
        didSet {
            layoutShadow()
        }
    }

    /// The image view contains target image
    @IBInspectable
    public var image: UIImage? {
        set {
            DispatchQueue.main.async {
                self.imageView.image = newValue
                self.layoutShadow()
            }
        }
        get {
            return self.imageView.image
        }
    }

    /// Image's corner radius
    @IBInspectable
    public var imageCornerRaidus: CGFloat = 0 {
        didSet {
            imageView.layer.cornerRadius = imageCornerRaidus
            imageView.layer.masksToBounds = true
        }
    }

    /// shadow radius offset in percentage, if you want shadow radius larger, set a postive number for this, if you want it be smaller, then set a negative number
    @IBInspectable
    public var shadowRadiusOffSetPercentage: CGFloat = 0 {
        didSet {
            layoutShadow()
        }
    }

    /// Shadow offset value on x axis, postive -> right, negative -> left
    @IBInspectable
    public var shadowOffSetByX: CGFloat = 0 {
        didSet {
            layoutShadow()
        }
    }


    /// Shadow offset value on y axis, postive -> right, negative -> left
    @IBInspectable
    public var shadowOffSetByY: CGFloat = 0 {
        didSet {
            layoutShadow()
        }
    }
    
    
    /// Shadow alpha value
    @IBInspectable
    public var shadowAlpha: CGFloat = 1 {
        didSet {
            blurredImageView.alpha = shadowAlpha
        }
    }
    
    override public var contentMode: UIView.ContentMode {
        didSet{
            layoutShadow()
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        layoutShadow()
    }

    /// Generate the background color and set it to a image view.
    private func generateBlurBackground() {
        guard let image = image else{
            return
        }
        let realImageSize = getRealImageSize(image)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let weakself = self else {
                return
            }
            // Create a containerView to hold the image should apply gaussian blur.
            let containerLayer = CALayer()
            containerLayer.frame = CGRect(origin: .zero, size: realImageSize.scaled(by: 1.4))
            containerLayer.backgroundColor = UIColor.clear.cgColor
            let blurImageLayer = CALayer()
            blurImageLayer.frame = CGRect(origin: CGPoint.init(x: realImageSize.width*0.2, y: realImageSize.height*0.2), size: realImageSize)
            blurImageLayer.contents = image.cgImage
            blurImageLayer.cornerRadius = weakself.imageCornerRaidus
            blurImageLayer.masksToBounds = true
            containerLayer.addSublayer(blurImageLayer)
            
            var containerImage = UIImage()
            // Get the UIImage from a UIView.
            if containerLayer.frame.size != CGSize.zero {
                containerImage = UIImage(layer: containerLayer)
            }else {
                containerImage = UIImage()
            }

            guard let resizedContainerImage = containerImage.resized(withPercentage: 0.2),
                let ciimage = CIImage(image: resizedContainerImage),
                let blurredImage = weakself.applyBlur(ciimage: ciimage) else {
                    return
            }

            DispatchQueue.main.async {
                self?.blurredImageView.image = blurredImage
            }
        }
    }

    /// Apply Gaussian Blur to a ciimage, and return a UIImage
    ///
    /// - Parameter ciimage: the imput CIImage
    /// - Returns: output UIImage
    private func applyBlur(ciimage: CIImage) -> UIImage? {

        if let filter = CIFilter(name: "CIGaussianBlur") {
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            filter.setValue(blurRadius, forKeyPath: kCIInputRadiusKey)
            
            let context = CIContext(options: nil)
            if let output = filter.outputImage, let cgimage = context.createCGImage(output, from: ciimage.extent) {
                return UIImage(cgImage: cgimage, scale: UIScreen.main.scale, orientation: .up)
            }
        }
        return nil
    }

    /// Due to scaleAspectFit, need to calculate the real size of the image and set the corner radius
    ///
    /// - Parameter from: input image
    /// - Returns: the real size of the image
    func getRealImageSize(_ image: UIImage) -> CGSize {
        if contentMode == .scaleAspectFit {
            let scale = min(bounds.size.width / image.size.width, bounds.size.height / image.size.height)
            return image.size.scaled(by: scale)
        }
        else if contentMode == .scaleAspectFill {
            let scale = max(bounds.size.width / image.size.width, bounds.size.height / image.size.height)
            return image.size.scaled(by: scale)
        }
        else {
            return image.size
        }
    }

    override public func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        backgroundColor = .clear
        if newSuperview != nil {
            layoutImageView()
        }
    }

    private func layoutShadow() {
        
        DispatchQueue.main.async {
            self.generateBlurBackground()
            guard let image = self.image else {
                return
            }
            
            let realImageSize = self.getRealImageSize(image)
            
            self.imageView.frame = CGRect(origin: .zero, size: realImageSize)
            self.imageView.center = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)

            self.delegate?.shadowImageViewDidUpdateImageFrame?(self)
            
            let newSize = realImageSize.scaled(by: 1.4 * (1 + self.shadowRadiusOffSetPercentage/100))
            
            self.blurredImageView.frame = CGRect(origin: .zero, size: newSize)
            self.blurredImageView.center = CGPoint(x: self.bounds.width/2 + self.shadowOffSetByX, y: self.bounds.height/2 + self.shadowOffSetByY)
            self.blurredImageView.contentMode = self.contentMode
            self.blurredImageView.alpha = self.shadowAlpha
            
            self.delegate?.shadowImageViewDidUpdateBlurFrame?(self)
        }
    }

    private func layoutImageView() {
        imageView.image = image
        imageView.frame = bounds
        
        imageView.layer.cornerRadius = imageCornerRaidus
        imageView.layer.masksToBounds = true
        imageView.contentMode = contentMode
        addSubview(imageView)
        addSubview(blurredImageView)
        sendSubviewToBack(blurredImageView)
    }
    
    // Conform ImageDisplaying protocol from Nuke
    public func nuke_display(image: PlatformImage?) {
        self.image = image
    }
}
