//
//  VideoViewController.swift
//  FearlessVideoFilter
//
//  Created by 박정민 on 2020/05/11.
//  Copyright © 2020 Hackday2020. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import SnapKit

class VideoViewController: UIViewController {

    var playerItem: AVPlayerItem?
    @IBOutlet weak var containerView: UIView!
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        
        // containerView에 playerLayer를 추가하여 동영상을 표시
        containerView.layer.addSublayer(playerLayer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()   // view가 나타날때 player 재생
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        var width = self.view.frame.width
        var height = self.view.frame.height
        
        if width < height {     // portrait mode
            height = width / 16 * 9
        } else {                // landscape mode
            width = height / 9 * 16
        }
        
        containerView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(width)
            make.height.equalTo(height)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = containerView.bounds
    }
}
