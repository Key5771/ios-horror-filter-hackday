//
//  VideoInfo.swift
//  FearlessVideoFilter
//
//  Created by 박정민 on 2020/05/07.
//  Copyright © 2020 Hackday2020. All rights reserved.
//

import Foundation

// MARK: - ListAPI
struct APIStruct: Codable {
    let header: Header
    let body: Body
}

struct Header: Codable {
    let code: Int?
    let message: String?
}

struct Body: Codable {
    let clips: [Clip]?
    let hasNext: Bool?
}

struct Clip: Codable {
    let clipNo: Int?
    let title: String?
    let thumbnailUrl: String?
    let channelEmblemUrl: String?
    let channelName: String?
    let duration: Int?
}


// MARK: - JSON Data
class VideoInfo: Decodable {
    var videoName: String
    
    init(videoName: String) {
        self.videoName = videoName
    }
    
    static func makeDummyData() -> [VideoInfo] {
        let dummyData: [VideoInfo] = load("VideoInfoData.json")
        return dummyData
    }
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
