//
//  ViewController.swift
//  DBVideoPlayer
//
//  Created by Dennis Birch on 12/14/15.
//  Copyright © 2015 Dennis Birch. All rights reserved.
//

import UIKit

class MoviePresentationViewController: UIViewController {
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var controlsView: DBVideoControlsOverlayView!
    var videoPlayerController: DBVideoPlayerController?
    var videoPlayerHasStarted = false
	var movieURL: NSURL?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		assert(movieURL != nil)
		let playButtonImage = UIImage(named: "Play")
		let pauseButtonImage = UIImage(named: "Pause")
		videoPlayerController = DBVideoPlayerController(url: movieURL!, movieView: videoView, overlayView: controlsView, playButtonImage: playButtonImage, pauseButtonImage: pauseButtonImage)

        videoPlayerController?.controlsDisplayDuration = 5.0
        videoPlayerController?.displayControlsOnTap = true
		videoPlayerController?.autoplay = true
		
		NSNotificationCenter.defaultCenter().addObserver(self,
		                                                 selector: #selector(didReceiveDBVideoControllerStateChangeNotification),
		                                                 name: DBVideoControllerStateChangeNotification,
		                                                 object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
		                                                 selector: #selector(didReceiveDBVideoControlsVisibiiltyChangeNotification),
		                                                 name: DBVideoControlsVisibilityChangeNotification,
		                                                 object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
		                                                 selector: #selector(didReceiveDBVideoPlayBeganNotification),
		                                                 name: DBVideoPlayBeganNotification,
		                                                 object: nil)
   }
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		
		videoPlayerController?.stop()
	}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func didReceiveDBVideoControllerStateChangeNotification(notification: NSNotification) {
		if let state = videoPlayerController?.currentState {
			switch state {
			case .Unknown:
				break
			case .Loading:
				print("The video is loading")
			case .ReadyToPlay:
				print("The video is ready to play")
			case .Playing:
				print("The video is playing")
			case .Stalled:
				print("The video is stalled")
			case .Failed:
				print("Playing the video stalled")
			}
		}
	}
	
	func didReceiveDBVideoControlsVisibiiltyChangeNotification(notification: NSNotification) {
		if controlsView.isVisible {
			print("The controls view has appeared")
		} else {
			print("The controls view has been hidden")
		}
	}
	
	func didReceiveDBVideoPlayBeganNotification(notification: NSNotification) {
		print("The first video frame has been displayed")
	}
}

