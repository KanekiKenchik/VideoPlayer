//
//  ShowVideoFromDownloadsViewController.swift
//  VideoPlayer
//
//  Created by Афанасьев Александр Иванович on 23.02.2022.
//

import AVKit
import AVFoundation
import UIKit
import CoreData

class ShowVideoFromDownloadsViewController: UIViewController {
    
    var video = VideoModel()
    
    let formatter = DateFormatter()
    
    var player: AVPlayer!
    
    @IBOutlet weak var videoLabel: UILabel!
    
    var downloadTask: URLSessionDownloadTask?
    
    @IBOutlet weak var avPlayerView: AVPlayerView!
    
    @IBOutlet weak var videoProgressSlider: UISlider!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBAction func videoProgressSliderAction(_ sender: UISlider) {
        
        self.player.seek(to: CMTime(seconds: Double(self.videoProgressSlider.value), preferredTimescale: 1000))
        self.timeLabel.text = self.formatter.string(from: Date(timeIntervalSince1970: TimeInterval(Int(self.videoProgressSlider.value))))
        
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        if self.player.timeControlStatus == .playing {
            self.player.pause()
            self.playButton.setImage(UIImage(systemName: "play"), for: .normal)
        } else {
            self.player.play()
            self.playButton.setImage(UIImage(systemName: "pause"), for: .normal)
        }
    }
    
    @IBOutlet weak var rewindButton: UIButton!
    
    @IBOutlet weak var fastForwardButton: UIButton!

    @IBOutlet weak var volumeButton: UIButton!
    
    
    @IBAction func volumeButtonAction(_ sender: Any) {
        if player.volume == 0.0 {
            volumeButton.setImage(UIImage(systemName: "volume.3"), for: .normal)
            player.volume = 1.0
        } else {
            volumeButton.setImage(UIImage(systemName: "volume.slash"), for: .normal)
            player.volume = 0.0
        }
    }
    
    
    @IBAction func rewindButtonAction(_ sender: Any) {
        
        self.player.seek(to: CMTime(seconds: player.currentTime().seconds-15.0, preferredTimescale: 1000))
        self.timeLabel.text = self.formatter.string(from: Date(timeIntervalSince1970: TimeInterval(Int(player.currentTime().seconds-15.0))))
        
    }
    
    @IBAction func fastForwardButtonAction(_ sender: Any) {
        self.player.seek(to: CMTime(seconds: player.currentTime().seconds+15.0, preferredTimescale: 1000))
        self.timeLabel.text = self.formatter.string(from: Date(timeIntervalSince1970: TimeInterval(Int(player.currentTime().seconds+15.0))))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presentationController?.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.videoLabel.text = video.videoName
        
        if let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(video.videoURL!)
        {
            self.player = AVPlayer(url: filePath)
            let castedLayer = self.avPlayerView.layer as! AVPlayerLayer
            castedLayer.player = player
            self.videoProgressSlider.maximumValue = Float(player.currentItem?.asset.duration.seconds ?? 0)
            
            self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1000), queue: DispatchQueue.main) {time in
                self.formatter.dateFormat = "mm:ss"
                self.timeLabel.text = self.formatter.string(from: Date(timeIntervalSince1970: TimeInterval(Int(time.seconds))))
                self.videoProgressSlider.value = Float(time.seconds)
            }
            
            self.player.play()
            
        } else {
            let alert = UIAlertController(title: "Error", message: "Nothing found", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (touches.first) != nil {
            view.endEditing(true)
            if self.videoProgressSlider.isHidden {
                self.videoProgressSlider.isHidden = false
                self.playButton.isHidden = false
                self.timeLabel.isHidden = false
                self.volumeButton.isHidden = false
                self.fastForwardButton.isHidden = false
                self.rewindButton.isHidden = false
            } else {
                self.videoProgressSlider.isHidden = true
                self.playButton.isHidden = true
                self.timeLabel.isHidden = true
                self.volumeButton.isHidden = true
                self.fastForwardButton.isHidden = true
                self.rewindButton.isHidden = true
            }
        }
        super.touchesBegan(touches, with: event)
    }

}

extension ShowVideoFromDownloadsViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.player.pause()
        self.player = nil
    }
    
}
