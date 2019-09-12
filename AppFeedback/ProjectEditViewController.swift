//
//  ProjectEditViewController.swift
//  AFKLFeedback
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import UIKit

protocol ProjectEditViewControllerDelegate {
    func projectEditViewControllerDidCancelAdd(_ projectEditViewController: ProjectEditViewController)
    func projectEditViewControllerDidAddProject(_ projectEditViewController: ProjectEditViewController)
    func projectEditViewControllerDidDeleteProject(_ projectEditViewController: ProjectEditViewController)
    func projectEditViewControllerDidUpdateProject(_ projectEditViewController: ProjectEditViewController)
}

class ProjectEditViewController: UIViewController {

    var creation: Bool = false
    var project: XProject?
    var delegate: ProjectEditViewControllerDelegate?
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var projectView: UIView!
    @IBOutlet weak var additionalView: UIView!
    @IBOutlet weak var actionsView: UIView!
    @IBOutlet weak var verticalImage: UIImageView!
    @IBOutlet weak var horizontalImage: UIImageView!
    @IBOutlet weak var toggleActionsButton: UIButton!
    @IBOutlet weak var projectViewWidth: NSLayoutConstraint!
    @IBOutlet weak var projectViewHeight: NSLayoutConstraint!
    
    private var actionsScale: CGFloat = 1.0
    private var actionsTranslation = CGPoint(x: 0.0, y: 0.0)
    private var actionsOn = true
    private var buttonBackgroundColor: UIColor!
    private var projectViewSize: CGSize!
    private var projectVC: ProjectViewController!
    private var mediaLibraryVC: MediaLibraryViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonBackgroundColor = addButton.backgroundColor
        projectView.layer.cornerRadius = 5.0
        projectView.layer.borderWidth = 0.5
        projectView.layer.borderColor = UIColor.white.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        prepareMediaLibrary()
        prepareProject()
        prepareActionsView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        VideoPlayer.at(4)?.detach()
    }
    
    private func prepareMediaLibrary() {
        mediaLibraryVC = (UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaLibraryVC") as! MediaLibraryViewController)
        mediaLibraryVC.delegate = self
        addChild(mediaLibraryVC)
        mediaLibraryVC.view.frame = CGRect(origin: .zero, size: additionalView.frame.size)
        additionalView.addSubview(mediaLibraryVC.view)
        mediaLibraryVC.didMove(toParent: self)
    }
    
    private func prepareProject() {
        projectViewSize = CGSize(width: (view.frame.width - 90.0) / 2, height: (view.frame.height - 110.0) / 2)
        projectViewWidth.constant = projectViewSize.width
        projectViewHeight.constant = projectViewSize.height
        view.layoutIfNeeded()
        
        projectVC = (UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProjectVC") as! ProjectViewController)
        projectVC.isEditing = true
        projectVC.delegate = self
        projectVC.project = project
        projectVC.player = VideoPlayer.at(4)
        addChild(projectVC)
        projectVC.view.frame = CGRect(origin: .zero, size: projectViewSize)
        projectView.addSubview(projectVC.view)
        projectVC.didMove(toParent: self)
        
        if creation {
            addButton.layer.cornerRadius = addButton.frame.height / 2
            manageAddButtonState()
        } else {
            addButton.isHidden = true
            projectVC.attachVideo()
        }
    }
    
    private func prepareActionsView() {
        if creation {
            actionsView.isHidden = true
            toggleActionsButton.isHidden = true
            horizontalImage.isHidden = true
            verticalImage.isHidden = true
        } else {
            for actionView in actionsView.subviews {
                actionView.layer.cornerRadius = actionView.frame.height / 2
            }
            actionsScale = verticalImage.frame.height / (2 * actionsView.frame.height)
            actionsTranslation = CGPoint(x: verticalImage.frame.midX - actionsView.frame.midX, y: verticalImage.frame.midY - actionsView.frame.midY)
            toggleActions()
        }
    }
    
    private func manageAddButtonState() {
        if let _ = projectVC.name, let _ = projectVC.path {
            addButton.isEnabled = true
            addButton.backgroundColor = buttonBackgroundColor
        } else {
            addButton.isEnabled = false
            addButton.backgroundColor = UIColor(white: 0.6, alpha: 1.0)
        }
    }

    @IBAction func onBackPressed(_ sender: Any) {
        if !creation, let project = project, let name = projectVC.name, let path = projectVC.path, let isVideo = projectVC.isVideo {
            let desc = projectVC.desc ?? ""
            DataManager.shared.update(projectId: project.id, name: name, description: desc, path: path, isVideo: isVideo)
            delegate?.projectEditViewControllerDidUpdateProject(self)
        } else {
            delegate?.projectEditViewControllerDidCancelAdd(self)
        }
    }
    
    @IBAction func onAddPressed(_ sender: Any) {
        _ = DataManager.shared.addProject(name: projectVC.name!, description: projectVC.desc ?? "", path: projectVC.path!, isVideo: projectVC.isVideo!)
        delegate?.projectEditViewControllerDidAddProject(self)
    }
    
    @IBAction func onDeleteFeedbacksPressed(_ sender: Any) {
        onToggleActionsPressed(self)
        yesNoAlert(title: "Confirm", message: "Are you sure you want to delete project feedbacks?", yes: "Yes", no: "Cancel") {
            DataManager.shared.deleteFeedbacks(project: self.project!)
            self.projectVC.updateRatings()
        }
    }
    
    @IBAction func onDeleteProjectPressed(_ sender: Any) {
        onToggleActionsPressed(self)
        yesNoAlert(title: "Confirm", message: "Are you sure you want to delete this project?", yes: "Yes", no: "Cancel") {
            DataManager.shared.delete(project: self.project!)
            self.delegate?.projectEditViewControllerDidDeleteProject(self)
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
}

extension ProjectEditViewController : ProjectViewControllerDelegate {
    func projectViewControllerDidUpdateProject(_ projectViewController: ProjectViewController) {
        if creation {
            manageAddButtonState()
        }
    }
    
    func projectViewControllerDidSelectMediaLibrary(_ projectViewController: ProjectViewController) {
        
    }
}

extension ProjectEditViewController : MediaLibraryViewControllerDelegate {
    func mediaLibraryViewController(_ mediaLibraryViewController: MediaLibraryViewController, didSelect path: String, isVideo: Bool) {
        projectVC.updateMedia(path: path, isVideo: isVideo)
        if isVideo {
            projectVC.attachVideo()
        } else {
            VideoPlayer.at(4)?.detach()
        }
        manageAddButtonState()
    }
}
