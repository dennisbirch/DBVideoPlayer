//
//  DBVideoPlayerView.swift
//  DBVideoPlayer
//
//  Created by Dennis Birch on 12/14/15.
//  Copyright © 2015 Dennis Birch. All rights reserved.
//

import UIKit
import AVFoundation

class DBVideoPlayerView: UIView {

    var overlayView: DBVideoControlsOverlayView
    var containerView: UIView
    
    init(player: AVPlayer, containerView: UIView, overlay: DBVideoControlsOverlayView) {
        self.containerView = containerView
        self.overlayView = overlay
        
        overlayView.backgroundColor = UIColor.clearColor()
        
        super.init(frame: CGRectZero)
        
        let playerLayer = self.layer as! AVPlayerLayer
        playerLayer.player = player
        
        backgroundColor = UIColor.blackColor()
        self.frame = containerView.bounds
        layer.frame = self.frame
        containerView.addSubview(self)
    }

    required init?(coder aDecoder: NSCoder) {
        containerView = UIView()
        overlayView = DBVideoControlsOverlayView(coder: aDecoder)!
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.frame = UIScreen.mainScreen().bounds
        layer.frame = self.frame
    }
    
    override class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }

}
