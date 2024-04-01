//
//  VideoControlsOverlayView.swift
//  Powerplay
//
//  Created by Deepak Goyal on 07/08/23.
//

import UIKit

protocol VideoControlsOverlayViewDelegate: AnyObject{
    
    // MARK: Forwarding 10 seconds from current position
    func didTapForward()
    
    // MARK: Back-warding 10 seconds from current position
    func didTapBackward()
    
    // MARK: Manually playing video
    func didTapPlay()
    
    // MARK: Manually pausing video
    func didTapPause()
    
    // MARK: Manually seeking through slider
    func didChangeSeek(withRatio ratio: Float)
}

class VideoControlsOverlayView: UIView {
    
    @IBOutlet weak var backwardBtnOutlet: UIButton!
    @IBOutlet weak var forwardBtnOutlet: UIButton!
    @IBOutlet weak var playPauseBtnOutlet: UIButton!
    @IBOutlet weak var startLbl: UILabel!
    @IBOutlet weak var endLbl: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    private var playedDurationSeconds: Double = 0
    private var totalDurationSeconds: Double = 0
    @IBOutlet weak var controlOptionsView: UIView!
    
    private var isPaused = false{
        didSet{
            playPauseBtnOutlet.setImage(isPaused ? UIImage(named: "pause_pdf") : UIImage(named: "play_pdf"), for: .normal)
        }
    }
    
    weak var delegate: VideoControlsOverlayViewDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fromNib()
        setUIConfigurations()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        fromNib()
        setUIConfigurations()
    }
    
    @discardableResult
    func fromNib() -> UIView?{
        
        let nibName = String(describing: Self.self)
        guard let contentView = Bundle.main.loadNibNamed(nibName, owner: self)?.first as? UIView else { return nil }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(contentView)
        return contentView
    }
    
    private func setUIConfigurations(){
        forwardBtnOutlet.setTitle("", for: .normal)
        backwardBtnOutlet.setTitle("", for: .normal)
        playPauseBtnOutlet.setTitle("", for: .normal)
        forwardBtnOutlet.tintColor = .white
        backwardBtnOutlet.tintColor = .white
        playPauseBtnOutlet.tintColor = .white
        playPauseBtnOutlet.layer.cornerRadius = playPauseBtnOutlet.bounds.width/2
        playPauseBtnOutlet.layer.masksToBounds = true
        forwardBtnOutlet.layer.cornerRadius = forwardBtnOutlet.bounds.width/2
        forwardBtnOutlet.layer.masksToBounds = true
        backwardBtnOutlet.layer.cornerRadius = backwardBtnOutlet.bounds.width/2
        backwardBtnOutlet.layer.masksToBounds = true
        isPaused = false
        timeSlider.addTarget(self, action: #selector(didChangeSlider), for: .valueChanged)
        updateLabel()
        updateSlider()
        controlOptionsView.layer.cornerRadius = 8
        controlOptionsView.layer.masksToBounds = true
    }
    
    @IBAction func backwardBtnAction(_ sender: Any) {
        delegate?.didTapBackward()
    }
    
    @IBAction func playPauseBtnAction(_ sender: Any) {
        isPaused = !isPaused
        if isPaused{
            delegate?.didTapPause()
        }
        else {
            self.delegate?.didTapPlay()
        }
    }
    
    @IBAction func forwardBtnAction(_ sender: Any) {
        delegate?.didTapForward()
    }
    
    
    /// - Parameters:
    ///   - playedDuration: Playing completed (In Seconds)
    ///   - totalDuration: Total length of video (In Seconds)
    func set(playedDuration: Double, totalDuration: Double, shouldUpdateSlider: Bool = true){
        self.playedDurationSeconds = playedDuration
        self.totalDurationSeconds = totalDuration
        updateLabel()
        updateSlider()
    }
    
    func pause(){
        isPaused = true
    }
    
    func play(){
        isPaused = false
    }
    
    private func updateLabel(){
        startLbl.text = getTime(playedDurationSeconds)
        endLbl.text = "-\(getTime(totalDurationSeconds - playedDurationSeconds))"
    }
    
    private func updateSlider(){
        
        let ratio = totalDurationSeconds == 0 ? 0.0 : Float(playedDurationSeconds/totalDurationSeconds)
        timeSlider.setValue(ratio, animated: true)
    }
    
    private func getTime(_ timeInSeconds: Double) -> String{
        let timeInSeconds = Int64(timeInSeconds)
        let hours = Int64(timeInSeconds/3600)
        let minutes = Int64((timeInSeconds - (hours*3600))/60)
        let seconds = Int64(timeInSeconds - (hours*3600) - (minutes*60))
        
        if hours != 0{
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    @objc func didChangeSlider(){
        delegate?.didChangeSeek(withRatio: timeSlider.value)
        playedDurationSeconds = Double(timeSlider.value) * totalDurationSeconds
        updateLabel()
    }
    
}

