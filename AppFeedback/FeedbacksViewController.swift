//
//  FeedbacksViewController.swift
//  AFKLFeedback
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import UIKit

class FeedbackCell: UITableViewCell {
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var moodImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
}

class ProjectCell : UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var happyImageView: UIImageView!
    @IBOutlet weak var neutralImageView: UIImageView!
    @IBOutlet weak var sadImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var happyLabel: UILabel!
    @IBOutlet weak var neutralLabel: UILabel!
    @IBOutlet weak var sadLabel: UILabel!
}

class FeedbacksViewController: UIViewController {
    
    @IBOutlet weak var projectsView: UICollectionView!
    @IBOutlet weak var feedbacksView: UITableView!
    
    var onDismiss: (() -> Void)? = nil
    
    private var selectedProject = 0

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onBackPressed(_ sender: Any) {
        onDismiss?()
    }
}

extension FeedbacksViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return DataManager.shared.projects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let project = DataManager.shared.projects[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "projectCell", for: indexPath) as! ProjectCell
        cell.titleLabel.text = project.name
        if project.type == .movie {
            cell.imageView.image = DataManager.shared.stillImageForMovie(atPath: project.content)
            cell.imageView.contentMode = .scaleAspectFit
        } else {
            cell.imageView.image = DataManager.shared.image(atPath: project.content)
            cell.imageView.contentMode = .scaleAspectFill
        }
        cell.happyLabel.text = "\(project.moods[.happy] ?? 0)"
        cell.neutralLabel.text = "\(project.moods[.neutral] ?? 0)"
        cell.sadLabel.text = "\(project.moods[.sad] ?? 0)"
        for view in [cell.happyLabel, cell.neutralLabel, cell.sadLabel, cell.happyImageView, cell.neutralImageView, cell.sadImageView] {
            view!.layer.cornerRadius = view!.frame.height / 2.0
        }
        cell.layer.cornerRadius = 10.0
        cell.layer.borderColor = indexPath.row == selectedProject ? UIColor(red: 0.12, green: 0.5, blue: 0.94, alpha: 1).cgColor : UIColor.white.cgColor
        cell.layer.borderWidth = indexPath.row == selectedProject ? 5.0 : 1.0
        return cell
    }
}

extension FeedbacksViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedProject = indexPath.row
        projectsView.reloadData()
        feedbacksView.reloadData()
    }
}

extension FeedbacksViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataManager.shared.projects[selectedProject].feedbacks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let feedback = DataManager.shared.projects[selectedProject].feedbacks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "feedbackCell", for: indexPath) as! FeedbackCell
        switch feedback.mood {
        case .happy: cell.moodImageView.image = UIImage(named: "happy")
        case .neutral: cell.moodImageView.image = UIImage(named: "neutral")
        case .sad: cell.moodImageView.image = UIImage(named: "sad")
        }
        cell.commentLabel.text = feedback.comment
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM' 'HH:mm:ss"
        cell.dateLabel.text = formatter.string(from: feedback.date)
        cell.moodImageView.layer.cornerRadius = cell.moodImageView.frame.height / 2.0
        cell.innerView.layer.cornerRadius = cell.moodImageView.layer.cornerRadius
        return cell
    }
    
    
}
