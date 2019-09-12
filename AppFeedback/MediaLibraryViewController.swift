//
//  MediaLibraryViewController.swift
//  AFKLFeedback
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import UIKit

class MediaLibraryViewCell : UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}

protocol MediaLibraryViewControllerDelegate {
    func mediaLibraryViewController(_ mediaLibraryViewController: MediaLibraryViewController, didSelect path: String, isVideo: Bool)
}

class MediaLibraryViewController: UIViewController {
    
    var delegate: MediaLibraryViewControllerDelegate?

    private var cellSize: CGSize!
    private var documents: [(url: URL, isVideo: Bool)]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cellSize = CGSize(width: VideoPlayer.size.width / 2, height: VideoPlayer.size.height / 2)
    }
}

extension MediaLibraryViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        documents = DataManager.shared.mediaDocuments()
        return documents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: MediaLibraryViewCell
        if documents[indexPath.row].isVideo {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "videoCell", for: indexPath) as! MediaLibraryViewCell
            cell.imageView.image = DataManager.shared.stillImageForMovie(at: documents[indexPath.row].url)
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! MediaLibraryViewCell
            cell.imageView.image = DataManager.shared.image(at: documents[indexPath.row].url)
        }
        cell.layer.cornerRadius = 5.0
        cell.layer.borderWidth = 0.5
        cell.layer.borderColor = UIColor.white.cgColor
        return cell
    }
}

extension MediaLibraryViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let document = documents[indexPath.row]
        delegate?.mediaLibraryViewController(self, didSelect: document.url.lastPathComponent, isVideo: document.isVideo)
    }
}

extension MediaLibraryViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
}
