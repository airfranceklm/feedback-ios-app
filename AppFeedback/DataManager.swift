//
//  DataManager.swift
//  AFKLFeedback
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import BleMesh

class DataManager : NSObject, BleManagerDelegate {
    
    static let shared = DataManager()
    
    private(set) var projects: [XProject]!
    private var docUrl: URL
    private var contentsUrl: URL
    private var projectsUrl: URL
    private var nextId: UInt = 1
    private let queue : DispatchQueue = DispatchQueue(label: "com.airfrance.mobile.inhouse.AFKLFeedbackQueue")
    
    // BLE working vars
    var sessionId: UInt64 = 7331
    var terminalId: BleTerminalId = UInt64(UUID().hashValue)
    var bleItems: [BleItem] = []
    var nextItemIndex: BleItemIndex = 0
    var itemDatas = [UInt32: Data]()
    var messages = [UInt64: [UInt32: XSharableFeedback]]()
    
    private override init() {
        self.docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.contentsUrl = docUrl.appendingPathComponent("contents", isDirectory: true)
        let supportDirUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        self.projectsUrl = supportDirUrl.appendingPathComponent("projects.json", isDirectory: false)
        try? FileManager.default.createDirectory(at: supportDirUrl, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(at: contentsUrl, withIntermediateDirectories: true, attributes: nil)
        
        super.init()
        
        BleManager.shared.delegate = self
        BleManager.shared.start(session: sessionId, terminal: terminalId)
        
        readProjects()
    }
    
    private func readProjects() {
        queue.sync {
            guard let json = try? Data(contentsOf: projectsUrl), let savedProjects = try? JSONDecoder().decode([XProject].self, from: json) else {
                projects = []
                return
            }
            for project in savedProjects {
                if project.id >= nextId {
                    nextId = project.id + 1
                }
            }
            projects = savedProjects
        }
    }
    
    private func saveProjects() throws {
        try saveProjects(url: projectsUrl, prettyPrinted: false)
    }
    
    private func saveProjects(url: URL, prettyPrinted: Bool) throws {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = .prettyPrinted
        }
        let json = try encoder.encode(projects)
        try json.write(to: url)
    }
    
    func addProject(name: String, description: String, path: String, isVideo: Bool) {
        queue.sync {
            let moods: [Mood: UInt] = [.happy: 0, .neutral: 0, .sad: 0]
            let project = XProject(id: nextId, name: name, desc: description, content: path, type: (isVideo ? .movie : .image), moods: moods, feedbacks: [])
            nextId += 1
            projects.append(project)
            do {
                try saveProjects()
            } catch {
                projects.removeLast()
                print("ERROR - Failed to save new project - \(error)")
            }
        }
    }
    
    func update(projectId: UInt, name: String, description: String, path: String, isVideo: Bool) {
        queue.sync {
            guard let index = projects.firstIndex(where: {$0.id == projectId}) else {
                print("ERROR - Failed to update project - Not found")
                return
            }
            let oldProject = projects[index]
            let newProject = XProject(id: projectId, name: name, desc: description, content: path, type: (isVideo ? .movie : .image), moods: oldProject.moods, feedbacks: oldProject.feedbacks)
            projects[index] = newProject
            do {
                try saveProjects()
            } catch {
                projects[index] = oldProject
                print("ERROR - Failed to update project - \(error)")
            }
        }
    }
    
    func addFeedback(projectId: UInt, comment: String, mood: Mood, share: Bool = true) {
        queue.sync {
            guard let index = projects.firstIndex(where: {$0.id == projectId}) else {
                print("ERROR - Failed to add feedback - Project not found")
                return
            }
            let oldProject = projects[index]
            let feedback = XFeedback(date: Date(), mood: mood, comment: comment)
            var moods = oldProject.moods
            moods[mood] = (oldProject.moods[mood] ?? 0) + 1
            var feedbacks = oldProject.feedbacks
            feedbacks.append(feedback)
            let newProject = XProject(id: projectId, name: oldProject.name, desc: oldProject.desc, content: oldProject.content, type: oldProject.type, moods: moods, feedbacks: feedbacks)
            projects[index] = newProject
            do {
                try saveProjects()
                if share {
                    shareFeedback(projectName: newProject.name, comment: comment, mood: mood)
                }
            } catch {
                projects[index] = oldProject
                print("ERROR - Failed to add feedback - \(error)")
            }
        }
    }
    
    private func shareFeedback(projectName: String, comment: String, mood: Mood) {
        print("DataManager->shareFeedback()")
        
        let encoder = JSONEncoder()
        let sharableFeedback = XSharableFeedback(projectName: projectName, mood: mood, comment: comment)
        
        guard let itemData = try? encoder.encode(sharableFeedback) else {
            print("ERROR: Enable to encode feedback in JSON format.")
            return
        }
        let headerData = "Broadcast".data(using: .utf8) ?? Data()
        let item = BleItem(terminalId: terminalId, itemIndex: nextItemIndex, previousIndexes: nil, size: UInt32(itemData.count), headerData: headerData)
        
        itemDatas[nextItemIndex] = itemData
        nextItemIndex = nextItemIndex + 1
        
        BleManager.shared.broadcast(item: item)
    }
    
    func delete(project: XProject) {
        queue.sync {
            guard let index = projects.firstIndex(where: {$0.id == project.id}) else {
                print("ERROR - Failed to delete project - Not found")
                return
            }
            let oldProject = projects.remove(at: index)
            do {
                try saveProjects()
            } catch {
                projects[index] = oldProject
                print("ERROR - Failed to delete project - \(error)")
            }
        }
    }
    
    func deleteFeedbacks(project: XProject) {
        queue.sync {
            guard let index = projects.firstIndex(where: {$0.id == project.id}) else {
                print("ERROR - Failed to delete project - Not found")
                return
            }
            let moods: [Mood: UInt] = [.happy: 0, .neutral: 0, .sad: 0]
            let oldProject = projects[index]
            let newProject = XProject(id: project.id, name: oldProject.name, desc: oldProject.desc, content: oldProject.content, type: oldProject.type, moods: moods, feedbacks: [])
            projects[index] = newProject
            do {
                try saveProjects()
            } catch {
                projects[index] = oldProject
                print("ERROR - Failed to delete project feedbacks - \(error)")
            }
        }
    }
    
    func deleteAll() {
        queue.sync {
            let oldProjects = projects
            projects = []
            do {
                try saveProjects()
            } catch {
                projects = oldProjects
                print("ERROR - Failed to delete all projects - \(error)")
            }
        }
    }
    
    func deleteAllFeedbacks() {
        queue.sync {
            let oldProjects = projects!
            let moods: [Mood: UInt] = [.happy: 0, .neutral: 0, .sad: 0]
            projects = []
            for project in oldProjects {
                projects.append(XProject(id: project.id, name: project.name, desc: project.desc, content: project.content, type: project.type, moods: moods, feedbacks: []))
            }
            do {
                try saveProjects()
            } catch {
                projects = oldProjects
                print("ERROR - Failed to delete all feedbacks - \(error)")
            }
        }
    }
    
    func mediaDocuments() -> [(url: URL, isVideo: Bool)] {
        var result = [(URL, Bool)]()
        let contents = (try? FileManager.default.contentsOfDirectory(at: contentsUrl, includingPropertiesForKeys: nil, options: [])) ?? []
        for content in contents {
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, content.pathExtension as CFString, nil)
            if UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeMovie) {
                result.append((content, true))
            } else if UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeImage) {
                result.append((content, false))
            }
        }
        return result
    }
    
    func videoUrl(path: String) -> URL {
        return contentsUrl.appendingPathComponent(path, isDirectory: false)
    }
    
    func image(atPath path: String) -> UIImage? {
        return image(at: contentsUrl.appendingPathComponent(path, isDirectory: false))
    }
    
    func image(at url: URL) -> UIImage? {
        guard let imageData = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    func stillImageForMovie(atPath path: String) -> UIImage? {
        return stillImageForMovie(at: contentsUrl.appendingPathComponent(path, isDirectory: false))
    }
    
    func stillImageForMovie(at url: URL) -> UIImage? {
        let dirUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("stillimages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
        let stillImageUrl = dirUrl.appendingPathComponent(url.lastPathComponent, isDirectory: false)
        if !FileManager.default.fileExists(atPath: stillImageUrl.path) {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            //generator.maximumSize = CGSize(width,height)
            do {
                let cgImage = try generator.copyCGImage(at: CMTimeMakeWithSeconds(1.0, preferredTimescale: 600), actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                if let data = image.pngData() {
                    try data.write(to: stillImageUrl)
                }
            } catch {
                print("ERROR - Failed to generate still image - \(error)")
                return nil
            }
        }
        if let data = try? Data(contentsOf: stillImageUrl), let image = UIImage(data: data) {
            return image
        }
        return nil
    }
    
    func export(all: Bool = true) -> Bool {
        let dirUrl = docUrl.appendingPathComponent("export", isDirectory: true)
        try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        let fileName = "AFKLFeedbacks_\(formatter.string(from: Date())).json"
        do {
            try saveProjects(url: dirUrl.appendingPathComponent(fileName, isDirectory: false), prettyPrinted: true)
            return true
        } catch {
            print("ERROR - Failed to export - \(error)")
            return false
        }
    }

    // MARK: BleManagerDelegate
    
    func bleManagerItemSliceFor(terminalId: BleTerminalId, index: BleItemIndex, offset: UInt32, length: UInt32) -> Data? {
        print("BleManagerDelegate->bleManagerItemSliceFor(terminalId:\(terminalId), index:\(index), offset:\(offset), length:\(length))")
        guard let itemData = itemDatas[index] else {
            print("ERROR: item data is nil for index:\(index)")
            return nil
        }
        guard offset < itemData.count else {
            print("ERROR: offset:(\(offset)) < itemData.count:(\(itemData.count))")
            return nil
        }
        return itemData[offset..<min(UInt32(itemData.count), UInt32(offset + length))]
    }
    
    func bleManagerDidReceive(item: BleItem, data: Data) {
        print("BleManagerDelegate->bleManagerDidReceive()")
        // get the XSharableFeedback from the BLE.
        let decoder = JSONDecoder()
        guard let message = try? decoder.decode(XSharableFeedback.self, from: data) else {
            print("ERROR, Malformed BLE message.")
            return
        }
        // save the message.
        var messagesFromTerminal = messages[item.terminalId]
        if messagesFromTerminal == nil {
            messagesFromTerminal = [UInt32: XSharableFeedback]()
            self.messages[item.terminalId] = messagesFromTerminal
        }
        self.messages[item.terminalId]?[item.itemIndex] = message
        // get the associated project.
        guard let index = projects.firstIndex(where: {$0.name == message.projectName}) else {
            print("ERROR - Failed to add feedback - Project not found")
            return
        }
        // add the feedback to the project.
        addFeedback(projectId: projects[index].id, comment: message.comment, mood: message.mood, share: false)
    }
}
