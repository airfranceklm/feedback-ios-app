//
//  NewFeedbackViewController.swift
//  AFKLFeedback
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import UIKit

protocol NewFeedbackViewControllerDelegate {
    func newFeedbackViewControllerDidFinish(_ newFeedbackViewController: NewFeedbackViewController)
}

class NewFeedbackViewController: UIViewController {

    var project: XProject!
    var delegate: NewFeedbackViewControllerDelegate?
    
    @IBOutlet weak var projectView: UIView!
    @IBOutlet weak var projectWidth: NSLayoutConstraint!
    @IBOutlet weak var projectHeight: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var happyButton: UIButton!
    @IBOutlet weak var neutralButton: UIButton!
    @IBOutlet weak var sadButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    private var projectVC: ProjectViewController!
    private var mood: Mood? = nil
    private var buttonBackgroundColor: UIColor!
    private var projectViewSize: CGSize!
    private let scaleTransform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonBackgroundColor = sendButton.backgroundColor
        projectView.layer.cornerRadius = 5.0
        projectView.layer.borderWidth = 0.5
        projectView.layer.borderColor = UIColor.white.cgColor
        textView.layer.cornerRadius = 5.0
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.white.cgColor
        
        projectViewSize = CGSize(width: (view.frame.width - 90.0) / 2, height: (view.frame.height - 110.0) / 2)
        projectWidth.constant = projectViewSize.width
        projectHeight.constant = projectViewSize.height
        view.layoutIfNeeded()
        
        projectVC = (UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProjectVC") as! ProjectViewController)
        projectVC.isEditing = false
        projectVC.project = project
        projectVC.player = VideoPlayer.at(4)
        addChild(projectVC)
        projectVC.view.frame = CGRect(origin: .zero, size: projectViewSize)
        projectView.addSubview(projectVC.view)
        projectVC.didMove(toParent: self)
        
        happyButton.transform = scaleTransform
        neutralButton.transform = scaleTransform
        sadButton.transform = scaleTransform
        
        for button in [happyButton, neutralButton, sadButton, sendButton] as! [UIButton] {
            button.layer.cornerRadius = button.frame.height / 2
        }
        manageAddButtonState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        projectVC.attachVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        VideoPlayer.at(4)?.detach()
    }

    @IBAction func onBackPressed(_ sender: Any) {
        let trimmed = textView.text.trimmingCharacters(in: .whitespaces)
        if trimmed.count > 0 || mood != nil {
            yesNoAlert(title: "Confirm", message: "By returning to the list of projects, your feedback will be lost.\n\nProceed anyway ?", yes: "Yes", no: "Cancel") {
                self.delegate?.newFeedbackViewControllerDidFinish(self)
            }
        } else {
            delegate?.newFeedbackViewControllerDidFinish(self)
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
    
    @IBAction func onHappyPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.happyButton.transform = .identity
            self.neutralButton.transform = self.scaleTransform
            self.sadButton.transform = self.scaleTransform
        }
        mood = .happy
        manageAddButtonState()
    }
    
    @IBAction func onNeutralPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.happyButton.transform = self.scaleTransform
            self.neutralButton.transform = .identity
            self.sadButton.transform = self.scaleTransform
        }
        mood = .neutral
        manageAddButtonState()
    }
    
    @IBAction func onSadPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.happyButton.transform = self.scaleTransform
            self.neutralButton.transform = self.scaleTransform
            self.sadButton.transform = .identity
        }
        mood = .sad
        manageAddButtonState()
    }
    
    @IBAction func onSendPressed(_ sender: Any) {
        let trimmed = textView.text.trimmingCharacters(in: .whitespaces)
        DataManager.shared.addFeedback(projectId: project.id, comment: trimmed, mood: mood!)
        delegate?.newFeedbackViewControllerDidFinish(self)
    }
    
    private func manageAddButtonState() {
        if mood != nil {
            sendButton.isEnabled = true
            sendButton.backgroundColor = buttonBackgroundColor
        } else {
            sendButton.isEnabled = false
            sendButton.backgroundColor = UIColor(white: 0.6, alpha: 1.0)
        }
    }
}

extension NewFeedbackViewController : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        
    }
}
