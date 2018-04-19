//
//  MusicViewController.swift
//  MusicApp
//
//  Created by Aditya Bonthu on 09/04/18.
//  Copyright © 2018 Aditya Bonthu. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class MusicViewController: UIViewController, MPMediaPickerControllerDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var songNameLabel: UILabel!
    @IBOutlet var controlSlider: UISlider!
    @IBOutlet var startTimeLabel: UILabel!
    @IBOutlet var endTimeLabel: UILabel!
    
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var forwardButton: UIButton!
    @IBOutlet var backwardButton: UIButton!
    
    @IBOutlet var volumeView: UIView!
    
    var mediaPicker = MPMediaPickerController()
    let mediaQuary = MPMediaQuery.songs()
    var mediaPlayer = MPMusicPlayerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            let _ = try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch let error as NSError {
            print("an error occurred when audio session category.\n \(error)")
        }
        
        //Create view that has volume of controller view
        let volumeSlider = MPVolumeView(frame: volumeView.layer.bounds)
        volumeView.addSubview(volumeSlider)
        
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
       
        NotificationCenter.default.addObserver(self, selector:#selector(updatePlayingCurrentInfo), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Function to pull track info and update labels
    @objc func updateTimer() {
        
        let currentTrack = mediaPlayer.nowPlayingItem
        let albumImage = currentTrack?.artwork?.image(at: imageView.bounds.size)
        imageView.image = albumImage
        songNameLabel.text = currentTrack?.title
        
        let trackDuration = currentTrack?.playbackDuration
        let trackElapsed = mediaPlayer.currentPlaybackTime
        
        if trackElapsed.isNaN {
            return
        }
        
        let elapsedMinutes = Int(trackElapsed / 60)
        let elapsedSeconds = Int(trackElapsed.truncatingRemainder(dividingBy: 60))
        if elapsedSeconds < 10 {
            startTimeLabel.text = "\(elapsedMinutes):0\(elapsedSeconds)"
        } else {
            startTimeLabel.text = "\(elapsedMinutes):\(elapsedSeconds)"
        }

        let trackRemaining = Int(trackDuration!) - Int(trackElapsed)
        let remainingMinutes = trackRemaining / 60
        let remainingSeconds = trackRemaining % 60
        if remainingSeconds < 10 {
            endTimeLabel.text = "\(remainingMinutes):0\(remainingSeconds)"
        } else {
            endTimeLabel.text = "\(remainingMinutes):\(remainingSeconds)"
        }
        
        //set maximum value of the slider
        controlSlider.maximumValue = Float(trackDuration!)
        
        //changes slider to as song progresses
        controlSlider.value = Float(trackElapsed)
        
        // For Control Center
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: currentTrack!.title ?? "",
                                                           MPMediaItemPropertyAlbumTitle: currentTrack?.albumTitle ?? "",
                                                           MPMediaItemPropertyArtist: currentTrack?.albumArtist ?? "",
                                                           MPMediaItemPropertyPlaybackDuration: currentTrack?.playbackDuration ?? 0,
                                                           MPNowPlayingInfoPropertyElapsedPlaybackTime: 20,
                                                           MPMediaItemPropertyArtwork: currentTrack?.artwork ?? ""]

    }
    
    // Creating function to change labels to current track info based on previous
    @objc func updatePlayingCurrentInfo() {
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }

    // MARK : **** IBActions ****

    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        if mediaPlayer.playbackState == .paused {
            playPauseButton.setImage(UIImage (named: "Pause"), for: .normal)
            mediaPlayer.play()
        } else if mediaPlayer.playbackState == .playing {
            playPauseButton.setImage(UIImage (named: "Play"), for: .normal)
            mediaPlayer.pause()
        } else if mediaPlayer.playbackState == .stopped {
            playPauseButton.setImage(UIImage (named: "Pause"), for: .normal)
            mediaPlayer = MPMusicPlayerController.applicationMusicPlayer
            mediaPlayer.setQueue(with: mediaQuary)
            mediaPlayer.play()
        }
    }
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        mediaPlayer.skipToNextItem()
    }
    
    @IBAction func previousButtonPressed(_ sender: UIButton) {
        mediaPlayer.skipToPreviousItem()
    }
    
    @IBAction func controlSeekSliderAction(_ sender: UISlider) {
        mediaPlayer.currentPlaybackTime = TimeInterval(sender.value)
    }
    
    @IBAction func addMusicButtonAction(_ sender: UIBarButtonItem) {
        mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.delegate = self
        mediaPicker.allowsPickingMultipleItems = true
        present(mediaPicker, animated: true, completion: {})
    }
    
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        self.dismiss(animated: true, completion: nil)
        let selectedSongs = mediaItemCollection
        mediaPlayer.setQueue(with: selectedSongs)
        mediaPlayer.play()
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //response to remote control events

    func remoteControlReceivedWithEvent(_ receivedEvent:UIEvent)  {
        if (receivedEvent.type == .remoteControl) {
            switch receivedEvent.subtype {
            case .remoteControlTogglePlayPause:
                if mediaPlayer.currentPlaybackRate > 0.0 {
                    mediaPlayer.pause()
                } else {
                    mediaPlayer.play()
                }
            case .remoteControlPlay:
                mediaPlayer.play()
            case .remoteControlPause:
                mediaPlayer.pause()
            default:
                print("received sub type \(receivedEvent.subtype) Ignoring")
            }
        }
    }
}

