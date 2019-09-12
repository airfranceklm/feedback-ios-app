//
//  ProjectsContainerViewController.swift
//  AFKLFeedback
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import UIKit

protocol ProjectsContainerViewControllerDelegate {
    func projectsContainerViewControllerDidStartEditing(_ controller: ProjectsContainerViewController)
    func projectsContainerViewControllerDidEndEditing(_ controller: ProjectsContainerViewController)
    func projectsContainerViewControllerDidAddProject(_ controller: ProjectsContainerViewController)
    func projectsContainerViewControllerDidDeleteProject(_ controller: ProjectsContainerViewController)
}

class ProjectsContainerViewController: UIViewController {

    var pageIndex: Int!
    var delegate: ProjectsContainerViewControllerDelegate?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var projectVCs: [ProjectViewController]!
    private var vcTransform: CGAffineTransform!
    private var isShowing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        projectVCs = []
        NotificationCenter.default.addObserver(self, selector: #selector(ProjectsContainerViewController.onGuidedAccessStatusChanged), name: UIAccessibility.guidedAccessStatusDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        isShowing = true
        for projectVC in projectVCs {
            projectVC.attachVideo()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        isShowing = false
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func onGuidedAccessStatusChanged(notfication: NSNotification) {
        collectionView.reloadData()
    }

    func prepareChildViewControllers() {
        for vc in projectVCs {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
        projectVCs = []
        let first = pageIndex * 4
        let last = min(DataManager.shared.projects.count, first + 4)
        guard first < last else {
            return
        }
        for i in first..<last {
            let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProjectVC") as! ProjectViewController
            vc.project = DataManager.shared.projects[i]
            projectVCs.append(vc)
            addChild(vc)
            vc.view.frame = CGRect(origin: .zero, size: VideoPlayer.size)
            vc.didMove(toParent: self)
        }
    }
}

extension ProjectsContainerViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        prepareChildViewControllers()
        return min(4, projectVCs.count + (UIAccessibility.isGuidedAccessEnabled ? 0 : 1))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell : UICollectionViewCell
        if indexPath.row == projectVCs.count {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCell", for: indexPath)
            cell.layer.cornerRadius = 5.0
            cell.layer.borderWidth = 0.5
            cell.layer.borderColor = UIColor.white.cgColor
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "projectCell", for: indexPath)
            let vc = projectVCs[indexPath.row]
            cell.addSubview(vc.view)
            vc.player = VideoPlayer.at(indexPath.row)
            if isShowing {
                vc.attachVideo()
            }
        }
        return cell
    }
}

extension ProjectsContainerViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let x = (indexPath.row == 0 || indexPath.row == 2) ? 30.0 : 60.0 + VideoPlayer.size.width
        let y = (indexPath.row == 0 || indexPath.row == 1) ? 40.0 : 70.0 + VideoPlayer.size.height
        let srcRect = CGRect(origin: CGPoint(x: x, y: y), size: VideoPlayer.size)
        vcTransform = CGAffineTransform(scaleX: srcRect.width / view.frame.width, y: srcRect.height / view.frame.height)
            .concatenating(CGAffineTransform(translationX: srcRect.midX - view.frame.midX, y: srcRect.midY - view.frame.midY))
        
        if UIAccessibility.isGuidedAccessEnabled {
            guard let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "newFeedbackVC") as? NewFeedbackViewController else {
                return
            }
            delegate?.projectsContainerViewControllerDidStartEditing(self)
            vc.project = DataManager.shared.projects[pageIndex * 4 + indexPath.row]
            vc.delegate = self
            addChild(vc)
            vc.view.frame = CGRect(origin: .zero, size: view.frame.size)
            vc.view.transform = vcTransform
            vc.view.alpha = 0.0
            view.addSubview(vc.view)
            UIView.animate(withDuration: 0.5, animations: {
                vc.view.alpha = 1.0
                vc.view.transform = .identity
            }) { _ in
                vc.didMove(toParent: self)
            }
            
            
        } else {
            guard let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProjectEditVC") as? ProjectEditViewController else {
                return
            }
            delegate?.projectsContainerViewControllerDidStartEditing(self)
            if indexPath.row == projectVCs.count {
                vc.creation = true
            } else {
                vc.project = DataManager.shared.projects[pageIndex * 4 + indexPath.row]
            }
            vc.delegate = self
            addChild(vc)
            vc.view.frame = CGRect(origin: .zero, size: view.frame.size)
            vcTransform = .identity
            vc.view.transform = vcTransform
            vc.view.alpha = 0.0
            view.addSubview(vc.view)
            UIView.animate(withDuration: 0.3, animations: {
                vc.view.alpha = 1.0
                vc.view.transform = .identity
            }) { _ in
                vc.didMove(toParent: self)
            }
        }
    }
}

extension ProjectsContainerViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return VideoPlayer.size
    }
}

extension ProjectsContainerViewController : NewFeedbackViewControllerDelegate {
    func newFeedbackViewControllerDidFinish(_ newFeedbackViewController: NewFeedbackViewController) {
        dismissEditVC(newFeedbackViewController)
    }
}

extension ProjectsContainerViewController : ProjectEditViewControllerDelegate {
    func projectEditViewControllerDidCancelAdd(_ projectEditViewController: ProjectEditViewController) {
        dismissEditVC(projectEditViewController)
    }
    
    func projectEditViewControllerDidAddProject(_ projectEditViewController: ProjectEditViewController) {
        collectionView.reloadData()
        dismissEditVC(projectEditViewController)
        delegate?.projectsContainerViewControllerDidAddProject(self)
    }
    
    func projectEditViewControllerDidDeleteProject(_ projectEditViewController: ProjectEditViewController) {
        collectionView.reloadData()
        dismissEditVC(projectEditViewController)
        delegate?.projectsContainerViewControllerDidDeleteProject(self)
    }
    
    func projectEditViewControllerDidUpdateProject(_ projectEditViewController: ProjectEditViewController) {
        dismissEditVC(projectEditViewController)
        collectionView.reloadData()
    }
    
    private func dismissEditVC(_ vc: UIViewController) {
        vc.willMove(toParent: nil)
        UIView.animate(withDuration: 0.3, animations: {
            vc.view.alpha = 0.0
            vc.view.transform = self.vcTransform
        }) { _ in
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
        delegate?.projectsContainerViewControllerDidEndEditing(self)
    }
}
