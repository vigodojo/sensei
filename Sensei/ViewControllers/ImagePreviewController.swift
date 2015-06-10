//
//  ImagePreviewController.swift
//  Sensei
//
//  Created by Sauron Black on 6/8/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class ImagePreviewController: UIViewController {
    
    private struct Constants {
        static let StoryboardName = "Main"
        static let StoryboardId = "ImagePreviewController"
    }

    @IBOutlet weak var scrollView: UIScrollView!
    
//    weak var imageView: UIImageView!
//    weak var imageView: TextImageView!
    weak var imageView: VisualizationView!
    
    var image: UIImage?
    var attributedText: NSAttributedString?
    
    // MARK: - Lifecycle
    
    class func imagePreviewControllerWithImage(image: UIImage) -> ImagePreviewController {
        let storyboard = UIStoryboard(name: Constants.StoryboardName, bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier(Constants.StoryboardId) as! ImagePreviewController
        viewController.image = image
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createImageView()
        imageView.image = image
        imageView.attributedText = attributedText
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let image = image {
            updateFrameAndContentSizeForImage(image)
        }
    }
    
    // MARK: - Private
    
    private func createImageView() {
        let imageView = VisualizationView(frame: CGRectZero)
        scrollView.addSubview(imageView)
        self.imageView = imageView
    }
    
    private func updateFrameAndContentSizeForImage(image: UIImage) {
        imageView.frame = CGRect(origin: CGPointZero, size: image.size)
        scrollView.contentSize = image.size
        scrollView.minimumZoomScale = minimumScaleForImageSize(image.size)
        scrollView.maximumZoomScale = 1.0
        scrollView.zoomScale = scrollView.minimumZoomScale
        centerScrollViewContent()
    }
    
    private func minimumScaleForImageSize(size: CGSize) -> CGFloat {
        let scaleWidth = CGRectGetWidth(view.frame) / size.width
        let scaleHeight = CGRectGetHeight(view.frame) / size.height
        return min(scaleWidth, scaleHeight, CGFloat(1.0))
    }
    
    private func centerScrollViewContent() {
        let boundsSize = view.frame.size
        var contentFrame = imageView.frame
        
        if CGRectGetWidth(contentFrame) < boundsSize.width {
            contentFrame.origin.x = (boundsSize.width - CGRectGetWidth(contentFrame)) / 2.0;
        } else {
            contentFrame.origin.x  = 0
        }
        
        if CGRectGetHeight(contentFrame) < boundsSize.height {
            contentFrame.origin.y = (boundsSize.height - CGRectGetHeight(contentFrame)) / 2.0;
        } else {
            contentFrame.origin.y  = 0
        }
        
        imageView.frame = contentFrame
    }
    
    // MARK: - IBActions
    
    @IBAction func tap(sender: UITapGestureRecognizer) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

// MARK: - UIScrollViewDelegate

extension ImagePreviewController: UIScrollViewDelegate {
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContent()
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
