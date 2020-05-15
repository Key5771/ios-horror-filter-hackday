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
    
    let dummyArr: [VideoInfo] = VideoInfo.makeDummyData()
    
    // api를 통해 받아온 데이터를 저장하는 배열
    var infoArr: [Clip] = []
    var hasNext: Bool = true
    var page: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        
        let nibName = UINib(nibName: "VideoCollectionViewCell", bundle: nil)
        collectionView.register(nibName, forCellWithReuseIdentifier: "VideoCollectionViewCell")
        
        
        // TODO: - hasNext == true인 경우 구현해야 함. cell이 마지막까지 스크롤 됐을 때 실행할 예정.
        NetworkRequest.shared.requestVideoInfo(api: .videoInfo, method: .get) { (response) in
            // 현재 infoArr에 저장되는 부분이 늦게 실행되기 때문에 reloadData()를 해주어야 셀에서 표현가능
            if let next = response.hasNext {
                self.hasNext = next
            }
            guard let data = response.clips else { return }
            self.infoArr = data
            self.collectionView.reloadData()
        }
    }
    
    // 화면 회전 시 cell size가 업데이트되지 않는 현상 방지
    override func viewWillLayoutSubviews() {
        collectionView.reloadData()
    }
    
    // 파일의 이름과 확장자를 .으로 분리.
    // index 0에는 파일의 이름을 index 1에는 파일의 확장자를 저장하여 배열로 리턴.
    func getURL(_ str: String) -> [String] {
        return str.components(separatedBy: ".")
    }
}

extension MainViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    // prefetch함수를 이용해 hasNext가 true이면 다음 페이지의 데이터를 요청.
    // TODO: - 미리 불러올 수 있도록 인덱스 설정을 해주어야 할 듯.
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if hasNext == true {
            page += 1
            let params: Parameters = ["page":String(page)]
            NetworkRequest.shared
                .requestVideoInfo(api: .videoInfo, method: .get, parameters: params, encoding: URLEncoding.queryString) { (response) in
                    if let has = response.hasNext {
                        self.hasNext = has
                    }
                    guard let data = response.clips else { return }
                    self.infoArr.append(contentsOf: data)
                    self.collectionView.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return infoArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath) as? VideoCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let infoData = infoArr[indexPath.row]
        
        // thumbnailUrl을 호출할 때, ?type=f480을 호출하기 위한 변수
        if let thumbnailUrl = infoData.thumbnailUrl {
//            print("thumbnailUrl: \(thumbnailUrl)")
            cell.thumbnailImageView.sd_setImage(with: URL(string: thumbnailUrl + "?type=f480"))
        }
        
        // channelEmblemUrl을 호출할 때, ?type=f200을 호출하기 위한 변수
//        let channelEmblemUrl = infoArr[indexPath.row].channelEmblemUrl + "?type=f200"
        
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
                cell.videoLengthLabel.text = formatter.string(from: date)
            }
        }
        
        return cell
    }
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 2 - 5.0
        return CGSize(width: width, height: width * 0.75)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let infoData = dummyArr[indexPath.row]
        let videoName = getURL(infoData.videoName)
        if let videoURL = Bundle.main.url(forResource: videoName[0], withExtension: videoName[1]) {
            // 블러처리 해주는 기초적인 클래스 구현 - 현재는 한 구간만 블러 가능
            let filteredItem = FilteredPlayerItem(videoURL: videoURL)
            
            // 블러 시작구간을 start, 끝구간을 end로 설정
            guard let start = Double(infoData.start),
                let end = Double(infoData.end) else { return }
            
            filteredItem.blur(from: start, to: end, animationRate: 1.0)
            let player = AVPlayer(playerItem: filteredItem.playerItem)
            
            let controller = AVPlayerViewController()
            controller.player = player

            present(controller, animated: true) {
                player.play()
            }
        }
    }
}

