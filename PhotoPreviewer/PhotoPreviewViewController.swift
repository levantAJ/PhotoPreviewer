//
//  PhotoPreviewViewController.swift
//  PhotoPreviewer
//
//  Created by Tai Le on 9/13/19.
//  Copyright © 2019 Tai Le. All rights reserved.
//

import UIKit
import SDWebImage

final class PhotoPreviewViewController: UIViewController {
    let imageURLs: [URL]
    let startAtIndex: Int
    let interPageSpacing: CGFloat
    
    var dismissOnTouch = true
    var sourceImageView: UIImageView?
    var animationDuration: TimeInterval = 0.25
    var hideNavigationBarWhilePresenting = false
    
    private lazy var pageVC: UIPageViewController = {
        return UIPageViewController(transitionStyle: .scroll,
                                    navigationOrientation: .horizontal,
                                    options: [.interPageSpacing: interPageSpacing])
    }()
    private lazy var dismissInteractor = DismissInteractor(animationDuration: animationDuration)
    private var currentIndex: Int
    private var dismissingImageView: UIImageView?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    init(imageURLs: [URL],
         startAtIndex: Int = 0,
         interPageSpacing: CGFloat = 20) {
        self.imageURLs = imageURLs
        self.startAtIndex = startAtIndex
        self.currentIndex = startAtIndex
        self.interPageSpacing = interPageSpacing
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension PhotoPreviewViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator(animationDuration: animationDuration,
                               sourceImageView: sourceImageView,
                               hideNavigationBarWhilePresenting: hideNavigationBarWhilePresenting)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator(animationDuration: animationDuration,
                               sourceImageView: sourceImageView == nil ? nil : dismissingImageView,
                               targetImageView: currentIndex == startAtIndex ? sourceImageView : nil)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        dismissInteractor.targetImageView = currentIndex == startAtIndex ? sourceImageView : nil
        return dismissInteractor.hasStarted ? dismissInteractor : nil
    }
}

// MARK: - UIPageViewControllerDataSource

extension PhotoPreviewViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? PhotoPreviewContentViewController,
            let url = imageURLs[safe: vc.index - 1] else { return nil }
        return contentVC(imageURL: url, index: vc.index - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? PhotoPreviewContentViewController,
            let url = imageURLs[safe: vc.index + 1] else { return nil }
        return contentVC(imageURL: url, index: vc.index + 1)
    }
}

// MARK: - UIPageViewControllerDelegate

extension PhotoPreviewViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
            let vc = pageViewController.viewControllers?.last as? PhotoPreviewContentViewController else { return }
        currentIndex = vc.index
    }
}

// MARK: - Privates

extension PhotoPreviewViewController {
    private func setupViews() {
        view.backgroundColor = .black
        transitioningDelegate = self
        
        pageVC.dataSource = self
        pageVC.delegate = self
        pageVC.willMove(toParent: self)
        pageVC.view.frame = view.bounds
        
        if let url = imageURLs[safe: startAtIndex] {
            let vc = contentVC(imageURL: url, index: startAtIndex)
            vc.placeholderImage = sourceImageView?.image
            pageVC.setViewControllers([vc],
                                      direction: .forward,
                                      animated: true,
                                      completion: nil)
        }
        
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)
    }
    
    private func contentVC(imageURL: URL, index: Int) -> PhotoPreviewContentViewController {
        let vc = PhotoPreviewContentViewController(imageURL: imageURL, index: index)
        vc.dismissInteractor = dismissInteractor
        vc.onDismiss = { [weak self] dismissBy, imageView in
            self?.dismissingImageView = imageView
            switch dismissBy {
            case .touch:
                guard self?.dismissOnTouch == true else { return }
                self?.dismiss(animated: true, completion: nil)
            case .drag:
                self?.dismiss(animated: true, completion: nil)
            }
        }
        return vc
    }
}

// MARK: - PresentAnimator

private final class PresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let animationDuration: TimeInterval
    let sourceImageView: UIImageView?
    let hideNavigationBarWhilePresenting: Bool
    
    init(animationDuration: TimeInterval,
         sourceImageView: UIImageView?,
         hideNavigationBarWhilePresenting: Bool) {
        self.animationDuration = animationDuration
        self.sourceImageView = sourceImageView
        self.hideNavigationBarWhilePresenting = hideNavigationBarWhilePresenting
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        
        if hideNavigationBarWhilePresenting {
            (transitionContext.viewController(forKey: .from) as? UINavigationController)?.setNavigationBarHidden(true, animated: true)
        }
        
        if let sourceImageView = sourceImageView,
            let image = sourceImageView.image {
            toView.isHidden = true
            sourceImageView.isHidden = true
            containerView.addSubview(toView)
            
            let backgroundView = UIView(frame: toView.frame)
            backgroundView.backgroundColor = .black
            backgroundView.alpha = 0.0
            containerView.addSubview(backgroundView)
            
            let windowFrame = sourceImageView.superview?.convert(sourceImageView.frame, to: nil)
            let animatingImageView = UIImageView(frame: windowFrame ?? sourceImageView.frame)
            animatingImageView.image = sourceImageView.image
            animatingImageView.contentMode = sourceImageView.contentMode
            containerView.addSubview(animatingImageView)
            
            let targetImageRect = toView.rect(aspectRatio: image.size)
            UIView.animate(withDuration: animationDuration,
                           delay: 0.0,
                           options: .curveLinear,
                           animations: {
                            backgroundView.alpha = 1.0
                            animatingImageView.frame = targetImageRect
            }, completion: { _ in
                toView.isHidden = false
                sourceImageView.isHidden = false
                backgroundView.removeFromSuperview()
                animatingImageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        } else {
            let backgroundView = UIView(frame: toView.frame)
            backgroundView.backgroundColor = .black
            backgroundView.alpha = 0.0
            containerView.addSubview(backgroundView)
            
            toView.alpha = 0.0
            containerView.addSubview(toView)
            
            UIView.animate(withDuration: animationDuration,
                           delay: 0.0,
                           options: .curveEaseIn,
                           animations: {
                            toView.alpha = 1.0
                            backgroundView.alpha = 1.0
            }, completion: { _ in
                backgroundView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}

// MARK: - DismissAnimator

private final class DismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let animationDuration: TimeInterval
    let sourceImageView: UIImageView?
    let targetImageView: UIImageView?
    
    init(animationDuration: TimeInterval,
         sourceImageView: UIImageView?,
         targetImageView: UIImageView?) {
        self.animationDuration = animationDuration
        self.sourceImageView = sourceImageView
        self.targetImageView = targetImageView
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let fromView = transitionContext.view(forKey: .from)!
        let toView = transitionContext.view(forKey: .to)!
        containerView.insertSubview(toView, belowSubview: fromView)
        
        if let sourceImageView = sourceImageView,
            let image = sourceImageView.image {
            if let targetImageView = targetImageView {
                targetImageView.isHidden = true
                let sourceFrame = sourceImageView.rect(aspectRatio: image.size)
                let animatingImageView = UIImageView(frame: sourceFrame)
                animatingImageView.image = sourceImageView.image
                animatingImageView.contentMode = targetImageView.contentMode
                containerView.addSubview(animatingImageView)
                
                let windowFrame = targetImageView.superview?.convert(targetImageView.frame, to: nil)
                let targetFrame = windowFrame ?? targetImageView.frame
                UIView.animate(withDuration: animationDuration,
                               delay: 0.0,
                               options: .curveLinear,
                               animations: {
                                animatingImageView.frame = targetFrame
                                fromView.alpha = 0.0
                }, completion: { _ in
                    targetImageView.isHidden = false
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
            } else {
                let targetFrame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height)
                UIView.animate(withDuration: animationDuration,
                               delay: 0.0,
                               options: .curveEaseOut,
                               animations: {
                                fromView.frame = targetFrame
                                fromView.alpha = 0.0
                }, completion: { _ in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
            }
        } else {
            UIView.animate(withDuration: animationDuration,
                           delay: 0.0,
                           options: .curveEaseOut,
                           animations: {
                            fromView.alpha = 0.0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}

private extension UIView {
    //This is get image size in scale aspect fit image view.
    func rect(aspectRatio size: CGSize) -> CGRect {
        var aspectFitSize = CGSize(width: frame.size.width,
                                   height: frame.size.height)
        let newWidth = frame.size.width / size.width
        let newHeight = frame.size.height / size.height
        
        if newHeight < newWidth {
            aspectFitSize.width = newHeight * size.width
        } else if newWidth < newHeight {
            aspectFitSize.height = newWidth * size.height
        }
        let origin = CGPoint(x: frame.size.width / 2 - aspectFitSize.width / 2,
                             y: frame.size.height / 2 - aspectFitSize.height / 2)
        return CGRect(origin: origin, size: aspectFitSize)
    }
}

// MARK: - PhotoPreviewContentViewController

private final class PhotoPreviewContentViewController: UIViewController {
    let imageURL: URL
    let index: Int
    
    var onDismiss: ((_ by: DismissBy, _ source: UIImageView) -> Void)?
    var dismissInteractor: DismissInteractor?
    var placeholderImage: UIImage?
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.maximumZoomScale = 4.0
        scrollView.contentSize = view.bounds.size
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        if #available(iOS 11, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        return scrollView
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        imageView.sd_imageTransition = .fade
        return imageView
    }()
    
    lazy var progressIndicatorView: CircularLoaderView = {
        let progressIndicatorView = CircularLoaderView(frame: .zero)
        progressIndicatorView.isHidden = true
        return progressIndicatorView
    }()
    
    init(imageURL: URL, index: Int) {
        self.imageURL = imageURL
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scrollView.zoomScale = 1
    }
    
    enum DismissBy {
        case touch
        case drag
    }
}

// MARK: - UIScrollViewDelegate

extension PhotoPreviewContentViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PhotoPreviewContentViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer,
            scrollView.zoomScale == 1 {
            return isVerticalGesture(panGestureRecognizer)
        }
        return false
    }
}

// MARK: - Privates

extension PhotoPreviewContentViewController {
    private func setupViews() {
        view.backgroundColor = .clear
        
        view.addSubview(progressIndicatorView)
        progressIndicatorView.center = view.center
        
        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.addSubview(imageView)
        
        imageView.sd_setImage(with: imageURL, placeholderImage: placeholderImage, options: .highPriority, progress: { [weak self] receivedSize, expectedSize, _ in
            DispatchQueue.main.async { [weak self] in
                self?.progressIndicatorView.isHidden = false
                self?.progressIndicatorView.progress = CGFloat(receivedSize) / CGFloat(expectedSize)
            }
            }, completed: { [weak self] _, _, _, _ in
                DispatchQueue.main.async { [weak self] in
                    self?.progressIndicatorView.isHidden = true
                }
        })
        
        let dismissPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handle(dismissPanGesture:)))
        dismissPanGesture.delegate = self
        imageView.addGestureRecognizer(dismissPanGesture)
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handle(singleTapGesture:)))
        scrollView.addGestureRecognizer(singleTapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handle(doubleTapGesture:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        singleTapGesture.require(toFail: doubleTapGesture)
    }
    
    @objc private func handle(dismissPanGesture: UIPanGestureRecognizer) {
        let translation = dismissPanGesture.translation(in: view)
        if let dismissInteractor = dismissInteractor {
            switch dismissPanGesture.state {
            case .began:
                dismissInteractor.hasStarted = true
                dismissInteractor.start(source: imageView)
                onDismiss?(.touch, imageView)
            case .changed:
                dismissInteractor.update(translation.y)
            case .cancelled:
                dismissInteractor.hasStarted = false
                dismissInteractor.cancel()
            case .ended:
                dismissInteractor.hasStarted = false
                dismissInteractor.shouldFinish ? dismissInteractor.finish() : dismissInteractor.cancel()
            default:
                break
            }
        }
        
        dismissPanGesture.setTranslation(.zero, in: view)
    }
    
    @objc private func handle(singleTapGesture: UIPanGestureRecognizer) {
        onDismiss?(.touch, imageView)
    }
    
    @objc private func handle(doubleTapGesture: UIPanGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            let center = doubleTapGesture.location(in: doubleTapGesture.view)
            scrollView.zoom(to: zoomedRect(for: scrollView.maximumZoomScale, center: center), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    private func isVerticalGesture(_ recognizer: UIPanGestureRecognizer) -> Bool {
        let translation = recognizer.translation(in: recognizer.view)
        return abs(translation.y) > abs(translation.x)
    }
    
    private func zoomedRect(for scale: CGFloat, center: CGPoint) -> CGRect {
        var rect: CGRect = .zero
        rect.size.height = imageView.frame.height / scale
        rect.size.width  = imageView.frame.width  / scale
        let center = scrollView.convert(center, from: imageView)
        rect.origin.x = center.x - (rect.width / 2.0)
        rect.origin.y = center.y - (rect.height / 2.0)
        return rect
    }
}

// MARK: - DismissInteractor

private final class DismissInteractor: NSObject {
    let animationDuration: TimeInterval
    var hasStarted = false
    var shouldFinish = false
    var sourceImageView: UIImageView?
    var targetImageView: UIImageView?
    
    private var transitionContext: UIViewControllerContextTransitioning?
    private var animatingImageView: UIImageView?
    private var backgroundView: UIView?
    
    init(animationDuration: TimeInterval) {
        self.animationDuration = animationDuration
    }
    
    func start(source imageView: UIImageView) {
        sourceImageView = imageView
    }
    
    func update(_ translationY: CGFloat) {
        targetImageView?.isHidden = true
        guard let animatingImageView = animatingImageView else { return }
        animatingImageView.center = CGPoint(x: animatingImageView.center.x,
                                            y: animatingImageView.center.y + translationY)
        if let toView = transitionContext?.view(forKey: .to) {
            shouldFinish = animatingImageView.center.y <= toView.frame.height / 4
                || animatingImageView.center.y >= 3 * toView.frame.height / 4
            let factor = min(animatingImageView.center.y, toView.frame.height - animatingImageView.center.y)
            backgroundView?.alpha = factor / (toView.frame.height / 2)
        }
    }
    
    func finish() {
        let completion = { [weak self] in
            self?.targetImageView?.isHidden = false
            self?.animatingImageView?.removeFromSuperview()
            self?.backgroundView?.removeFromSuperview()
            self?.transitionContext?.view(forKey: .to)?.removeFromSuperview()
            self?.transitionContext?.completeTransition(true)
        }
        if let targetImageView = targetImageView,
            let image = targetImageView.image,
            let animatingImageView = animatingImageView {
            animatingImageView.frame = animatingImageView.rect(aspectRatio: image.size)
            animatingImageView.contentMode = targetImageView.contentMode
            
            let windowFrame = targetImageView.superview?.convert(targetImageView.frame, to: nil)
            let frame = windowFrame ?? targetImageView.frame
            UIView.animate(withDuration: animationDuration,
                           delay: 0.0,
                           options: .curveLinear,
                           animations: {
                            self.animatingImageView?.frame = frame
                            self.backgroundView?.alpha = 0.0
            }, completion: { _ in
                completion()
            })
        } else if let toView = transitionContext?.view(forKey: .to) {
            let frame = toView.frame.offsetBy(dx: 0, dy: toView.frame.height)
            UIView.animate(withDuration: animationDuration,
                           animations: {
                            self.animatingImageView?.frame = frame
                            self.backgroundView?.alpha = 0.0
            }, completion: { _ in
                completion()
            })
        } else {
            completion()
        }
    }
    
    func cancel() {
        let completion = { [weak self] in
            self?.targetImageView?.isHidden = false
            self?.animatingImageView?.removeFromSuperview()
            self?.backgroundView?.removeFromSuperview()
            self?.transitionContext?.view(forKey: .to)?.removeFromSuperview()
            self?.transitionContext?.completeTransition(false)
        }
        if let sourceImageView = sourceImageView {
            let frame = sourceImageView.frame
            UIView.animate(withDuration: animationDuration,
                           delay: 0.0,
                           options: .curveLinear,
                           animations: {
                            self.animatingImageView?.frame = frame
                            self.backgroundView?.alpha = 1.0
            }, completion: { _ in
                completion()
            })
        } else {
            completion()
        }
    }
}

// MARK: - UIViewControllerInteractiveTransitioning

extension DismissInteractor: UIViewControllerInteractiveTransitioning {
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        let containerView = transitionContext.containerView
        guard let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        containerView.addSubview(toView)
        
        backgroundView = UIView(frame: toView.bounds)
        backgroundView?.backgroundColor = .black
        containerView.addSubview(backgroundView!)
        
        if let sourceImageView = sourceImageView {
            animatingImageView = UIImageView(frame: sourceImageView.frame)
            animatingImageView?.contentMode = sourceImageView.contentMode
            animatingImageView?.image = sourceImageView.image
            containerView.addSubview(animatingImageView!)
        }
    }
}

// MARK: - CircularLoaderView

private final class CircularLoaderView: UIView {
    lazy var circlePathLayer = CAShapeLayer()
    let circleRadius: CGFloat = 20.0
    
    var progress: CGFloat {
        get {
            return circlePathLayer.strokeEnd
        }
        set {
            if newValue > 1 {
                circlePathLayer.strokeEnd = 1
            } else if newValue < 0 {
                circlePathLayer.strokeEnd = 0
            } else {
                circlePathLayer.strokeEnd = newValue
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circlePathLayer.frame = bounds
        circlePathLayer.path = circlePath.cgPath
    }
}

// MARK: - Privates

extension CircularLoaderView {
    private var circleFrame: CGRect {
        var frame = CGRect(x: 0, y: 0, width: 2 * circleRadius, height: 2 * circleRadius)
        let circlePathBounds = circlePathLayer.bounds
        frame.origin.x = circlePathBounds.midX - frame.midX
        frame.origin.y = circlePathBounds.midY - frame.midY
        return frame
    }
    
    private var circlePath: UIBezierPath {
        return UIBezierPath(ovalIn: circleFrame)
    }
    
    private func setupViews() {
        circlePathLayer.frame = bounds
        circlePathLayer.lineWidth = 2
        circlePathLayer.fillColor = UIColor.clear.cgColor
        circlePathLayer.strokeColor = UIColor.white.cgColor
        progress = 0
        layer.addSublayer(circlePathLayer)
        backgroundColor = .white
    }
}

extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}
