//
//  SearchViewController.swift
//  VideoPlayer
//
//  Created by Афанасьев Александр Иванович on 17.02.2022.
//

import AVKit
import AVFoundation
import UIKit
import CoreData
import SystemConfiguration

class SearchViewController: UIViewController, URLSessionDelegate {
    
    let formatter = DateFormatter()
    
    var player: AVPlayer!
    
    var downloadTask: URLSessionDownloadTask?
    
    var videoURL: String?
    
    @IBOutlet weak var avPlayerView: AVPlayerView!
    
    @IBOutlet weak var urlPlaceholder: UITextField!
    
    @IBOutlet weak var videoProgressSlider: UISlider!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBAction func searchButton(_ sender: UIButton) {
        
        urlPlaceholder.resignFirstResponder()
        
        videoURL = urlPlaceholder.text ?? ""
        
        guard Reachability.isConnectedToNetwork() == true else {
            
            let alert = UIAlertController(title: "Network error", message: "Lost internet connection", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
            
        }
    
        if urlPlaceholder.text != "" {
            self.player = AVPlayer(url: URL(string: urlPlaceholder.text!)!)
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
            let alert = UIAlertController(title: "Error", message: "Nothing found. Try entering the valid URL first", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if videoProgressSlider.maximumValue == 0.0 {
            let alert = UIAlertController(title: "Error", message: "The URL does not contain video. Enter the valid URL first", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didPlayToEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @IBAction func videoProgressSliderAction(_ sender: UISlider) {
        
        if ifVideoIsEntered(player: player) != 0 {
            self.player.seek(to: CMTime(seconds: Double(self.videoProgressSlider.value), preferredTimescale: 1000))
            self.timeLabel.text = self.formatter.string(from: Date(timeIntervalSince1970: TimeInterval(Int(self.videoProgressSlider.value))))
        }
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        
        if ifVideoIsEntered(player: player) != 0 {
            if self.player.timeControlStatus == .playing {
                self.player.pause()
                self.playButton.setImage(UIImage(systemName: "play"), for: .normal)
            } else {
                self.player.play()
                self.playButton.setImage(UIImage(systemName: "pause"), for: .normal)
            }
        }
    }
    
    
    @IBOutlet weak var rewindButton: UIButton!
    
    @IBOutlet weak var fastForwardButton: UIButton!
    
    @IBAction func downloadButton(_ sender: UIButton) {
        
        guard Reachability.isConnectedToNetwork() == true else {
            
            let alert = UIAlertController(title: "Network error", message: "Lost internet connection", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
            
        }
        
        if ifVideoIsEntered(player: player) != 0 {
            let alert = UIAlertController(title: "Download", message: "Enter the name of the video", preferredStyle: .alert)
            alert.addTextField { videoName in
                videoName.placeholder = "Video name"
            }
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { UIAlertAction in
                self.saveVideo(videoName: alert.textFields?.first?.text ?? "")
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in }))

            self.present(alert, animated: true, completion: nil)
        }

    }

    @IBOutlet weak var volumeButton: UIButton!
    
    @IBAction func volumeButtonAction(_ sender: Any) {
        
        if ifVideoIsEntered(player: player) != 0 {
            if player.volume == 0.0 {
                volumeButton.setImage(UIImage(systemName: "speaker.wave.3"), for: .normal)
                player.volume = 1.0
            } else {
                volumeButton.setImage(UIImage(systemName: "volume.slash"), for: .normal)
                player.volume = 0.0
            }
        }
    }
    
    
    @IBAction func rewindButtonAction(_ sender: Any) {
        
        if ifVideoIsEntered(player: player) != 0 {
            self.player.seek(to: CMTime(seconds: player.currentTime().seconds-15.0, preferredTimescale: 1000))
            self.timeLabel.text = self.formatter.string(from: Date(timeIntervalSince1970: TimeInterval(Int(player.currentTime().seconds-15.0))))
        }
        
    }
    
    @IBAction func fastForwardButtonAction(_ sender: Any) {
        
        if ifVideoIsEntered(player: player) != 0 {
            self.player.seek(to: CMTime(seconds: player.currentTime().seconds+15.0, preferredTimescale: 1000))
            self.timeLabel.text = self.formatter.string(from: Date(timeIntervalSince1970: TimeInterval(Int(player.currentTime().seconds+15.0))))
        }
    }
    
    
    @IBAction func clearSearchField(_ sender: Any) {
        urlPlaceholder.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func ifVideoIsEntered(player: AVPlayer?) -> Int {
        guard player != nil else {
            let alert = UIAlertController(title: "Error", message: "Video not found. Try entering the valid URL first", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return 0
        }
        return 1
    }

    
    func saveVideo(videoName: String) {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Video", in: context)
        let newEntity = NSManagedObject(entity: entity!, insertInto: context)
        
        newEntity.setValue(videoName, forKey: "videoName")
        newEntity.setValue("downloading", forKey: "videoURL")
        
        let downloadRequest = NSMutableURLRequest(url: URL(string: videoURL ?? "")!)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.downloadTask = session.downloadTask(with: downloadRequest as URLRequest, completionHandler: { [self] (url, response, error) in
            
            if error != nil{
                self.downloadTask?.resume()
            }

            guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            print(documentsDirectoryURL)
            
            var fileExt = ""
            for i in (response?.suggestedFilename ?? "").reversed() {
                if i == "." {
                    break
                }
                fileExt.insert(i, at: fileExt.startIndex)
            }
            
            let videoURL = "\(videoName).\(fileExt)"
            
            newEntity.setValue(videoURL, forKey: "videoURL")
            
            do {
                try context.save()
                print("Video saved successfully")
            } catch {
                print("Failed saving")
            }
            
            let destinationURL = documentsDirectoryURL.appendingPathComponent("\(videoURL)")
            
            do {
                if url != nil {
                    try FileManager.default.moveItem(at: url!, to: destinationURL)
                }
            } catch { print(error.localizedDescription) }

        })
        
        self.downloadTask?.resume()
 
    }
    
    @objc func didPlayToEnd() {
        self.player.seek(to: CMTimeMakeWithSeconds(0, preferredTimescale: 1000))
        self.playButton.setImage(UIImage(systemName: "pause"), for: .normal)
        print("Video has stopped")
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

