//
//  VideoPlayerLayerView.swift
//  Powerplay
//
//  Created by Deepak Goyal on 04/08/23.
//

import UIKit
import AVKit

protocol VideoPlayerViewDelegate: AnyObject{
    
    
    /// Get called after every 1 second when video is playing and also played duration changes in any way.
    /// - Parameters:
    ///   - time: Video played  duration
    ///   - duration: Total duration of video
    func didChangePlayedDuration(withTime time: Double, ofDuration duration: Double)
    
    
    /// Video will started playing
    /// - Parameter time: Total duration of video
    func didReadyToPlay(ofDuration time: Double)
    
    /// Video playing failed due to any reason eg. Invalid URL
    func didFailedPlaying()
    
    /// Just Initiated player with url
    func didLoadPlayer()
    
    /// Tiggers when player is paused
    func didPaused()
    
    /// Triggers when played is played
    func didPlayed()
}

class VideoPlayerLayerView: UIView{
    
    override class var layerClass: AnyClass{
        return AVPlayerLayer.self
    }
    
    private var playerLayer: AVPlayerLayer?{
        return layer as? AVPlayerLayer
    }
    
    private var player: AVPlayer? {
        get{
            return playerLayer?.player
        }
        set{
            playerLayer?.player = newValue
        }
    }
    
    var url: URL? {
        didSet{
            guard let url = url else { return }
            play(withURL: url)
        }
    }
    
    private var playerItem: AVPlayerItem?
    private var isAutoPlay = true
    weak var delegate: VideoPlayerViewDelegate?
    
    init(withURL url: URL? = nil, isAutoPlay: Bool = true){
        self.url = url
        self.isAutoPlay = isAutoPlay
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit{
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
    }
            
    private func play(withURL url: URL){

        // Removing observer for previous playerItem
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        playerItem = AVPlayerItem(url: url)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
        delegate?.didLoadPlayer()
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return }
            
            self.player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
            self.player = AVPlayer(playerItem: self.playerItem!)
            self.playerLayer?.videoGravity = .resizeAspectFill
            self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new], context: nil)
            self.player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: .main, using: { [weak self] time in
                
                guard let duration = self?.player?.currentItem?.duration.seconds,
                       !(duration.isNaN || duration.isInfinite) else {
                    return
                }
                self?.delegate?.didChangePlayedDuration(withTime: time.seconds, ofDuration: duration)
            })
        }
        
    }
    
    /// Seconds you need to go forward or backward in played duration
    /// - Parameter seconds: Seconds (Negative - to go back) & (Positive - to go forward)
    func seek(_ seconds: Double){
        
        guard let currentTime = player?.currentTime() else { return }
        let seekToSeconds = CMTimeGetSeconds(currentTime).advanced(by: seconds)
        playerItem?.seek(to: CMTime(value: CMTimeValue(seekToSeconds), timescale: 1), completionHandler: { [weak self] _ in
            
            let totalDuration = self?.player?.currentItem?.duration.seconds ?? 0
            self?.delegate?.didChangePlayedDuration(withTime: seekToSeconds, ofDuration: totalDuration)
        })
    }
    
    /// Used for seeking to particular ratio of total video duration
    /// - Parameter ratio: (Played Duration / Total Duration)
    func seek(toRatio ratio: Float){
        let secondsToSeek = (self.player?.currentItem?.duration.seconds ?? 0) * Double(ratio)
        let currentTime = player?.currentTime().seconds ?? 0
        seek(secondsToSeek - currentTime)
    }
    
    func play(){
        player?.play()
    }
    
    func pause(){
        player?.pause()
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue) ?? .unknown
            } else {
                status = .unknown
            }
            
            switch status {
            case .readyToPlay:
                self.delegate?.didReadyToPlay(ofDuration: player?.currentItem?.duration.seconds ?? 0)
                if isAutoPlay{
                    player?.play()
                }
                break
            case .failed:
                self.delegate?.didFailedPlaying()
                debugPrint("Failed to play")
            default:
                self.delegate?.didFailedPlaying()
                debugPrint("Something went wrong while playing video")
                break
            }
        }
        else if keyPath == #keyPath(AVPlayer.timeControlStatus){
            let statusNumber = change?[.newKey] as? NSNumber ?? 1
            let status = AVPlayer.TimeControlStatus(rawValue: statusNumber.intValue)
            
            switch status{
            case .paused:
                delegate?.didPaused()
                break
            case .playing:
                delegate?.didPlayed()
                break
            default:
                break
            }
        }
    }
    
}
