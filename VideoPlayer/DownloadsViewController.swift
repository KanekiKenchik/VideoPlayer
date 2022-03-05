//
//  DownloadsViewController.swift
//  VideoPlayer
//
//  Created by Афанасьев Александр Иванович on 21.02.2022.
//

import UIKit
import CoreData

class DownloadsViewController: UIViewController {
    
    var videos = [VideoModel]()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func clearHistoryButtonAction(_ sender: Any) {
        
        let fetchRequest: NSFetchRequest<Video> = Video.fetchRequest()
        
        if let tasks = try? context.fetch(fetchRequest) {
            for task in tasks {
                context.delete(task)
            }
        }
        
        do {
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        self.videos.removeAll(keepingCapacity: false)
        tableView.reloadData()
        
        let fileManager = FileManager.default
        guard let directoryWithFiles = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryWithFiles, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    @IBAction func editButton(_ sender: UIButton) {
        tableView.isEditing = !tableView.isEditing
    }
    
    
    @IBOutlet weak var videoNamePlaceholder: UITextField!
    
    @IBAction func searchButtonAction(_ sender: UIButton) {
        let videoName = videoNamePlaceholder.text ?? ""
        if videoName != "" {
            videos.removeAll()
            getVideosByName(videoName: videoName)
            self.tableView.reloadData()
        } else {
            videos.removeAll()
            getData()
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        videos.removeAll()
        getData()
        self.tableView.reloadData()
    }
    
    func getData() {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                let tmp = VideoModel(videoName: (data.value(forKey: "videoName") as! String), videoURL: (data.value(forKey: "videoURL") as! String))
                videos.insert(tmp, at: 0)
            }
            
        } catch {
            print("Failed")
        }
    }

    private func getVideosByName(videoName: String) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                let tmp = VideoModel(videoName: (data.value(forKey: "videoName") as! String), videoURL: (data.value(forKey: "videoURL") as! String))
                if tmp.videoName!.contains(videoName) {
                    videos.insert(tmp, at: 0)
                }
            }
            
        } catch {
            print("Failed")
        }
        
    }

}

extension DownloadsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! VideoTableViewCell
        let video = videos[indexPath.row]
        cell.videoName.text = video.videoName
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = videos[indexPath.row]
        let viewController = self.storyboard!.instantiateViewController(withIdentifier: "showVideo") as! ShowVideoFromDownloadsViewController
        viewController.video = video
        self.present(viewController, animated: true, completion: nil)
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            
            let fetchRequest: NSFetchRequest<Video> = Video.fetchRequest()
            
            if let objects = try? context.fetch(fetchRequest) {
                for object in objects {
                    if object.videoURL == videos[indexPath.row].videoURL!{
                        context.delete(object)
                    }
                }
            }
            
            do {
                try context.save()
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            let fileManager = FileManager.default
            guard let directoryWithFiles = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let fileURL = directoryWithFiles.appendingPathComponent(videos[indexPath.row].videoURL!)
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Could not clear temp folder: \(error)")
            }
            
            videos.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
        }
    }
    
}

