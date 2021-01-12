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

extension Notification.Name {
    static let kAVPlayerViewControllerDidDisappearNotification = Notification.Name.init("kAVPlayerViewControllerDidDisappearNotification")
}

extension AVPlayerViewController {
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .kAVPlayerViewControllerDidDisappearNotification, object: nil)
    }
    
    open var isPlaying: Bool {
        return self.player?.rate != 0 && self.player?.error == nil
    }
}

enum PlaybackMode {
    case idle
    case playing
    case pip
}

class PlaybackCoordinator: NSObject, AVPlayerViewControllerDelegate {

    static let shared = PlaybackCoordinator()
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(playerViewControllerDidDisappear), name: .kAVPlayerViewControllerDidDisappearNotification, object: nil)
    }
    
    private var currentPlayer: AVPlayer?
    private var currentPlayerController: AVPlayerViewController!

    private var loading = false {
        didSet {
            loading ? displayLoadingView() : dismissLoadingView()
        }
    }
    
    private(set) var playbackMode: PlaybackMode = .idle
    
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
    
    // MARK: - Playback & Preparation -
    
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
    
    func attemptPlayback<T>(for item: T) {
        guard !loading else {
            print("attemptPlayback() - ERROR: Already attempting playback.")
            return
        }
        
        if playbackMode == .pip {
            resetPlaybackSession()
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
                DispatchQueue.main.async {
                    self?.loading = false
                    self?.presentErrorAlert(for: youtubeItem)
                }
            }
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
        
        currentPlayerController = AVPlayerViewController()
        currentPlayerController.delegate = self
        currentPlayerController.player = currentPlayer

        UIApplication.topMostViewController()?.present(currentPlayerController, animated: true) {
            self.currentPlayerController.player?.play()
            self.playbackMode = .playing
        }
    }
    
    func resetPlaybackSession() {
        currentPlayer?.pause()
        currentPlayer = nil

        currentPlayerController.player = nil
        currentPlayerController.dismiss(animated: false)
        currentPlayerController.delegate = nil
        currentPlayerController = nil
        
        playbackMode = .idle
    }
    
    // MARK: - Error Handling -

    private func presentErrorAlert<T>(for item: T) {
        let alert = UIAlertController(title: "Media stream not found", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let mediaItem = item as? YouTubeItem {
            var preferredYTUrl: URL!
            var tryActionTitle: String!
            
            let ytAppUrl = URL(string: "youtube://\(mediaItem.youtubeId)")!
            let ytWebUrl = URL(string: "https://www.youtube.com/watch?v=\(mediaItem.youtubeId)")!

            if UIApplication.shared.canOpenURL(ytAppUrl) {
                tryActionTitle = "Try on App"
                alert.message = "Couldn't extract the media stream for the selected YouTube item. Would you like to try to open it on the YouTube app?"
                preferredYTUrl = ytAppUrl
            }
            else {
                tryActionTitle = "Try on Web"
                alert.message = "Couldn't extract the media stream for the selected YouTube item. Would you like to try to open it on the YouTube website?"
                preferredYTUrl = ytWebUrl
            }
            
            alert.addAction(UIAlertAction(title: tryActionTitle, style: .default) { (action) in
                UIApplication.shared.open(preferredYTUrl)
            })
        }
        else {
            alert.message = "Couldn't find the media stream for the selected item. Would you like to try again?"
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] (action) in
                self?.attemptPlayback(for: item)
            })
        }
        
        UIApplication.topMostViewController()?.present(alert, animated: true)
    }
    
    // MARK: - AVPlayerViewController Callbacks -
    
    @objc private func playerViewControllerDidDisappear() {
        if playbackMode == .playing {
            resetPlaybackSession()
        }
    }
    
    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        playbackMode = .pip
    }
    
    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        if !playerViewController.isPlaying {
            resetPlaybackSession()
        }
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        if playerViewController.isPlaying {
            UIApplication.topMostViewController()?.present(playerViewController, animated: true) {
                completionHandler(true)
                
                self.playbackMode = .playing
            }
        }
    }
}
