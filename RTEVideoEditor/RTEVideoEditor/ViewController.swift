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
    private lazy var controlPannel: EditControlPannel = {
        let pannel = EditControlPannel.init()
        return pannel
    }()
    
    private lazy var slider: UISlider = {
        let slider = UISlider.init(frame: .zero)
        slider.addTarget(self, action: #selector(seekToTime(_:)), for: .valueChanged)
        return slider
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView.init(frame: .zero)
        table.delegate = self
        table.dataSource = self
        table.hideEmptyCells()
        
        table.register(FilterCell.self, forCellReuseIdentifier: FilterCell.identifier)
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPlayer()
        
        setupViews()
        
        slider.maximumValue = Float(player.duration.value)
        
        // Do any additional setup after loading the view.
    }
    
    private func setupPlayer() {
        self.player = RTEVideoPlayer.init()
        if let path = Bundle.main.path(forResource: "cat", ofType: "MP4") {
            let asset = AVAsset.init(url: URL.init(fileURLWithPath: path))

            player.asset = asset
            player.delegate = self
            player.start()
        }
    }
    
    private func setupViews() {
        view.addSubview(player.layer)
        view.addSubview(slider)
        view.addSubview(tableView)
        
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
        
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(slider.snp.bottom)
            make.bottom.equalToSuperview()
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    @objc func seekToTime(_ sender: UISlider) {
        let time = CMTime(value: CMTimeValue(sender.value), timescale: player.duration.timescale)
        self.player.seekToTime(time, autoPlay: false)
    }
}

extension ViewController: RTEVideoPlayerDelegate {
    func playerSliderDidChange(_ player: RTEVideoPlayer) {
        self.slider.value = player.progress * Float(player.duration.value)
    }
    
    func playerDidPlayToEnd(_ player: RTEVideoPlayer) {
        self.slider.value = 0.0
        self.player.seekToTime(CMTime.zero, autoPlay: false)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controlPannel.filterItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FilterCell.identifier, for: indexPath)
        cell.selectionStyle = .none
        
        if let filterCell = cell as? FilterCell {
            filterCell.setupWith(filterItem: controlPannel.filterItems[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var filterItem = controlPannel.filterItems[indexPath.row]
        filterItem.isSelected = !filterItem.isSelected
        
        if filterItem.isSelected {
            player.add(filterDescriptor: filterItem.descriptor)
        } else {
            player.remove(filterDescriptor: filterItem.descriptor)
        }
        
        controlPannel.filterItems[indexPath.row] = filterItem
        tableView.reloadData()
    }
}
