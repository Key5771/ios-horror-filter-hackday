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
    static let pauseButtonImageName = "SF_pause_circle_fill"
    static let playButtonImageName = "SF_play_circle_fill"
    
    // layout 관련 상수
    let closeButtonCornerRadius = CGFloat(10)
    let playbackControlsViewCornerRadius = CGFloat(15)
    let containerViewAspect = CGFloat(16.0 / 9.0)
    
    // time 관련 상수
    let jumpingTimeStep = 15.0
    let prefferedTimeScale = CMTimeScale(600)
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()
    
    // MARK: - Variables
//    var asset: AVAsset?
    var playerItem: AVPlayerItem?
    private var player: AVPlayer? {
        didSet {
            if let item = self.player?.currentItem {
                durationSeconds = Float(item.duration.seconds)
            }
        }
    }
    private var playerLayer: AVPlayerLayer?
    private var durationSeconds: Float = 0.0
    
    // observer 관련 변수
    private var timeObserverToken: Any?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var playerItemStepForwardObserver: NSKeyValueObservation?
    private var playerItemStepBackwardObserver: NSKeyValueObservation?
    private var playerTimeControlStatusObserver: NSKeyValueObservation?

    // MARK: - IBOutlet Propertise
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var playbackControlsView: UIView!
    @IBOutlet weak var stepBackwardButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var stepForwardButton: UIButton!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareToPlay()
        playerLayer = AVPlayerLayer(player: player)
        
        guard let playerLayer = playerLayer else { return }
        playerLayer.videoGravity = .resizeAspectFill
        
        // containerView에 playerLayer를 추가하여 동영상을 표시
        containerView.layer.addSublayer(playerLayer)
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()   // view가 나타날때 player 재생
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.updateLayoutOfContainerView()
        }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        player?.pause()
        
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Setup
    private func setupLayout() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        closeButton.layer.cornerRadius = closeButtonCornerRadius
        playbackControlsView.layer.cornerRadius = playbackControlsViewCornerRadius
        updateLayoutOfContainerView()
    }

    private func prepareToPlay() {
//        guard let asset = asset else { return }
//
//        playerItem = AVPlayerItem(asset: asset,
//                                  automaticallyLoadedAssetKeys: assetKeysRequiredToPlay)
        
        player = AVPlayer(playerItem: playerItem)
        setupPlayerObservers()
    }
    
    private func updateLayoutOfContainerView() {
        let width = self.view.frame.width
        let height = self.view.frame.height

        if width < height {     // portrait mode
            let newHeight = width / containerViewAspect
            containerView.snp.remakeConstraints { make in
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                make.height.equalTo(newHeight)
                make.centerY.equalToSuperview()
            }
        } else {                // landscape mode
            let newWidth = height * containerViewAspect
            containerView.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(newWidth)
                make.centerX.equalToSuperview()
            }
        }
        
        self.view.layoutIfNeeded()
        playerLayer?.frame = containerView.bounds
    }
    
    // MARK: - Key-Value Observing
    private func setupPlayerObservers() {
        guard let player = player else { return }
        
        playerTimeControlStatusObserver = player.observe(\AVPlayer.timeControlStatus,
                                                         options: [.initial, .new]) { [unowned self] _, _ in
            DispatchQueue.main.async {
                self.setPlayPauseButtonImage()
            }
        }
        
        let interval = CMTime(value: 1, timescale: 2)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval,
                                                           queue: .main) { [unowned self] time in
            let timeElapsed = Float(time.seconds)
            self.timeSlider.value = timeElapsed
            self.startTimeLabel.text = self.createTimeString(time: timeElapsed)
            self.remainingTimeLabel.text = self.createTimeString(time: timeElapsed - self.durationSeconds)
        }
        
        playerItemStepForwardObserver = player.observe(\AVPlayer.currentItem?.canPlayFastForward,
                                                       options: [.new, .initial]) { [unowned self] player, _ in
            DispatchQueue.main.async {
                self.stepForwardButton.isEnabled = player.currentItem?.canStepForward ?? false
            }
        }
        
        playerItemStepBackwardObserver = player.observe(\AVPlayer.currentItem?.canPlayReverse,
                                                   options: [.new, .initial]) { [unowned self] player, _ in
            DispatchQueue.main.async {
                self.stepBackwardButton.isEnabled = player.currentItem?.canStepBackward ?? false
            }
        }
        
        playerItemStatusObserver = player.observe(\AVPlayer.currentItem?.status, options: [.new, .initial]) { [unowned self] _, _ in
            DispatchQueue.main.async {
                self.updateUIforPlayerItemStatus()
            }
        }
    }
    
    // MARK: - IBActions
    @IBAction func actionCloseButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func togglePlay(_ sender: UIButton) {
        guard let player = player else { return }
        
        switch player.timeControlStatus {
        case .playing:
            player.pause()
        case .paused:
            let currentItem = player.currentItem
            if currentItem?.currentTime() == currentItem?.duration {
                currentItem?.seek(to: .zero, completionHandler: nil)
            }
            // 현재 정지 상태이므로 play 시작
            player.play()
        default:
            player.pause()
        }
    }
    
    @IBAction func stepBackward(_ sender: UIButton) {
        guard let player = player,
            let currentTime = player.currentItem?.currentTime() else { return }
        if currentTime == .zero { return }
        
        let backwardTime = CMTime(seconds: currentTime.seconds - jumpingTimeStep, preferredTimescale: prefferedTimeScale)
        player.seek(to: backwardTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    @IBAction func stepForward(_ sender: UIButton) {
        guard let player = player,
            let currentTime = player.currentItem?.currentTime() else { return }
        if currentTime == player.currentItem?.duration { return }
        let forwardTime = CMTime(seconds: currentTime.seconds + jumpingTimeStep, preferredTimescale: prefferedTimeScale)
        player.seek(to: forwardTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    @IBAction func timeSliderDidChange(_ sender: UISlider) {
        let newTime = CMTime(seconds: Double(sender.value), preferredTimescale: 600)
        player?.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    @IBAction func tapAction(_ sender: Any) {
        if playbackControlsView.isHidden == false && closeButton.isHidden == false {
            playbackControlsView.isHidden = true
            closeButton.isHidden = true
        } else {
            playbackControlsView.isHidden = false
            closeButton.isHidden = false
        }
    }
    
    // MARK: - Error Handling
    private func handleErrorWithMessage(_ message: String, error: Error? = nil) {
        if let err = error {
            print("Error occurred with message: \(message), error: \(err).")
        }
        let alertTitle = NSLocalizedString("Error", comment: "Alert title for errors")
        
        let alert = UIAlertController(title: alertTitle, message: message,
                                      preferredStyle: UIAlertController.Style.alert)
        let alertActionTitle = NSLocalizedString("OK", comment: "OK on error alert")
        let alertAction = UIAlertAction(title: alertActionTitle, style: .default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Utilities
    private func createTimeString(time: Float) -> String {
        let isNegative = time < 0 ? true : false
        var time = time
        if isNegative == true {
            time = -time
        }
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        
        guard let timeString = timeRemainingFormatter.string(from: components as DateComponents) else { return "-:--" }
        if isNegative == true {
            return "-" + timeString
        } else {
            return timeString
        }
    }
    
    private func setPlayPauseButtonImage() {
        guard let player = player else { return }
        var buttonImage: UIImage?
        
        switch player.timeControlStatus {
        case .playing:
            buttonImage = UIImage(named: VideoViewController.pauseButtonImageName)
        case .paused, .waitingToPlayAtSpecifiedRate:
            buttonImage = UIImage(named: VideoViewController.playButtonImageName)
        @unknown default:
            buttonImage = UIImage(named: VideoViewController.pauseButtonImageName)
        }
        
        guard let image = buttonImage else { return }
        let templateImage = resizedImage(at: image, for: CGSize(width: 20, height: 20))
            .withRenderingMode(.alwaysTemplate)
        playPauseButton.setImage(templateImage, for: .normal)
        playPauseButton.tintColor = UIColor.white
    }
    
    private func resizedImage(at image: UIImage, for size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func updateUIforPlayerItemStatus() {
        guard let player = player,
            let currentItem = player.currentItem else { return }
        
        switch currentItem.status {
        case .failed:
            playPauseButton.isEnabled = false
            timeSlider.isEnabled = false
            startTimeLabel.isEnabled = false
            remainingTimeLabel.isEnabled = false
            handleErrorWithMessage(currentItem.error?.localizedDescription ?? "", error: currentItem.error)
            
        case .readyToPlay:
            playPauseButton.isEnabled = true
            
            // Update the time slider control, time labels for the player duration.
            let newDurationSeconds = Float(currentItem.duration.seconds)
            
            let currentTime = Float(CMTimeGetSeconds(player.currentTime()))
            
            timeSlider.maximumValue = newDurationSeconds
            timeSlider.value = currentTime
            timeSlider.isEnabled = true
            startTimeLabel.isEnabled = true
            startTimeLabel.text = createTimeString(time: currentTime)
            remainingTimeLabel.isEnabled = true
            remainingTimeLabel.text = createTimeString(time: newDurationSeconds)
            
        default:
            playPauseButton.isEnabled = false
            timeSlider.isEnabled = false
            startTimeLabel.isEnabled = false
            remainingTimeLabel.isEnabled = false
        }
    }
}
