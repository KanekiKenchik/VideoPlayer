//
//  AVPlayerView.swift
//  VideoPlayer
//
//  Created by Афанасьев Александр Иванович on 19.02.2022.
//

import UIKit
import AVFoundation

class AVPlayerView: UIView {
    
    override class var layerClass: AnyClass {
            return AVPlayerLayer.self
    }

}
