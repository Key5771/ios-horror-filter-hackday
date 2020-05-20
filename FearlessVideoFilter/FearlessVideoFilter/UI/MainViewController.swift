//
//  ViewController.swift
//  FearlessVideoFilter
//
//  Created by 박정민 on 2020/05/06.
//  Copyright © 2020 Hackday2020. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Alamofire
import SDWebImage

class MainViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let dummyArr: [VideoInfo] = VideoInfo.makeDummyData()
    
    // api를 통해 받아온 데이터를 저장하는 배열
    private var infoArr: [Clip] = []
    private var hasNext: Bool = true
    private var page: Int = 1
    
    
    // Response Header에 넘어오는 code 값에 따라 success, failure 분리.
    enum ResponseCode: Int {
        case success = 0
        case failure = -1000
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        
        let nibName = UINib(nibName: "VideoCollectionViewCell", bundle: nil)
        collectionView.register(nibName, forCellWithReuseIdentifier: "VideoCollectionViewCell")
        
        NetworkRequest.shared.requestVideoInfo(api: .videoInfo, method: .get) { (response: APIStruct) in
            guard let code = response.header.code else { return }
            let body = response.body
            if code == ResponseCode.success.rawValue {
                if let next = body.hasNext {
                    self.hasNext = next
                }
                if let data = body.clips {
                    self.infoArr = data
                }
                self.collectionView.reloadData()
            } else if code == ResponseCode.failure.rawValue {
                print("Response Failure: code \(code)")
            }
            
        }
    }
    
    // 화면 회전 시 cell size가 업데이트되지 않는 현상 방지
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.reloadData()
    }
    
    // 파일의 이름과 확장자를 .으로 분리.
    // index 0에는 파일의 이름을 index 1에는 파일의 확장자를 저장하여 배열로 리턴.
    private func getURL(_ str: String) -> [String] {
        return str.components(separatedBy: ".")
    }
}

extension MainViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    // prefetch함수를 이용해 hasNext가 true이면 다음 페이지의 데이터를 요청.
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        dataLoad(indexPaths: indexPaths)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return infoArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath) as? VideoCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let infoData = infoArr[indexPath.item]
        
        // thumbnailUrl을 호출할 때, ?type=f480을 호출하기 위한 변수
        if let thumbnailUrl = infoData.thumbnailUrl {
            cell.thumbnailImageView.sd_setImage(with: URL(string: thumbnailUrl + "?type=f480"))
        }
        
        // channelEmblemUrl을 호출할 때, ?type=f200을 호출하기 위한 변수
        if let channelEmblemUrl = infoData.channelEmblemUrl {
            cell.channelEmblemImageView.sd_setImage(with: URL(string: channelEmblemUrl + "?type=f200"))
        }
        
        cell.titleLabel.text = infoData.title
        
        if let duration = infoData.duration {
            let minute: Int = duration / 60
            let seconds: Int = duration % 60
            
            // 초 단위로 이루어진 duration을 시, 분, 초 단위로 분리.
            var component = DateComponents()
            component.setValue(minute, for: .minute)
            component.setValue(seconds, for: .second)
            if let date = Calendar.current.date(from: component) {
                let formatter = DateFormatter()
                if minute > 60 {
                    formatter.dateFormat = "HH:mm:ss"
                } else {
                    formatter.dateFormat = "mm:ss"
                }
                if let channelName = infoData.channelName {
                    cell.videoLengthLabel.text = channelName + " • " + formatter.string(from: date)
                }
            }
        }
        
        return cell
    }
    
    // cellForItem 함수와 prefetch 함수에서 호출할 수 있도록 함수로 분리
    private func dataLoad(indexPaths: [IndexPath]) {
        guard let lastIndex = indexPaths.last?.item, lastIndex > infoArr.count - 4, hasNext == true else { return }
        page += 1
        let params: Parameters = ["page": String(page)]
        NetworkRequest.shared.requestVideoInfo(api: .videoInfo, method: .get, parameters: params, encoding: URLEncoding.queryString) { (response: APIStruct) in
                guard let code = response.header.code else { return }
                if code == ResponseCode.success.rawValue {
                    if let next = response.body.hasNext {
                        self.hasNext = next
                    }
                    if let data = response.body.clips {
                        self.infoArr.append(contentsOf: data)
                    }
                    self.collectionView.reloadData()
                } else if code == ResponseCode.failure.rawValue {
                    print("Response Failure: code \(code)")
                }
        }
    }
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width - 10
        let height = width * 9 / 16 + 55.5
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let clipno = infoArr[indexPath.item].clipNo else { return }
        let params: Parameters = ["clipNo": String(clipno)]
        NetworkRequest.shared.requestVideoInfo(api: .filterInfo, method: .get, parameters: params, encoding: URLEncoding.queryString) { (response: FilterAPI) in
            guard let code = response.header.code else { return }
            
            if code == ResponseCode.success.rawValue {
                let videoIndex = indexPath.row % self.dummyArr.count
                let videoName = self.getURL(self.dummyArr[videoIndex].videoName)
                guard let filters = response.body.filters,
                    let videoURL = Bundle.main.url(forResource: videoName[0], withExtension: videoName[1]),
                    let controller = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "VideoViewController") as? VideoViewController else { return }
                
                let filteredItem = FilteredPlayerItem(videoURL: videoURL, filterArray: filters, animationRate: 1.0)
                controller.playerItem = filteredItem.playerItem
                self.navigationController?.pushViewController(controller, animated: false)
                
            } else if code == ResponseCode.failure.rawValue {
                print("Response Failure: code \(code)")
            }
        }
    }
}
