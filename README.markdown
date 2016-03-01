# DBVideoPlayer
A drop-in video player module for iOS written in Swift 2.0. It allows you to easily add a customizable storyboard-based video player view to your projects. It is inspired by code from the excellent book "Learning AVFoundation" by [Bob McCune](http://www.bobmccune.com/).

## Requirements 
DBVideoPlayer requires Xcode 7.0 or higher.

## Usage
To add a video player view with DBVideoPlayer, first create a scene in a storyboard with the following components:

* Movie view (the bottom layer) — This should be an ordinary UIView instance.
* Controls overlay view (next layer up) — Set this to be a DBVideoOverlayView in Xcode's Identity inspector.
* [Movie controls within the controls overlay](id:optional-movie-controls) (Optional):
	* Buttons for Play/Pause, Rewind, Fast forward
	* Slider for scrubbing movie position
	* Labels to display elapsed and total time
* Optionally add graphics for the movie controls.
* Wire up the controls in the storyboard to the DBVideoOverlay class's corresponding outlet properties.
* Wire up the controls in the storyboard to their corresponding actions in the DBVideoOverlay class:
	* `scrubberTouchedDown`: Connect to your UISlider scrubber control for its `touchUpInside` action
	* `scrubberChanged`: Connect to your UISlider scrubber control for its `valueChanged` action
	* `scrubberTouchEnded`: Connect to your UISlider scrubber control for its `touchDown` action
	* `playPauseTapped`: Connect to your Play/Pause button's `touchDown` action
	* `rewindTapped`: Connect to your Reverse button's `touchDown` action 
	* `rewindReleased`: Connect to your Reverse button's `touchUpInside` action
	* `forwardTapped`: Connect to your Fast Forward button's `touchDown` action
	* `forwardReleased`: Connect to your Fast Forward button's `touchUpInside` action

You can see an example of such a layout in the Main storyboard of the example app included in the project archive.

###Setting up a DBVideoPlayer
After creating the layout for a DBVideoPlayer view, you must initialize an instance of the DBVideoPlayerController class from its presenting view controller. You will need properties for storing references to the DBVideoPlayerController instance, the UIView in which you're presenting the video, and the DBVideoOverlayView.

Then you call the DBVideoPlayerController's default initializer: `init(url: NSURL, movieView: UIView, overlayView: DBVideoControlsOverlayView, playButtonImage: UIImage?, pauseButtonImage: UIImage?)`.

_url_: NSURL instance that resolves to an on-disk media file in a playable format (e.g. .mp4, m4v), or to a streaming video asset available via HTTPS.

_movieView_: UIView. This should be the UIView property mentioned above.

_overlayView_: DBVideoControlsOverlayView. This should be the controls overlay property mentioned above.

_playButtonImage_: Optional UIIMage for the graphic to be used as the icon for the Play half of the Play/Pause button (displayed when the video is stopped or paused).

_pauseButtonImage_: Optional UIIMage for the graphic to be used as the icon for the Pause half of the Play/Pause button (displayed when the video is playing).

At that point you should be able play the video whose URL you passed into the DBVideoPlayerController initializer by calling the controller's `play()` method.

### Configuring the video player
There are a number of options you can configure to customize the video playing experience.

For starters, remember that you can customize the appearance of your viewer by leaving out optional controls. You can also compose your [controls overlay](#optional-movie-controls) to have whatever appearance you desire.

There are a number of options available in code, as well:

* Auxiliary views: You can add and remove a UIView instance that you want to appear on top of your video player view hierarchy. To do so, call the `addAuxiliaryView(auxiliaryView: UIView?, frame: CGRect)` method. It takes the UIView that you want to display as its first parameter, and the rect in which you want to display it as its second parameter. Call the `removeAuxiliaryView()` method to add an auxiliaryView that you've added with the method above.

* Set the controller's `autoplay` property to true to have the video start playing as soon as the player has loaded sufficient content. If you set this property to true, you do not need to call the `play()` method mentioned above. This property is _false_ by default.

* Set the controller's `autoDecrementRemainingTime` method to true to display the time left to play instead of the video's total time. This property is _false_ by default.

* Set the controller's `controlsDisplayDuration` property to a non-zero value to control how long before the controls overlay stays on screen after a user taps the video player view. The default for this property is _0_ (no delay).

* Set the controller's `displayControlsOnTap` property to true to enable showing controls when a user taps the video player view. The default for this property is _false_.

* Set the controller's `dontHideControls` property to true to keep the controls overlay on screen. When set to true, it overrides any value set for the controlsDisplayDuration property. The default for this property is _false_.

* Set the controller's `timeDisplayRefreshInterval` property to a non-zero value to control how often the time display should be updated, and how accurate calculations should be. The lower the number, the more it taxes the CPU. A value of 0 is not allowed and will set the interval to the property's default value, _1.0_.

* Set the controller's `scrubberThumbImage` property to a custom UIImage to change the default scrubber "thumb" appearance, which is the default UISlider thumb.

###Notifications
There are a few notifications you can register to listen to in your app to learn when certain issues or state changes are encountered:

* `DBVideoControllerLoadFailureNotification`: Posted by the video controller in the case of a video not loading.
* `DBVideoControllerStateChangeNotification`: Sent when the video player's state changes between the following. Check the video controller's _currentState_ property and use these enum members to determine the player's state:
	* _Unknown_: The player has not been initialized and loading has not begun.
    * _Loading_: The player is loading content in preparation to play it.
    * _ReadyToPlay_: Content has been loaded sufficiently for play to begin.
    * _Playing_: The video player is playing content.
    * _Stalled_: The video player has stopped loading content (usually because of network issues).
    * _Failed_: The video cannot be played. The DBVideoControllerLoadFailureNotification is also sent when the video player enters this state.
* `DBVideoControlsVisibilityChangeNotification`: Send when the video overlay's visibility changes, whether it's appearing or hiding. You can determine the overlay's visibility by checking its _isVisible_ property.
* `DBVideoPlayBeganNotification`: Sent when the first frame of video is displayed. This may not necessarily be the same as the video player changing to _Playing_ state.


##Demo Project
The DBVideoPlayer archive includes a demo project with a rudimentary UI and some basic implementation to give you an example of setting it up and using some of its features. Note that you'll need to provide your own disk-based video file to play if you want to demo that functionality. There is a link to a publicly available streaming video URL to demonstrate that functionality. 

##License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

