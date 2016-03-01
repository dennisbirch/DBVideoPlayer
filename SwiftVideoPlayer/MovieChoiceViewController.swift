//
//  MovieChoiceViewController.swift
//  DBVideoPlayer
//
//  Created by Dennis Birch on 12/26/15.
//  Copyright © 2015 Dennis Birch. All rights reserved.
//

import UIKit

let movieURLString = "https://archive.org/download/EnterTheLoneRanger/EnterTheLoneRanger_512kb.mp4"

class MovieChoiceViewController: UIViewController {

	private func urlForStreamingMovie() -> NSURL {
		return NSURL(string: movieURLString)!
	}
	
	private func urlForMovieFile() -> NSURL? {
		// Drag a video asset into this project and return a NSURL reference to it

		// You can download Apple sample videos from https://support.apple.com/en-us/HT201549 if you have no other content to test with
		
		guard let url = NSBundle.mainBundle().URLForResource("sample_iPod", withExtension: "m4v") else {
			print("Movie file is missing")
			return nil
		}
		
		return url
	}
	
	@IBAction func streamingMovieButtonTapped() {
		presentMovie(urlForStreamingMovie())
	}
	
	@IBAction func diskBasedMovieButtonTapped() {
		if let fileMovieURL = urlForMovieFile() {
			presentMovie(fileMovieURL)
		}
	}
	
	
	func presentMovie(movieURL: NSURL) {
		let vc = self.storyboard?.instantiateViewControllerWithIdentifier("MoviePresentationViewController") as! MoviePresentationViewController
		vc.movieURL = movieURL
		self.navigationController?.pushViewController(vc, animated: true)
	}
}
