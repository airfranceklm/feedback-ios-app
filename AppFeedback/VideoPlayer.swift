//
//  VideoPlayer.swift
//  AFKLFeedback
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPlayer {
    private(set) static var size = CGSize.zero
    private static var _players: [VideoPlayer]?
    
    static func prepare(frame: CGRect) {
        var players = [VideoPlayer]()
        for _ in 1...5 {
            players.append(VideoPlayer(frame: frame))
        }
        _players = players
        size = frame.size
    }
    
    static func at(_ index: Int) -> VideoPlayer? {
        guard let players = _players, players.count > index else {
            return nil
        }
        return players[index]
    }
    
    private let player: AVPlayer
    private let playerLayer: AVPlayerLayer
    
    private init(frame: CGRect) {
        player = AVPlayer(playerItem: nil)
        player.isMuted = true
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = frame
        player.actionAtItemEnd = .none
    }
    
    deinit {
        detach()
    }
    
    func attach(view: UIView, videoUrl: URL) {
        player.replaceCurrentItem(with: AVPlayerItem(url: videoUrl))
        view.layer.insertSublayer(playerLayer, at: 1)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayer.playbackFinished), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        player.play()
    }
    
    func detach() {
        player.pause()
        playerLayer.removeFromSuperlayer()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func playbackFinished() {
        player.seek(to: CMTime.zero)
        player.play()
    }
}

