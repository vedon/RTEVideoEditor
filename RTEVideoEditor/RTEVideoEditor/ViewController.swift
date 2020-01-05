//
//  ViewController.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2019 Free. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit

class ViewController: UIViewController {
    private var player: RTEVideoPlayer!
    private lazy var slider: UISlider = {
        let slider = UISlider.init(frame: .zero)
        slider.addTarget(self, action: #selector(seekToTime(_:)), for: .valueChanged)
        return slider
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = RTEVideoPlayer.init()
        view.addSubview(player.layer)
        view.addSubview(slider)
        
        if let path = Bundle.main.path(forResource: "cat", ofType: "MP4") {
            let asset = AVAsset.init(url: URL.init(fileURLWithPath: path))

            player.asset = asset
            player.start()
        }
        
        if let asset = player.asset {
            slider.minimumValue = 0.0
            slider.maximumValue = Float(asset.duration.value)
        }
        
        setupViews()
        // Do any additional setup after loading the view.
    }
    
    private func setupViews() {
        view.addSubview(player.layer)
        view.addSubview(slider)
        
        let ratio: CGFloat = 4.0 / 4.0
        player.layer.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(view.snp.width).multipliedBy(1.0 / ratio)
            make.top.equalToSuperview().offset(60)
            make.left.equalToSuperview()
        }
        
        slider.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(30)
            make.top.equalTo(player.layer.snp.bottom).offset(10)
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    @objc func seekToTime(_ sender: UISlider) {
        guard let asset = player.asset else { return }
        let time = CMTime(value: CMTimeValue(sender.value), timescale: asset.duration.timescale)
        self.player.seekToTime(time)
    }
}

