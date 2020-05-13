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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let nibName = UINib(nibName: "VideoCollectionViewCell", bundle: nil)
        collectionView.register(nibName, forCellWithReuseIdentifier: "VideoCollectionViewCell")
        
        
        // TODO: - hasNext == true인 경우 구현해야 함. cell이 마지막까지 스크롤 됐을 때 실행할 예정.
        NetworkRequest.shared.requestVideoInfo(api: .videoInfo, method: .get) { (response) in
            // 현재 infoArr에 저장되는 부분이 늦게 실행되기 때문에 reloadData()를 해주어야 셀에서 표현가능
            self.infoArr = response.clips
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

extension MainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return infoArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath) as? VideoCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        // 기존의 dummyArr대신 infoArr을 사용하면 됩니다.
        let infoData = infoArr[indexPath.row]
        
        // thumbnailUrl을 호출할 때, ?type=f480을 호출하기 위한 변수
        let thumbnailUrl = infoArr[indexPath.row].thumbnailUrl + "?type=f480"
        print("thumbnailUrl: \(thumbnailUrl)")
        cell.thumbnailImageView.sd_setImage(with: URL(string: thumbnailUrl))
        
        // channelEmblemUrl을 호출할 때, ?type=f200을 호출하기 위한 변수
//        let channelEmblemUrl = infoArr[indexPath.row].channelEmblemUrl + "?type=f200"
        
        cell.titleLabel.text = infoData.title
        
        let duration = infoData.duration
        var minute: Int = 0
        var seconds: Int = 0
        
        // 초 단위로 이루어진 duration을 분, 초 단위로 분리.
        if duration > 60 {
            minute = duration / 60
            seconds = duration % 60
            if seconds < 10 {
                cell.videoLengthLabel.text = "\(String(minute)):\(0)\(String(seconds))"
            } else {
                cell.videoLengthLabel.text = "\(String(minute)):\(String(seconds))"
            }
        } else {
            seconds = duration
            if seconds < 10 {
                cell.videoLengthLabel.text = "\(0):\(0)\(String(seconds))"
            } else {
                cell.videoLengthLabel.text = "\(0):\(String(seconds))"
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

