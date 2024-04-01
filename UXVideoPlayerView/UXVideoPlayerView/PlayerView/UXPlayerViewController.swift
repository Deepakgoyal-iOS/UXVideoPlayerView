//
//  UXPlayerViewController.swift
//  Powerplay
//
//  Created by Deepak Goyal on 07/08/23.
//

import UIKit

protocol UXPlayerViewControllerDelegate: AnyObject{
    
    // MARK: If URL is appropriate and video is Ready to playing / start playing
    func didReadyToPlay()
    
    // MARK: Something is wrong and video is failed to play
    func didFailToPlay()
    
    func didTapPlay()
    
    func didTapPause()
}

class UXPlayerViewController: UIViewController {
    
    
    private lazy var controlsOverLay: VideoControlsOverlayView = {
       let view = VideoControlsOverlayView()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOverlayView))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    private lazy var playerView: VideoPlayerLayerView = {
        let view = VideoPlayerLayerView(isAutoPlay: isAutoPlay)
        view.url = url
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapVideoView))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    private lazy var loader: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.hidesWhenStopped = true
        view.tintColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var url: URL?{
        didSet{
            playerView.url = url
        }
    }
    private var isAutoPlay = true
    private var pendingSeekRatio: Float?
    weak var delegate: UXPlayerViewControllerDelegate?
    private var seekFactor: Double = 10
    
    init(url: URL? = nil, isAutoPlay: Bool = true) {
        self.url = url
        self.isAutoPlay = isAutoPlay
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        addLayoutConstraints()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerView.pause()
    }
    
    private func addViews(){
        self.view.addSubview(playerView)
        self.playerView.addSubview(controlsOverLay)
        self.playerView.addSubview(loader)
        controlsOverLay.isHidden = true
    }
    
    private func addLayoutConstraints(){
        
        NSLayoutConstraint(item: controlsOverLay, attribute: .top, relatedBy: .equal, toItem: playerView, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: controlsOverLay, attribute: .bottom, relatedBy: .equal, toItem: playerView, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: controlsOverLay, attribute: .leading, relatedBy: .equal, toItem: playerView, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: controlsOverLay, attribute: .trailing, relatedBy: .equal, toItem: playerView, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        
        NSLayoutConstraint(item: playerView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .topMargin, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: playerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottomMargin, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: playerView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: playerView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0).isActive = true

        NSLayoutConstraint(item: loader, attribute: .centerX, relatedBy: .equal, toItem: playerView, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: loader, attribute: .centerY, relatedBy: .equal, toItem: playerView, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        loader.heightAnchor.constraint(equalToConstant: 100).isActive = true
        loader.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
    }
    
    /// Seconds you need to seek forward and backward
    /// - Parameter seconds: Eg if X then, on forward and backward tap video will be X seconds forward and X seconds backward
    func setSeekFactor(seconds: Double){
        self.seekFactor = seconds
    }
    
    @objc private func didTapVideoView(){
        controlsOverLay.isHidden = false
    }
    
    @objc private func didTapOverlayView(){
        controlsOverLay.isHidden = true
    }
}
extension UXPlayerViewController: VideoControlsOverlayViewDelegate{
    
    func didChangeSeek(withRatio ratio: Float) {
        
        pendingSeekRatio = ratio
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(changeSeek), object: nil)
        self.perform(#selector(changeSeek), with: nil, afterDelay: 1)
        self.loader.startAnimating()
    }
    
    func didTapForward() {
        playerView.seek(seekFactor)
    }
    
    func didTapBackward() {
        playerView.seek(-seekFactor)
    }
    
    func didTapPlay() {
        playerView.play()
        delegate?.didTapPlay()
    }
    
    func didTapPause() {
        playerView.pause()
        delegate?.didTapPause()
    }
    
    @objc private func changeSeek(){
        playerView.seek(toRatio: pendingSeekRatio ?? 0)
        loader.stopAnimating()
        pendingSeekRatio = nil
    }

}
extension UXPlayerViewController: VideoPlayerViewDelegate{
    
    func didChangePlayedDuration(withTime time: Double, ofDuration duration: Double) {
        
        guard pendingSeekRatio == nil else { return }
        controlsOverLay.set(playedDuration: time, totalDuration: duration)
    }
    
    func didReadyToPlay(ofDuration time: Double) {
        self.delegate?.didReadyToPlay()
        loader.stopAnimating()
        controlsOverLay.set(playedDuration: 0, totalDuration: time)
    }
    
    func didFailedPlaying() {
        self.delegate?.didFailToPlay()
        loader.stopAnimating()
        controlsOverLay.set(playedDuration: 0, totalDuration: 0)
    }
    
    func didLoadPlayer() {
        loader.startAnimating()
    }
    
    func didPaused() {
        controlsOverLay.pause()
    }
    
    func didPlayed() {
        controlsOverLay.play()
    }

}
