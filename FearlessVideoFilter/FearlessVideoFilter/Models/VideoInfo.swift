//
//  VideoInfo.swift
//  FearlessVideoFilter
//
//  Created by 박정민 on 2020/05/07.
//  Copyright © 2020 Hackday2020. All rights reserved.
//

import Foundation

class VideoInfo: Decodable {
    var thumbnailName: String
    var videoName: String
    var title: String
    var videoLength: String
    
    init(thumbnailName: String, videoName: String, title: String, videoLength: String) {
        self.thumbnailName = thumbnailName
        self.videoName = videoName
        self.title = title
        self.videoLength = videoLength
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
