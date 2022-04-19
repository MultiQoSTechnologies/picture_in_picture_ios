//
//  ViewController.swift
//
//  Created by MQI-1 on 18/04/22.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    
    //MARK: - Property
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var sliderProgress: UISlider!
    @IBOutlet weak var videoPlayerController: UIView!
    @IBOutlet weak var btnPlayPause: UIButton!
    
    //MARK: - Variable
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var pipController: AVPictureInPictureController!
    var pipPossibleObservation: NSKeyValueObservation?
    var timer: Timer?
    var timeObserver: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
        view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerPlay), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setupVideoPlayer()
    }
    
    //player frame update
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.layoutIfNeeded()
        playerLayer?.frame = self.view.bounds
    }
    
    //MARK: - Function
    
    // set video player
    func setupVideoPlayer() {
        guard let url = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else {
            return
        }
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoPlayerView.bounds
        
        guard let `playerLayer` = playerLayer else { return }
        videoPlayerView.layer.insertSublayer(playerLayer, at: 0)
        
        // set timer to update slider progress
        let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { elapsedTime in
            self.updateVideoPlayerSlider()
        })
        
        self.setupPictureInPicture()
    }
    
    //Set PiP controller
    func setupPictureInPicture() {
        // Ensure PiP is supported by current device.
        if AVPictureInPictureController.isPictureInPictureSupported() {
            // Create a new controller, passing the reference to the AVPlayerLayer.
            pipController = AVPictureInPictureController(playerLayer: playerLayer!)
            pipController.delegate = self
            
            pipPossibleObservation = pipController.observe(\AVPictureInPictureController.isPictureInPicturePossible,
                                                            options: [.initial, .new]) { [weak self] _, change in
                self?.player?.play()
                self?.updateVideoPlayerState()
                self?.resetTimer()
                self?.playerPlay()
            }
        }
    }
    
    // Update video total time
    func updateVideoPlayerState() {
        guard let currentTime = player?.currentTime() else { return }
        let currentTimeInSeconds = CMTimeGetSeconds(currentTime)
        sliderProgress.value = Float(currentTimeInSeconds)
        if let currentItem = player?.currentItem {
            let duration = currentItem.duration
            if (CMTIME_IS_INVALID(duration)) {
                return
            }
            let currentTime = currentItem.currentTime()
            sliderProgress.value = Float(CMTimeGetSeconds(currentTime) / CMTimeGetSeconds(duration))
            
            // Update time remaining label
            let totalTimeInSeconds = CMTimeGetSeconds(duration)
            let remainingTimeInSeconds = totalTimeInSeconds - currentTimeInSeconds
            
            let mins = remainingTimeInSeconds / 60
            let secs = remainingTimeInSeconds.truncatingRemainder(dividingBy: 60)
            let timeformatter = NumberFormatter()
            timeformatter.minimumIntegerDigits = 2
            timeformatter.minimumFractionDigits = 0
            timeformatter.roundingMode = .down
            guard let minsStr = timeformatter.string(from: NSNumber(value: mins)), let secsStr = timeformatter.string(from: NSNumber(value: secs)) else {
                return
            }
            lblTime.text = "\(minsStr):\(secsStr)"
        }
    }
    
    
    // Update slider progress
    func updateVideoPlayerSlider() {
        guard let currentTime = player?.currentTime() else { return }
        let currentTimeInSeconds = CMTimeGetSeconds(currentTime)
        sliderProgress.value = Float(currentTimeInSeconds)
        if let currentItem = player?.currentItem {
            let duration = currentItem.duration
            if (CMTIME_IS_INVALID(duration)) {
                return
            }
            let currentTime = currentItem.currentTime()
            sliderProgress.value = Float(CMTimeGetSeconds(currentTime) / CMTimeGetSeconds(duration))
            self.updateVideoPlayerState()
        }
    }
    
    // Progress and play button view hide after 10 seconds
    func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
    }
    
    //MARK: - Action
    
    @objc func toggleControls() {
        videoPlayerController.isHidden = false
        resetTimer()
    }
    
    @objc func hideControls() {
        videoPlayerController.isHidden = true
    }
    
    // button play and pause
    @objc func playerPlay() {
        guard let player = self.player else { return }
        if player.isPlaying {
            btnPlayPause.isSelected = true
            player.play()
        } else {
            btnPlayPause.isSelected = false
            player.pause()
        }
    }
    
    @IBAction func btnPlay(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        guard let player = self.player else { return }

        if sender.isSelected {
            player.play()
        } else {
            player.pause()
        }
    }
    
    @IBAction func btnNext(sender: UIButton) {
        guard let currentTime = player?.currentTime() else { return }
        let currentTimeInSecondsPlus10 =  CMTimeGetSeconds(currentTime).advanced(by: 15)
        let seekTime = CMTime(value: CMTimeValue(currentTimeInSecondsPlus10), timescale: 1)
        player?.seek(to: seekTime)
        self.updateVideoPlayerState()
    }
    
    @IBAction func btnPrevious(sender: UIButton) {
        guard let currentTime = player?.currentTime() else { return }
        let currentTimeInSecondsMinus10 =  CMTimeGetSeconds(currentTime).advanced(by: -15)
        let seekTime = CMTime(value: CMTimeValue(currentTimeInSecondsMinus10), timescale: 1)
        player?.seek(to: seekTime)
        self.updateVideoPlayerState()
    }
    
    //slider value change and update duration time
    @IBAction func playbackSliderValueChanged(_ sender:UISlider)
    {
        guard let duration = player?.currentItem?.duration else { return }
        let value = Float64(sliderProgress.value) * CMTimeGetSeconds(duration)
        let seekTime = CMTime(value: CMTimeValue(value), timescale: 1)
        player?.seek(to: seekTime )
        self.updateVideoPlayerState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
}

//MARK: - PictureInPictureControllerDelegate
extension ViewController: AVPictureInPictureControllerDelegate {
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        pipController?.startPictureInPicture()
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        pipController?.stopPictureInPicture()
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        self.player = pictureInPictureController.playerLayer.player
        self.playerPlay()
        completionHandler(true)
    }
}


