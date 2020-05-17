//
//  VideoInfoAPI.swift
//  FearlessVideoFilter
//
//  Created by 김기현 on 2020/05/11.
//  Copyright © 2020 Hackday2020. All rights reserved.
//

import Foundation
import Alamofire


// MARK: - REQUEST
class NetworkRequest {
    static let shared: NetworkRequest = NetworkRequest()
    let baseUrl = "http://27.96.131.40:10001/api/v1/clip"
    
    enum API: String {
        case videoInfo = "/list"
        case filterInfo = "/filter/list"
    }
    
    enum NetworkError: Error {
        case http404
    }
    
    // API 요청 함수.
    func requestVideoInfo(api: API, method: Alamofire.HTTPMethod, parameters: Parameters? = nil, encoding: URLEncoding? = nil, completion handler: @escaping (Body) -> Void) {
        // responseDecodable
        AF.request(baseUrl+api.rawValue, method: .get, parameters: parameters).responseDecodable(of: APIStruct.self) { (response) in
            // TODO: - 이부분은 API와 맞추어 성공, 실패를 나누어야 할 듯.
            switch response.result {
            case .success(let object):
                let data = object.body
                handler(data)
            case .failure(let error):
                print("Failure Error: \(error)")
            }
        }
    }
    
    // FilterAPI 요청 함수.
    func requestFilterInfo(api: API, method: Alamofire.HTTPMethod, parameters: Parameters? = nil, encoding: URLEncoding? = nil, completion handler: @escaping (FilterBody) -> Void) {
        AF.request(baseUrl+api.rawValue, method: .get, parameters: parameters).responseDecodable(of: FilterAPI.self) { (response) in
            switch response.result {
            case .success(let object):
                let data = object.body
                handler(data)
            case .failure(let error):
                print("Failure Error in FilterAPI: \(error)")
            }
        }
    }
}
