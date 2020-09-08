//
//  PlaybackCoordinator.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 3/3/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

import NVActivityIndicatorView
import YoutubeDirectLinkExtractor

extension Notification.Name {
    static let kAVPlayerViewControllerDidDisappearNotification = Notification.Name.init("kAVPlayerViewControllerDidDisappearNotification")
}

extension AVPlayerViewController {
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .kAVPlayerViewControllerDidDisappearNotification, object: nil)
    }
}

class PlaybackCoordinator: NSObject {

    static let shared = PlaybackCoordinator()
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(playerViewControllerDidDisappear), name: .kAVPlayerViewControllerDidDisappearNotification, object: nil)
    }
    
    private var playbackObserverToken: Any?
    private var currentPlayer: AVPlayer?

    private var loading = false {
        didSet {
            loading ? displayLoadingView() : dismissLoadingView()
        }
    }
    
    private var activityIndicator: NVActivityIndicatorView!
    
    private lazy var loadingView: UIView = {
        let loadingView = UIView(frame: UIScreen.main.bounds)
        loadingView.alpha = 0.0
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = UIScreen.main.bounds
        loadingView.addSubview(blurredEffectView)
        
        let indicatorSize: CGFloat = 80.0
        let indicatorOrigin = CGPoint(x: UIScreen.main.bounds.width/2 - indicatorSize/2, y: UIScreen.main.bounds.height/2 - indicatorSize/2)
        let indicatorFrame = CGRect(x: indicatorOrigin.x, y: indicatorOrigin.y, width: indicatorSize, height: indicatorSize)
        activityIndicator = NVActivityIndicatorView(frame: indicatorFrame, type: .circleStrokeSpin, color: .white, padding: 10.0)
        loadingView.addSubview(activityIndicator)
        
        return loadingView
    }()
    
    private lazy var youtubeLinkExtractor: YoutubeDirectLinkExtractor = {
        return YoutubeDirectLinkExtractor()
    }()
    
    func attemptPlayback<T>(for item: T) {
        guard !loading else {
            print("attemptPlayback() - ERROR: Already attenpting playback.")
            return
        }
        
        if let mediaItem = item as? MediaItem {
            // Play the first clip
            if let clipItem = mediaItem.clips.first {
                PlaybackCoordinator.shared.attemptPlayback(for: clipItem)
            }
        }
        else if let youtubeItem = item as? YouTubeItem {
            loading = true
            youtubeLinkExtractor.extractInfo(for: .id(youtubeItem.youtubeId), success: { [weak self] (videoInfo) in
                DispatchQueue.main.async {
                    self?.loading = false
                    // Get the best source available
                    let path = videoInfo.highestQualityPlayableLink ?? videoInfo.lowestQualityPlayableLink ?? ""
                    if !path.isEmpty, let videoURL = URL(string: path) {
                        self?.play(url: videoURL)
                    }
                    else {
                        self?.presentErrorAlert(for: youtubeItem)
                    }
                }
            }) { [weak self] (_) in
                self?.presentErrorAlert(for: youtubeItem)
            }
        }
    }
    
    private func displayLoadingView() {
        loadingView.removeFromSuperview()
        UIApplication.shared.firstKeyWindow?.addSubview(loadingView)
        
        activityIndicator.startAnimating()

        UIView.animate(withDuration: 0.3) {
            self.loadingView.alpha = 1.0
        }
    }
    
    private func dismissLoadingView() {
        self.activityIndicator.stopAnimating()

        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView.alpha = 0.0
        }) { (finished) in
            self.loadingView.removeFromSuperview()
        }
    }
    
    private func play(url: URL, with headers: [String: String] = [:], mediaItem: MediaItem? = nil) {
        var assetOptions: [String: [String: Any]] = [:]
        if !headers.isEmpty {
            assetOptions = [
                "AVURLAssetHTTPHeaderFieldsKey": headers
            ]
        }
        
        let asset = AVURLAsset(url: url, options: assetOptions)
        let item = AVPlayerItem(asset: asset)
        currentPlayer = AVPlayer(playerItem: item)
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = currentPlayer
        UIApplication.topMostViewController()?.present(playerViewController, animated: true) {
            playerViewController.player?.play()
        }
    }
    
    private func presentErrorAlert<T>(for item: T) {
        let title = "Media stream not found"
        let message = "Couldn't find the media stream for the selected item. Would you like to try again?"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] (action) in
            self?.attemptPlayback(for: item)
        })
        
        UIApplication.topMostViewController()?.present(alert, animated: true)
    }
    
    @objc private func playerViewControllerDidDisappear() {
        if let token = playbackObserverToken {
            currentPlayer?.removeTimeObserver(token)
            playbackObserverToken = nil
        }
        
        currentPlayer?.pause()
        currentPlayer = nil
    }
}
