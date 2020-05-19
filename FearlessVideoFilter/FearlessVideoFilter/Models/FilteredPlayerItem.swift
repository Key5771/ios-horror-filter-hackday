//
//  FilteredPlayerItem.swift
//  FearlessVideoFilter
//
//  Created by 박정민 on 2020/05/07.
//  Copyright © 2020 Hackday2020. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit

class FilteredPlayerItem: NSObject {
    var videoURL: URL
    private var asset: AVAsset
    private(set) var playerItem: AVPlayerItem
    
    // 임의로 지정한 blur의 강도
    let blurIntensity = 10.0
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        self.asset = AVAsset(url: videoURL)
        self.playerItem = AVPlayerItem(asset: self.asset)
    }
    
    convenience init(videoURL: URL, filterArray: [Filter], animationRate: Double) {
        self.init(videoURL: videoURL)
        self.blur(filterArray: filterArray, animationRate: animationRate)
    }
    
    func blur(filterArray: [Filter], animationRate: Double) {
        if filterArray.isEmpty { return }
        
        let blurParam = blurIntensity / animationRate
        
        let filter = CIFilter(name: "CIGaussianBlur")!
        let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            // 이미지 가장자리는 블러되지 않도록 처리
            let source = request.sourceImage.clampedToExtent()
            filter.setValue(source, forKey: kCIInputImageKey)
            
            // 비디오 타이밍에 따라 필터 파라미터가 달라짐
            let seconds = CMTimeGetSeconds(request.compositionTime)
            if let (start, end) = self.filteringSection(at: seconds, of: filterArray) {
                if seconds < start + animationRate {
                    filter.setValue((seconds-start) * blurParam, forKey: kCIInputRadiusKey)
                } else if seconds < end - animationRate {
                    filter.setValue(self.blurIntensity, forKey: kCIInputRadiusKey)
                } else if seconds < end {
                    filter.setValue((end - seconds) * blurParam, forKey: kCIInputRadiusKey)
                }
            } else {
                filter.setValue(0, forKey: kCIInputRadiusKey)
            }
                    
            // 원본 이미지 크기만큼 블러처리 된 부분을 잘라냄
            let output = filter.outputImage!.cropped(to: request.sourceImage.extent)
            
            // Provide the filter output to the composition
            request.finish(with: output, context: nil)
        })
        
        self.playerItem.videoComposition = composition
    }
    
    private func filteringSection(at seconds: Double, of filterArray: [Filter]) -> (Double, Double)? {
        for item in filterArray {
            guard let start = item.startPosition,
                let end = item.endPosition else { return nil }
            if seconds > Double(start) && seconds < Double(end) {
                return (Double(start), Double(end))
            }
        }
        return nil
    }
}
