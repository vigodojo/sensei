//
//  TextImagePreviewController.swift
//  Sensei
//
//  Created by Sauron Black on 6/8/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class TextImagePreviewController: UIViewController {
    
    private struct Constants {
        static let StoryboardName = "Main"
        static let StoryboardId = "TextImagePreviewController"
    }

    @IBOutlet weak var scrollView: UIScrollView!
    private weak var textImageView: TextImageView!
    
    var image: UIImage?
    var attributedText: NSAttributedString?
    
    // MARK: - Lifecycle
    
    class func imagePreviewControllerWithImage(image: UIImage) -> TextImagePreviewController {
        let storyboard = UIStoryboard(name: Constants.StoryboardName, bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier(Constants.StoryboardId) as! TextImagePreviewController
        viewController.image = image
        viewController.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
        viewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createImageView()
        textImageView.image = image
        textImageView.attributedText = attributedText
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let image = image {
            updateFrameAndContentSizeForImage(image)
        }
    }
    
    // MARK: - Private
    
    private func createImageView() {
        let textImageView = TextImageView(frame: CGRectZero)
        scrollView.addSubview(textImageView)
        self.textImageView = textImageView
    }
    
    private func updateFrameAndContentSizeForImage(image: UIImage) {
        textImageView.frame = CGRect(origin: CGPointZero, size: image.size)
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
        var contentFrame = textImageView.frame
        
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
        
        textImageView.frame = contentFrame
    }
    
    // MARK: - IBActions
    
    @IBAction func tap(sender: UITapGestureRecognizer) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - UIScrollViewDelegate

extension TextImagePreviewController: UIScrollViewDelegate {
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContent()
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return textImageView
    }
}
