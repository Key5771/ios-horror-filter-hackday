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
        layoutOfContainerView()
    }
    
    private func layoutOfContainerView() {
        let width = self.view.frame.width
        let height = self.view.frame.height

        if width < height {     // portrait mode
            let newHeight = width / 16 * 9
            self.containerView.snp.remakeConstraints { make in
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                make.height.equalTo(newHeight)
                make.centerY.equalToSuperview()
            }
        } else {                // landscape mode
            let newWidth = height / 9 * 16
            self.containerView.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(newWidth)
                make.centerX.equalToSuperview()
            }
        }
        
        self.view.layoutIfNeeded()
        playerLayer.frame = containerView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()   // view가 나타날때 player 재생
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.layoutOfContainerView()
        }, completion: nil)
    }
}
