//
//  Model.swift
//  AFKLFeedback
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import Foundation

enum Mood: String, Codable {
    case happy, neutral, sad
}

enum ContentType: String, Codable {
    case image, movie
}

struct XFeedback: Codable {
    let date: Date
    let mood: Mood
    let comment: String
}

struct XProject: Codable {
    let id: UInt
    let name: String
    let desc: String
    let content: String
    let type: ContentType
    let moods: [Mood: UInt]
    let feedbacks: [XFeedback]
}
