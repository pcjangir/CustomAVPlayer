//
//  ViewController.swift
//  CustomAVPlayer
//
//  Created by Poonam on 23/07/22.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var playerControlsContainerView: UIView!
    @IBOutlet weak var playerTimer: UILabel!
    @IBOutlet weak var playAndPauseIcon: UIButton!
    @IBOutlet weak var videoSlider: UISlider!
    @IBOutlet weak var airPlayView: UIView!
    @IBOutlet weak var progressView: UIActivityIndicatorView!
    
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var timeObserverToken: Any?
    private var playerControlsTimer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpPlayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = playerView.bounds
    }
    
    deinit {
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
        if self.timeObserverToken != nil {
            player?.removeTimeObserver(self.timeObserverToken!)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.portrait, UIInterfaceOrientationMask.landscapeLeft]
    }
    
    
    @IBAction func handleButtonActions(_ sender: UIButton) {
        if sender.tag == 0 {
            // Handle play and pause action
            if player?.timeControlStatus == .playing {
                player?.pause()
                playAndPauseIcon.setBackgroundImage(UIImage(named: "pauseIcon"), for: .normal)
                
            }
            else if player?.timeControlStatus == .paused {
                player?.play()
                playAndPauseIcon.setBackgroundImage(UIImage(named: "playIcon"), for: .normal)
            }
            startPlayerControlsTimer()
        }
        else if sender.tag == 1 {
            // Handle video rotate action
            if UIDevice.current.orientation == .portrait {
                let value = UIInterfaceOrientation.landscapeLeft.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
            }
            else {
                let value = UIInterfaceOrientation.portrait.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
            }
            startPlayerControlsTimer()
        }
        else if sender.tag == 2 {
            // Forward 10 seconds video action
            guard let duration = player.currentItem?.duration else { return }
            let currentTime = CMTimeGetSeconds(player.currentTime())
            let newTime = currentTime + 10
            if newTime < (CMTimeGetSeconds(duration) - 10) {
                let time = CMTimeMake(value: Int64(newTime*1000), timescale: 1000)
                player.seek(to: time)
            }
            startPlayerControlsTimer()
        }
        else if sender.tag == 3 {
            // Backword 10 seconds video action
            let currentTime = CMTimeGetSeconds(player.currentTime())
            var newTime = currentTime - 10
            if newTime < 0 {
                newTime = 0
            }
            let time = CMTimeMake(value: Int64(newTime*1000), timescale: 1000)
            player.seek(to: time)
            startPlayerControlsTimer()
        }
        else if sender.tag == 3 {
            // Handle airplay action
        }
    }
    
    @IBAction func slidervlaueChanged(_ sender: UISlider) {
        player.seek(to: CMTimeMake(value: Int64(sender.value*1000), timescale: 1000))
        startPlayerControlsTimer()
    }
    
    @IBAction func sliderDragStart(_ sender: UISlider) {
        playerControlsContainerView.isHidden = false
    }
    
    
    func setUpPlayer() {
        guard let url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else { return }
        player = AVPlayer(url: url)
        player.allowsExternalPlayback = true
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        playerView.layer.addSublayer(playerLayer)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureAction))
        playerView.addGestureRecognizer(tapGesture)
        addPlayerObservers()
        setupAVRouterPicker()
    }
    
    func startPlayerControlsTimer() {
        self.playerControlsTimer?.invalidate()
        self.playerControlsContainerView.isHidden = false
        self.playerControlsTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { [weak self] _ in
            self?.playerControlsContainerView.isHidden = true
        })
    }
    
    func addPlayerObservers() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            guard let currentItem = self?.player.currentItem else { return }
            self?.videoSlider.maximumValue = Float(currentItem.duration.seconds)
            self?.videoSlider.minimumValue = 0
            self?.videoSlider.value = Float(currentItem.currentTime().seconds)
            self?.playerTimer.text = self?.getTimeString(from: currentItem.currentTime())
        }
        
        player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
    }
    
    @objc func handleTapGestureAction() {
        if player?.timeControlStatus == .paused || player?.timeControlStatus == .playing {
            startPlayerControlsTimer()
        }
    }
    
    func showAndHidePlayerControls() {
        self.playerControlsContainerView.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now()+4) { [weak self] in
            self?.playerControlsContainerView.isHidden = true
        }
    }
    
    
    func getTimeString(from time:CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds/3600)
        let minutes = Int(totalSeconds/60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments:[hours, minutes,seconds])
        }
        else {
            return String(format: "%02i:%02i", arguments:[ minutes,seconds])
        }
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            if newStatus != oldStatus {
                DispatchQueue.main.async {[weak self] in
                    if newStatus == .playing || newStatus == .paused {
                        self?.progressView.stopAnimating()
                    } else {
                        self?.progressView.startAnimating()
                    }
                }
            }
        }
    }
    
}

extension ViewController :AVRoutePickerViewDelegate {
    
    private func setupAVRouterPicker() {
        let routerPicker = AVRoutePickerView()
        routerPicker.activeTintColor = .white
        routerPicker.tintColor = .white
        routerPicker.delegate = self
        //  routerPicker.prioritizesVideoDevices = true
        routerPicker.translatesAutoresizingMaskIntoConstraints = false
        self.airPlayView.addSubview(routerPicker)
        routerPicker.centerYAnchor.constraint(equalTo: self.airPlayView.centerYAnchor).isActive = true
        routerPicker.centerXAnchor.constraint(equalTo: self.airPlayView.centerXAnchor).isActive = true
        routerPicker.widthAnchor.constraint(equalToConstant: 300).isActive = true
        routerPicker.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        print("Will present routes")
    }
    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        print("End presenting routes")
    }
    
}

