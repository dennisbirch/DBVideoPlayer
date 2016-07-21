//
//  VideoOverlayView.swift
//  DBVideoPlayer
//
//  Created by Dennis Birch on 12/14/15.
//  Copyright © 2015 Dennis Birch. All rights reserved.
//

import UIKit

protocol VideoTransportDelegate {
    func play()
    func pause()
    func stop()
    
    func scrubbingStarted()
    func scrubbedToTime(timeValue: Double)
    func scrubbingEnded()
    func setRate(rate: Float)
 }

class DBVideoControlsOverlayView: UIView {
	@IBOutlet weak var elapsedTimeLabel: UILabel?
	@IBOutlet weak var timeRemainingLabel: UILabel?
	@IBOutlet weak var scrubberSlider: UISlider?
	@IBOutlet weak var playPauseButton: UIButton?
	@IBOutlet weak var rewindButton: UIButton?
	@IBOutlet weak var fastForwardButton: UIButton?
	
    var delegate: VideoTransportDelegate?
    var isVisible = false
    var timeAccuracy = 0
    var timeInterval = DBVideoPlayerController.defaultTimeDisplayRefreshInterval {
        didSet {
            let timeString = String(timeInterval)
            if let offset = timeString.rangeOfString(".") {
                let distance = timeString.startIndex.distanceTo((offset.endIndex))
                let decText = String(timeString.characters.dropFirst(distance))
                timeAccuracy = decText.characters.count
            }
        }
    }

    private let kSeekRate: Float = 3.0

    private var isPlaying = false
	private var isSeeking = false
    private var itemDuration: NSTimeInterval = 0
    private var displayDuration: NSTimeInterval = 0
    private var autoDecrementRemainingTime = false
    private var playButtonImage: UIImage?
    private var pauseButtonImage: UIImage?
    
    // MARK: - Setup
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isVisible = true
    }
	
	override func layoutSubviews() {
		elapsedTimeLabel?.text = ""
		timeRemainingLabel?.text = ""
		scrubberSlider?.value = 0
	}
	
	func setPauseButtonImage(image: UIImage) {
        pauseButtonImage = image
    }
    
    func setPlayButtonImage(image: UIImage) {
        playButtonImage = image
    }
    
    func setScrubberThumbImage(image: UIImage) {
        scrubberSlider?.setThumbImage(image, forState: .Normal)
    }
    
    func updatePlayButtonState() {
        playPauseButton?.setImage(self.playButtonImage, forState: .Normal)
    }
    
    func updatePauseButtonState() {
        self.playPauseButton?.setImage(pauseButtonImage, forState: .Normal)
    }
    
    func setAutoDecrementRemainingTime(autoDecrement: Bool) {
        autoDecrementRemainingTime = autoDecrement
    }
    
    func setDisplayDuration(duration: NSTimeInterval) {
        displayDuration = duration
        if displayDuration == 0 {
            NSObject.cancelPreviousPerformRequestsWithTarget(self,
                                                             selector: #selector(DBVideoControlsOverlayView.hideControls),
                                                             object: nil)
        }
    }
    
    // MARK: PlayerItem synch
    
    func setCurrentTime(time: NSTimeInterval, duration: NSTimeInterval) {
        itemDuration = duration
        elapsedTimeLabel?.alpha = 1.0
        timeRemainingLabel?.alpha = 1.0
        
        scrubberSlider?.maximumValue = Float(duration)
        scrubberSlider?.value = Float(time)
        
        elapsedTimeLabel?.text = timeStringForSeconds(time, includeDecimal: true)
        if self.autoDecrementRemainingTime {
            timeRemainingLabel?.text = timeStringForSeconds(duration - time, includeDecimal: false)
        } else {
            timeRemainingLabel?.text = timeStringForSeconds(duration, includeDecimal: false)
        }
    }
    
    func playbackComplete() {
        updatePlayButtonState()
    }
    
    // MARK: Visibility
    func autoFadeOutControls() {
		if isSeeking {
			// don't fade controls out while user is seeking with slider or FF/Rew buttons
			return
		}

		if displayDuration > 0 {
            performSelector(#selector(DBVideoControlsOverlayView.hideControls),
                            withObject: nil,
                            afterDelay: displayDuration)
        }
    }
    
    func showControls() {
        if isVisible {
            autoFadeOutControls()
            return
        }
        
        NSObject.cancelPreviousPerformRequestsWithTarget(self,
                                                         selector: #selector(DBVideoControlsOverlayView.hideControls),
                                                         object: nil)
        isVisible = true
        alpha = 1.0
        NSNotificationCenter.defaultCenter().postNotificationName(DBVideoControlsVisibilityChangeNotification, object: nil)
        autoFadeOutControls()
    }
    
    func hideControls() {
        if !isVisible {
            return
        }
        
        NSObject.cancelPreviousPerformRequestsWithTarget(self,
                                                         selector: #selector(DBVideoControlsOverlayView.showControls),
                                                         object: nil)
        isVisible = false
        alpha = 0

        NSNotificationCenter.defaultCenter().postNotificationName(DBVideoControlsVisibilityChangeNotification, object: nil)
        autoFadeOutControls()
    }
    
    // MARK: State
    
    func setIsPlayingVideo(playing: Bool) {
        isPlaying = playing
        if isPlaying {
            updatePauseButtonState()
        } else {
            updatePlayButtonState()
        }
    }
    
    // MARK: Actions
    
    @IBAction func scrubberTouchedDown(sender: AnyObject) {
		isSeeking = true
        NSObject.cancelPreviousPerformRequestsWithTarget(self,
                                                         selector: #selector(DBVideoControlsOverlayView.hideControls),
                                                         object: nil)
        delegate?.scrubbingStarted()
    }
    
    @IBAction func scrubberChanged(sender: AnyObject) {
        if let slider = sender as? UISlider {
            delegate?.scrubbedToTime(Double(slider.value))
            setCurrentTime(Double(slider.value), duration: itemDuration)
        }
    }
    
    @IBAction func scrubberTouchEnded(sender: AnyObject) {
		isSeeking = false
        delegate?.scrubbingEnded()
        autoFadeOutControls()
    }
    
    @IBAction func playPauseTapped(sender: AnyObject) {
        if isPlaying {
            delegate?.pause()
        } else {
            delegate?.play()
        }
        
        autoFadeOutControls()
    }
    
    @IBAction func rewindTapped(sender: AnyObject) {
		isSeeking = true
        delegate?.setRate(-kSeekRate)
    }
    
    @IBAction func rewindReleased(sender: AnyObject) {
		isSeeking = false
        delegate?.play()
        autoFadeOutControls()
    }
    
    @IBAction func forwardTapped(sender: AnyObject) {
		isSeeking = true
        delegate?.setRate(kSeekRate)
    }

    @IBAction func forwardReleased(sender: AnyObject) {
		isSeeking = false
        delegate?.play()
        autoFadeOutControls()
    }


    // MARK: Time Display
    
	func timeStringForSeconds(time: NSTimeInterval, includeDecimal: Bool) -> String {
		let secondsPerHour = 3600.00
		let secondsPerMinute = 60.00
		
		var seconds = time
		let hours = seconds/secondsPerHour
		let hrsInt = Int(hours)
		let hourSecs = Double(hrsInt) * secondsPerHour
		seconds -= hourSecs
		
		let minutes = seconds/secondsPerMinute
		let minInt = Int(minutes)
		let minuteSecs = Double(minInt) * secondsPerMinute
		seconds -= minuteSecs
		
		var output = ""
		if hrsInt > 0 {
			output = "\(hrsInt):"
		}
		if minInt > 0 {
			let format = (hrsInt > 0) ? "%02d" : "%d"
			output += "\(String(format: format, minInt))"
		} else {
			output += "00"
		}
		
		let secs = Int(seconds)
		output += ":\(String(format: "%02d", secs))"
		
		if includeDecimal && timeAccuracy > 0 {
			seconds = (seconds - Double(secs))
			let decimals = String(format: "%0\(timeAccuracy)d", Int((seconds * pow(10.0, Double(timeAccuracy)))))
			output += ".\(decimals)"
		}
		
		return output
	}
}
