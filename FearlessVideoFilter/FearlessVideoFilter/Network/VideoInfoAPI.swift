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
    // videoInfo와 filterInfo에서 같은 함수를 사용할 수 있도록 변경.
    func requestVideoInfo<Response: Decodable>(api: API, method: Alamofire.HTTPMethod, parameters: Parameters? = nil, encoding: URLEncoding? = nil, completion handler: @escaping (Response) -> Void) {
        let queue = DispatchQueue(label: "background", qos: .background, attributes: .concurrent)
        
        // responseDecodable
        AF.request(baseUrl+api.rawValue, method: .get, parameters: parameters).responseDecodable(of: Response.self, queue: queue) { (response) in
            switch response.result {
            case .success(let object):
                handler(object)
            case .failure(let error):
                print("Failure Error: \(error)")
            }
        }
    }
}
