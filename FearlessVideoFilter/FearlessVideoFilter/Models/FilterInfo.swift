//
//  FilterInfo.swift
//  FearlessVideoFilter
//
//  Created by 김기현 on 2020/05/15.
//  Copyright © 2020 Hackday2020. All rights reserved.
//

import Foundation

// MARK: - FilterAPI
struct FilterAPI: Codable {
    let header: FilterHeader
    let body: FilterBody
}

struct FilterHeader: Codable {
    let code: Int?
    let message: String?
}

struct FilterBody: Codable {
    let filters: [Filter]?
    let clipNo: Int?
}

struct Filter: Codable {
    let filterSrl: Int?
    let startPosition: Int?
    let endPosition: Int?
}
