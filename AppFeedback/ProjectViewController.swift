//
//  ProjectViewController.swift
//  AFKLFeedback
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import UIKit

protocol ProjectViewControllerDelegate {
    func projectViewControllerDidUpdateProject(_ projectViewController: ProjectViewController)
    func projectViewControllerDidSelectMediaLibrary(_ projectViewController: ProjectViewController)
}

class ProjectViewController: UIViewController {

    var delegate: ProjectViewControllerDelegate?
    var project: XProject?
    weak var player: VideoPlayer?
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var namePlaceHolder: UITextField!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var descPlaceHolder: UITextView!
    @IBOutlet weak var editMediaButton: UIButton!
    @IBOutlet weak var happyLabel: UILabel!
    @IBOutlet weak var neutralLabel: UILabel!
    @IBOutlet weak var sadLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    private(set) var name: String?
    private(set) var desc: String?
    private(set) var path: String?
    private(set) var isVideo: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 5.0
        
        view.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        
        name = project?.name
        desc = project?.desc
        path = project?.content
        isVideo = project == nil ? nil : (project!.type == .movie)
        
        if UIAccessibility.isGuidedAccessEnabled || name == nil {
            footerView.isHidden = true
        } else {
            for childView in footerView.subviews {
                childView.layer.cornerRadius = childView.frame.height / 2
                childView.clipsToBounds = true
            }
            updateRatings()
        }
        if isEditing {
            editMediaButton.isHidden = true //path == nil
            namePlaceHolder.isHidden = name != nil && name!.count > 0
            descPlaceHolder.isHidden = desc != nil && desc!.count > 0
            descPlaceHolder.isEditable = false
            namePlaceHolder.isEnabled = false
        }
        else {
            editMediaButton.isHidden = true
            namePlaceHolder.isHidden = true
            descPlaceHolder.isHidden = true
            nameTextField.isEnabled = false
            descTextView.isEditable = false
        }
        
        nameTextField.text = name
        descTextView.text = desc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateMedia()
    }
    
    func updateRatings() {
        happyLabel.text = "\(project?.moods[.happy] ?? 0)"
        neutralLabel.text = "\(project?.moods[.neutral] ?? 0)"
        sadLabel.text = "\(project?.moods[.sad] ?? 0)"
    }
    
    func updateMedia(path: String, isVideo: Bool) {
        self.path = path
        self.isVideo = isVideo
        updateMedia()
    }
    
    func attachVideo() {
        guard let player = player else {
            return
        }
        DispatchQueue.main.async {
            player.detach()
            guard let path = self.path, let isVideo = self.isVideo, isVideo else {
                return
            }
            player.attach(view: self.view, videoUrl: DataManager.shared.videoUrl(path: path))
        }
    }
    
    private func updateMedia() {
        guard let path = path, let isVideo = isVideo else {
            return
        }
        if isVideo {
            imageView.image = DataManager.shared.stillImageForMovie(atPath: path)
            imageView.contentMode = .scaleAspectFit
        } else {
            imageView.image = DataManager.shared.image(atPath: path)
            imageView.contentMode = .scaleAspectFill
        }
    }
    
    @IBAction func onEditMediaPressed(_ sender: Any) {
        delegate?.projectViewControllerDidSelectMediaLibrary(self)
    }
}

extension ProjectViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        namePlaceHolder.isHidden = text.count > 0
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        name = trimmed.count > 0 ? trimmed : nil
        delegate?.projectViewControllerDidUpdateProject(self)
        return true
    }
}

extension ProjectViewController : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        descPlaceHolder.isHidden = textView.text.count > 0
        let text = textView.text.trimmingCharacters(in: .whitespaces)
        desc = text.count > 0 ? text : nil
        delegate?.projectViewControllerDidUpdateProject(self)
    }
}

