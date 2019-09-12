//
//  MainViewController.swift
//  AFKLFeedback
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet weak var actionsView: UIView!
    @IBOutlet weak var verticalImage: UIImageView!
    @IBOutlet weak var horizontalImage: UIImageView!
    @IBOutlet weak var toggleActionsButton: UIButton!
    
    private var pageController: FullHeightPageViewController!
    private var actionsScale: CGFloat = 1.0
    private var actionsTranslation = CGPoint(x: 0.0, y: 0.0)
    private var actionsOn = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let playersSize = CGSize(width: (view.frame.width - 90.0) / 2, height: (view.frame.height - 110.0) / 2)
        VideoPlayer.prepare(frame: CGRect(origin: .zero, size: playersSize))
        
        prepareActionsView()
        
        let pageControl = UIPageControl.appearance()
        pageControl.backgroundColor = UIColor(white: 1.0, alpha: 0.0)
        pageControl.pageIndicatorTintColor = UIColor(white: 1.0, alpha: 0.3)
        pageControl.currentPageIndicatorTintColor = UIColor(white: 1.0, alpha: 1.0)
        
        pageController = FullHeightPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.dataSource = self
        pageController.delegate = self
        pageController.view.frame = CGRect(origin: .zero, size: view.frame.size)
        addChild(pageController)
        view.insertSubview(pageController.view, at: 0)
        pageController.didMove(toParent: self)
        
        view.backgroundColor = UIColor.black
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.onGuidedAccessStatusChanged(notfication:)), name: UIAccessibility.guidedAccessStatusDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pageController.setViewControllers([page(0)!], direction: .forward, animated: false, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    private func prepareActionsView() {
        for actionView in actionsView.subviews {
            actionView.layer.cornerRadius = actionView.frame.height / 2
        }
        actionsScale = verticalImage.frame.height / (2 * actionsView.frame.height)
        actionsTranslation = CGPoint(x: verticalImage.frame.midX - actionsView.frame.midX, y: verticalImage.frame.midY - actionsView.frame.midY)
        toggleActions()
    }
    
    @IBAction func onExportNewFeedbacksPressed(_ sender: Any) {
        onToggleActionsPressed(self)
        if DataManager.shared.export(all: false) {
            okAlert(title: "Export done", message: "Feedbacks have been exported successfully.", ok: "OK")
        } else {
            okAlert(title: "Export failed", message: "An error occurred while trying to export the feedbacks.", ok: "OK")
        }
    }
    
    @IBAction func onExportAllFeedbacksPressed(_ sender: Any) {
        onToggleActionsPressed(self)
        if DataManager.shared.export() {
            okAlert(title: "Export done", message: "Feedbacks have been exported successfully.", ok: "OK")
        } else {
            okAlert(title: "Export failed", message: "An error occurred while trying to export the feedbacks.", ok: "OK")
        }
    }
    
    @IBAction func onDeleteAllFeedbacksPressed(_ sender: Any) {
        onToggleActionsPressed(self)
        yesNoAlert(title: "Confirm", message: "Are you sure you want to delete all feedbacks?", yes: "Yes", no: "Cancel") {
            DataManager.shared.deleteAllFeedbacks()
            self.pageController.setViewControllers([self.page(0)!], direction: .forward, animated: false, completion: nil)
        }
    }
    
    @IBAction func onDeleteAllProjectsPressed(_ sender: Any) {
        onToggleActionsPressed(self)
        yesNoAlert(title: "Confirm", message: "Are you sure you want to delete all projects?", yes: "Yes", no: "Cancel") {
            DataManager.shared.deleteAll()
            self.pageController.setViewControllers([self.page(0)!], direction: .forward, animated: false, completion: nil)
        }
    }
    
    @IBAction func onShowFeedbacks(_ sender: Any) {
        onToggleActionsPressed(self)
        guard let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FeedbacksVC") as? FeedbacksViewController else {
            return
        }
        vc.onDismiss = {
            vc.willMove(toParent: nil)
            UIView.animate(withDuration: 0.3, animations: {
                vc.view.alpha = 0.0
            }) { _ in
                vc.view.removeFromSuperview()
                vc.removeFromParent()
            }
        }
        addChild(vc)
        vc.view.frame = CGRect(origin: .zero, size: view.frame.size)
        vc.view.alpha = 0.0
        view.addSubview(vc.view)
        UIView.animate(withDuration: 0.3, animations: {
            vc.view.alpha = 1.0
        }) { _ in
            vc.didMove(toParent: self)
        }
    }
    
    private func yesNoAlert(title: String, message: String, yes: String, no: String, onYes: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: yes, style: .default) { _ in
            onYes()
        }
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: no, style: .cancel))
        present(alert, animated: true, completion: nil)
    }
    
    private func okAlert(title: String, message: String, ok: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: ok, style: .default))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onToggleActionsPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.toggleActions()
        }
    }
    
    private func toggleActions() {
        verticalImage.transform = actionsOn ? .identity : CGAffineTransform(rotationAngle: .pi / 2)
        horizontalImage.transform = actionsOn ? .identity : CGAffineTransform(rotationAngle: .pi / 2)
        horizontalImage.alpha = actionsOn ? 1.0 : 0.0
        actionsView.alpha = actionsOn ? 0.0 : 1.0
        actionsView.transform = actionsOn ? CGAffineTransform(scaleX: actionsScale, y: actionsScale)
            .concatenating(CGAffineTransform(translationX: actionsTranslation.x, y: actionsTranslation.y)) : .identity
        actionsOn = !actionsOn
    }
    
    private func page(_ index: Int) -> UIViewController? {
        guard index >= 0 && index < pageCount() else {
            return nil
        }
        
        let page = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProjectsContainerVC") as! ProjectsContainerViewController
        page.delegate = self
        page.pageIndex = index
        page.view.tag = index
        
        return page
    }
    
    private func pageCount() -> Int {
        let count = DataManager.shared.projects.count + (UIAccessibility.isGuidedAccessEnabled ? 0 : 1)
        return max(1, (count + 3) / 4)
    }

    @objc func onGuidedAccessStatusChanged(notfication: NSNotification) {
        if UIAccessibility.isGuidedAccessEnabled {
            if self.actionsOn {
                self.toggleActions()
            }
            self.horizontalImage.alpha = 0.0
            self.verticalImage.alpha = 0.0
            self.toggleActionsButton.alpha = 0.0
        } else {
            self.horizontalImage.alpha = 1.0
            self.verticalImage.alpha = 1.0
            self.toggleActionsButton.alpha = 1.0
        }
        pageController.setViewControllers([page(0)!], direction: .forward, animated: false, completion: nil)
        pageController.showPageControl()
    }
}

extension MainViewController : UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pageCount()
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return pageViewController.view.tag
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return page(viewController.view.tag - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return page(viewController.view.tag + 1)
    }
}

extension MainViewController: ProjectsContainerViewControllerDelegate {
    func projectsContainerViewControllerDidAddProject(_ controller: ProjectsContainerViewController) {
        pageController.setViewControllers([controller], direction: .forward, animated: false, completion: nil)
    }
    
    func projectsContainerViewControllerDidDeleteProject(_ controller: ProjectsContainerViewController) {
        pageController.setViewControllers([controller], direction: .forward, animated: false, completion: nil)
    }
    
    func projectsContainerViewControllerDidStartEditing(_ controller: ProjectsContainerViewController) {
        UIView.animate(withDuration: 0.3) {
            if self.actionsOn {
                self.toggleActions()
            }
            self.horizontalImage.alpha = 0.0
            self.verticalImage.alpha = 0.0
            self.toggleActionsButton.alpha = 0.0
        }
        pageController.hidePageControl()
    }
    
    func projectsContainerViewControllerDidEndEditing(_ controller: ProjectsContainerViewController) {
        if !UIAccessibility.isGuidedAccessEnabled {
            UIView.animate(withDuration: 0.3) {
                self.horizontalImage.alpha = 1.0
                self.verticalImage.alpha = 1.0
                self.toggleActionsButton.alpha = 1.0
            }
        }
        pageController.showPageControl()
    }
}

class FullHeightPageViewController: UIPageViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for subview in view.subviews {
            if subview is UIScrollView {
                subview.frame = view.bounds
            }
            else if subview is UIPageControl {
                view.bringSubviewToFront(subview)
                subview.frame = CGRect(origin: CGPoint(x: 0.0, y: view.frame.height - 40.0), size: subview.frame.size)
            }
        }
    }
    
    func hidePageControl() {
        for subview in view.subviews {
            if subview is UIPageControl {
                UIView.animate(withDuration: 0.3) {
                    subview.alpha = 0.0
                }
            } else if subview is UIScrollView {
                (subview as! UIScrollView).isScrollEnabled = false
            }
        }
    }
    
    func showPageControl() {
        for subview in view.subviews {
            if subview is UIPageControl {
                UIView.animate(withDuration: 0.3) {
                    subview.alpha = 1.0
                }
            } else if subview is UIScrollView {
                (subview as! UIScrollView).isScrollEnabled = true
            }
        }
    }
}

