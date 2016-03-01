//
//  DBDBVideoPlayerController.swift
//  DBVideoPlayer
//
//  Created by Dennis Birch on 12/14/15.
//  Copyright © 2015 Dennis Birch. All rights reserved.
//

import UIKit
import AVFoundation

let DBVideoControllerLoadFailureNotification = "VideoControllerLoadFailure"
let DBVideoControllerStateChangeNotification = "VideoControllerStateChange"
let DBVideoControlsVisibilityChangeNotification = "VideoControlsVisibilityChange"
let DBVideoPlayBeganNotification = "VideoControlsVideoPlayBegan"

enum VideoPlayerState: Int {
    case Unknown
    case Loading
    case ReadyToPlay
    case Playing
    case Stalled
    case Failed
}

class DBVideoPlayerController: NSObject, VideoTransportDelegate {
    // MARK: - Configurable properties
	/*!
 * @brief Image for scrubber thumb
 * @discussion Provides a custom UIImage for the video scrubber thumb. If you don't provide your own image, the default slider thumb is displayed.
 */
	var scrubberThumbImage: UIImage? {
		didSet {
			if let image = scrubberThumbImage {
				controlsOverlay?.setScrubberThumbImage(image)
			}
		}
	}
	
	/*!
 * @brief Sets a flag to automatically begin play
 * @discussion If set to true, the movie files begins playing as soon as it is prepared for play. Otherwise you must call the play() method to begin playing the movie.
 */
    var autoplay = false
	
	/*!
 * @brief Configures the video player to decrement remaining time
 * @discussion When set to true, the remaining time label displays the movie's length minus the movie player's current time. If false, the remaining time label displays the movie's length.
 */
    var autoDecrementRemainingTime = false {
        didSet {
            controlsOverlay?.setAutoDecrementRemainingTime(self.autoDecrementRemainingTime)
        }
    }
    
	/*!
 * @brief Sets a value for fading out controls after a specified number of seconds
 * @discussion Provide a value for fading controls out after certain actions (starting play, stopping play, etc.), or leave at 0 for no delay.
 */
    var controlsDisplayDuration : NSTimeInterval = 0 {
        didSet {
            controlsOverlay?.setDisplayDuration(controlsDisplayDuration)
        }
    }
    
	/*!
 * @brief Specify whether tapping the movie player view should display controls
 * @discussion Set to true to configure the movie player so that a single tap displays the controls overlay/
 */
    var displayControlsOnTap = false

	/*!
 * @brief Specify whether movie player controls should never be hidden
 * @discussion Set to true to configure the movie player to never hide its controls.
 */
    var dontHideControls = false {
        didSet {
            if dontHideControls {
                controlsOverlay?.setDisplayDuration(0)
            } else {
                controlsOverlay?.setDisplayDuration(controlsDisplayDuration)
            }
        }
    }

	/*!
 * @brief Sets the interval for refreshing time updates
 * @discussion Changes the interval at which the elapsed time display is updated. The value for this property also determines the accuracy of the elapsed time display. This value cannot be 0.
 */
    var timeDisplayRefreshInterval: NSTimeInterval = defaultTimeDisplayRefreshInterval {
        didSet {
            if timeDisplayRefreshInterval <= 0 {
                timeDisplayRefreshInterval = DBVideoPlayerController.defaultTimeDisplayRefreshInterval
                return
            }
            controlsOverlay?.timeInterval = timeDisplayRefreshInterval
        }
    }

    // MARK: - State
	
	/*!
 * @brief Provides the current state of the movie player
 * @discussion Returns a member of the VideoPlayerState enum to allow you to determine the player's current state, especially after having received a state change notification, so that you can update your view's UI appropriately.
 */
    var currentState = VideoPlayerState.Unknown {
        didSet {
            if currentState != lastPlayerState {
                NSNotificationCenter.defaultCenter().postNotificationName(DBVideoControllerStateChangeNotification, object: nil)
            }
            // update Play/Pause button
            controlsOverlay?.setIsPlayingVideo(currentState == .Playing)
            lastPlayerState = currentState
        }
    }
    
	// MARK: - Constants for KVO
	private let STATUS_KEYPATH = "status"
	private var PlayerItemStatusContext: String?
	private let assetKeys = ["tracks", "duration", "commonMetadata"]
	static let defaultTimeDisplayRefreshInterval = 1.0
	
    // MARK: Private Properties
    private var hasBoundaryObserver = false
	private var hasStatusObserver = false
	
    private weak var controlsOverlay: DBVideoControlsOverlayView?
    
    private var timeObserver: AnyObject?
    private var itemEndObserver: AnyObject?

    private var lastPlaybackRate: Float = 0.0
    private var lastPlayerState: VideoPlayerState = VideoPlayerState.Unknown
    private weak var boundaryObserver: AnyObject?

    private var url: NSURL?
    private var player: AVPlayer?
    private var playerView: DBVideoPlayerView?
    private var asset: AVAsset?
    private var playerItem: AVPlayerItem? {
        willSet {
            if self.playerItem == playerItem {
                return
            }
            
            if self.playerItem != nil && hasStatusObserver {
                self.playerItem?.removeObserver(self, forKeyPath: STATUS_KEYPATH)
				hasStatusObserver = false
            }
        }
    }
	private var auxiliaryView: UIView?
    
    private var stallTimer: NSTimer?
	
	// MARK: - Configuration
	
	/*!
 * @brief Allows setting an auxiliary view over the movie player
 * @discussion You can use this method to add a view that appears over the controls overlay.
 * @param auxiliaryView: UIView - A UIView to display
 * @param frame: CGRect - The frame to use for the auxiliary view
 */
	func addAuxiliaryView(auxiliaryView: UIView?, frame: CGRect) {
		assert(auxiliaryView != nil)
		self.auxiliaryView = auxiliaryView
		controlsOverlay?.addSubview(auxiliaryView!)
		auxiliaryView!.frame = frame
	}
	
	/*!
 * @brief Removes an auxiliary view added to the movie player
 * @discussion This method is safe to call even if you have not added an auxiliary view or have already removed one.
 */
	func removeAuxiliaryView() {
		if let view = auxiliaryView {
			view.removeFromSuperview()
			auxiliaryView = nil
		}
	}
	
    // MARK: - Initialization
    
	/*!
 * @brief The default intializer for this class
 * @discussion This initializer provides the essential information for setting it up, and performs all the initialization steps other than setting configurable properties which you must do separately.
 * @param url: NSURL - A URL to a file on disk or a remote streaming movie resource for the movie that should be played. Required.
 * @param movieView: UIView - A container view that will hold the movie to be played. Required.
 * @param overlayView: DBVideoControlsOverlayView - This view should be the frontmost layer of your interface. Required.
 * @param playButtonImage: UIImage - The image to use for the controls' Play/Pause button in Play state. Required for correct implementation if you are displaying a Play/Pause button in your controls overlay.
 * @param pauseButtonImage: UIImage - The image to use for the controls' Play/Pause button in Pause state. Required for correct implementation if you are displaying a Play/Pause button in your controls overlay.
 */
	required init(url: NSURL, movieView: UIView, overlayView: DBVideoControlsOverlayView, playButtonImage: UIImage?, pauseButtonImage: UIImage?) {
        self.url = url
        self.asset = AVAsset(URL: url)
        
        super.init()
        
        self.prepareToPlayInView(movieView, overlay: overlayView)
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "handleOrientationChange:", name: UIApplicationDidChangeStatusBarFrameNotification, object: nil)
        nc.addObserver(self, selector: "handlePlaybackStalledNotification:", name: AVPlayerItemPlaybackStalledNotification, object: nil)
        nc.addObserver(self, selector: "handleMoviePlayerPlayEndedNotification:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        
        movieView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "handleShowControlsTapGesture:"))

        boundaryObserver = (self.player?.addBoundaryTimeObserverForTimes([NSValue(CMTime: CMTimeMake(1, 10))], queue: nil, usingBlock: { [weak self] () -> Void in
                nc.postNotificationName(DBVideoPlayBeganNotification, object: nil)
            self!.hasBoundaryObserver = false;
            self!.currentState = .Playing
        }))
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            print("Error setting audio category: \(error)")
        }
		
		if let playImage = playButtonImage {
			overlayView.setPlayButtonImage(playImage)
		}
		if let pauseImage = pauseButtonImage {
			overlayView.setPauseButtonImage(pauseImage)
		}
    }
    
    private func prepareToPlayInView(movieView: UIView, overlay: DBVideoControlsOverlayView) {
        assert(self.asset != nil)
        
        playerItem = AVPlayerItem(asset: self.asset!, automaticallyLoadedAssetKeys: assetKeys)
        playerItem!.addObserver(self, forKeyPath: STATUS_KEYPATH, options: NSKeyValueObservingOptions(rawValue: 0), context: &PlayerItemStatusContext)
		hasStatusObserver = true
        player = AVPlayer(playerItem: playerItem!)
        currentState = .Loading
        playerView = DBVideoPlayerView(player: self.player!, containerView: movieView, overlay: overlay)
        
        updateLayerGravity();
        
        controlsOverlay = overlay
        controlsOverlay?.delegate = self
    }
    
    private func updateLayerGravity() {
        let currentOrientation = UIApplication.sharedApplication().statusBarOrientation
        let playerLayer = playerView?.layer as! AVPlayerLayer
        playerLayer.videoGravity = (UIInterfaceOrientationIsLandscape(currentOrientation)) ? AVLayerVideoGravityResizeAspectFill : AVLayerVideoGravityResizeAspect
    }
    
    deinit {
        player?.pause()
        killStallTimer()
		removeItemEndObserver()
		removeTimeObserver()
    }
    
    // MARK: - Controls visibility
    
    func showControls(shouldShow: Bool) {
        if shouldShow {
            self.controlsOverlay?.showControls()
        } else {
            self.controlsOverlay?.hideControls()
        }
    }
    
    func controlsShowing() -> Bool {
        if let controls = controlsOverlay {
            return controls.isVisible
        }
        
        return false
    }
    
    @objc private func handleShowControlsTapGesture(recognizer: UITapGestureRecognizer) {
        if displayControlsOnTap {
            showControls(true)
        }
    }
    
    // MARK: - Observers/Notifications
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &PlayerItemStatusContext {
            if playerItem?.status == .ReadyToPlay {
                addPlayerItemTimeObserver()
                addItemEndObserverForPlayerItem()
                currentState = .ReadyToPlay
                
                // synchronize the time display
                let duration = playerItem?.duration
                controlsOverlay?.setCurrentTime(CMTimeGetSeconds(kCMTimeZero), duration: CMTimeGetSeconds(duration!))
                
                if autoplay {
                    self.play()
                    controlsOverlay?.autoFadeOutControls()
                }
            } else if playerItem?.status == .Failed {
				currentState = .Failed
                NSNotificationCenter.defaultCenter().postNotification(NSNotification(
                    name: DBVideoControllerLoadFailureNotification, object: nil))
            }
        }
    }
    
    private func addPlayerItemTimeObserver() {
		removeTimeObserver()
        // set refresh interval
        if let playerItem = self.playerItem {
            let interval = CMTimeMakeWithSeconds(timeDisplayRefreshInterval, Int32(NSEC_PER_SEC))

            timeObserver = player?.addPeriodicTimeObserverForInterval(interval, queue: dispatch_get_main_queue(), usingBlock: { [weak self] (time) -> Void in
                self!.controlsOverlay?.setCurrentTime(CMTimeGetSeconds(time), duration: CMTimeGetSeconds(playerItem.duration))
            })
        }
    }
    
	private func addItemEndObserverForPlayerItem() {
		let queue = NSOperationQueue.mainQueue()

		removeItemEndObserver()
		
		itemEndObserver = NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: self.playerItem, queue: queue, usingBlock: { [weak self] (note) -> Void in
			self!.player?.seekToTime(kCMTimeZero, completionHandler: { (finished) -> Void in
				self!.currentState = .ReadyToPlay
				self!.controlsOverlay?.playbackComplete()
			})
			})
	}
	
	private func removeItemEndObserver() {
		if let endObserver = itemEndObserver {
			NSNotificationCenter.defaultCenter().removeObserver(endObserver, name: AVPlayerItemDidPlayToEndTimeNotification, object: player?.currentItem)
			itemEndObserver = nil
		}
	}
	
	private func removeTimeObserver() {
		if let timeObserver = self.timeObserver {
			player?.removeTimeObserver(timeObserver)
			self.timeObserver = nil
		}
	}
	
	@objc private func handleOrientationChange(notification: NSNotification) {
		updateLayerGravity()
		playerView?.setNeedsLayout()
	}
	
    @objc private func handlePlaybackStalledNotification(notification: NSNotification) {
        currentState = .Stalled
        controlsOverlay?.setIsPlayingVideo(false)
        
        // start up a time to check loaded ranges every two seconds so we can know when it's possible to resume
        createStallTimer()
    }
    
    private func checkLoadedRanges(timer: NSTimer) {
        // this method is called by the stallTimer, checking for sufficient download progress
        if hasPlayableLoadedMaterial() {
            // if we have enough additional data to play, kill the stall timer... we don't need it until there's another stall
            killStallTimer()

            // and resume playing video
            play()
        }
    }
    
    private func hasPlayableLoadedMaterial() -> Bool {
        return loadedMediaBuffer() > 1.0
    }
    
    private func loadedMediaBuffer() -> NSTimeInterval {
        let rangeValue = playerItem?.loadedTimeRanges.last
        let timeRange = rangeValue?.CMTimeRangeValue
        return CMTimeGetSeconds(timeRange!.duration)
    }
    
    private func createStallTimer() {
        stallTimer = NSTimer(timeInterval: 2.0, target:self, selector: "checkLoadedRanges", userInfo: nil, repeats: true)
    }
    
    @objc private func handleVideoPlayBeganNotification(notification: NSNotification) {
        boundaryObserver = nil;
    }
    
    private func killStallTimer() {
        stallTimer?.invalidate()
        stallTimer = nil
    }
    
    @objc private func handleMoviePlayerPlayEndedNotification(notification: NSNotification) {
        // make sure the stall timer has been killed when the video reaches the end in case we're on a slow network
        killStallTimer()
    }
    
    // MARK: - Start/Stop Play
    
    private func startPlaying() {
        if playerItem?.status == .Failed {
            asset = AVAsset(URL: self.url!)
            playerItem = AVPlayerItem(asset: asset!, automaticallyLoadedAssetKeys: assetKeys)
            
            player?.replaceCurrentItemWithPlayerItem(playerItem)
            autoplay = true
            return
        } else if currentState == .Loading {
            print("Attempted to play before video loaded")
            return
        }
        
        killStallTimer()
        player?.play()
        player?.rate = 1.0
        controlsOverlay?.setIsPlayingVideo(true)
        controlsOverlay?.setDisplayDuration(controlsDisplayDuration)
        controlsOverlay?.autoFadeOutControls()

        if !hasBoundaryObserver {
            currentState = .Playing
        }
    }
    
    private func stopPlaying() {
        player?.pause()
        killStallTimer()
        controlsOverlay?.setIsPlayingVideo(false)
        currentState = .ReadyToPlay
    }
    
    // MARK: - VideoTransportDelegate
    
    func play() {
        startPlaying()
    }
    
    func pause() {
        killStallTimer()
        lastPlaybackRate = player!.rate
        player?.pause()
        controlsOverlay?.setIsPlayingVideo(false)
        currentState = .ReadyToPlay
    }
    
    func stop() {
        killStallTimer()
        player?.rate = 0
        controlsOverlay?.playbackComplete()
        controlsOverlay?.setIsPlayingVideo(false)
        currentState = .Unknown
    }
    
    func scrubbingStarted() {
        killStallTimer()
        lastPlaybackRate = player!.rate
        player?.pause()
    }
    
    func scrubbedToTime(timeValue: Double) {
        playerItem?.cancelPendingSeeks()
        playerItem?.seekToTime(CMTimeMakeWithSeconds(timeValue, Int32(NSEC_PER_SEC)))
    }
    
    func scrubbingEnded() {
        if lastPlaybackRate > 0 {
            if !hasPlayableLoadedMaterial() {
                createStallTimer()
                currentState = .Stalled
            } else {
                player?.play()
                currentState = .Playing
            }
        }
    }
    
    func setRate(rate: Float) {
        self.player?.rate = rate
    }
    
    func resetVideo() {
        player?.seekToTime(CMTimeMakeWithSeconds(0, 1))
    }
    
}
