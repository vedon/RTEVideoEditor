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
        
        RTEFilterType.allCases.forEach { (filter) in
            table.register(filter.cell, forCellReuseIdentifier: filter.cellIdentifier)
        }
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPlayer()
        
        setupViews()
        
        slider.maximumValue = Float(player.duration.value)
        
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
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            } else {
                // Fallback on earlier versions
                make.bottom.equalTo(bottomLayoutGuide.snp.bottom)
            }
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let filterItem = controlPannel.filterItems[indexPath.row]
        return filterItem.type.height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let filterItem = controlPannel.filterItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: filterItem.type.cellIdentifier, for: indexPath)
        cell.selectionStyle = .none
        
        switch cell {
        case let sliderCell as SliderFilterCell:
            sliderCell.setupWith(filterItem: filterItem)
            sliderCell.delegate = self
            break
        case let filterCell as FilterCell:
            filterCell.setupWith(filterItem: filterItem)
        default: break
        }

        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var filterItem = controlPannel.filterItems[indexPath.row]
        filterItem.isSelected = !filterItem.isSelected
        
        if filterItem.isSelected {
            player.add(filter: filterItem.type)
        } else {
            player.remove(filter: filterItem.type)
        }
        
        controlPannel.filterItems[indexPath.row] = filterItem
        tableView.reloadData()
    }
}

extension ViewController: SliderFilterCellDelegate {
    func sliderCellDidUpdate(_ cell: SliderFilterCell, value: Float, filter: RTEFilterType) {
        var paramas = CanvasParams.init()
        paramas.blurProgress = value
        
        self.player.update(filter: filter, params: paramas)
    }
}

extension RTEFilterType {
    var cellIdentifier: String {
        switch self {
        case .canvas: return "canvas"
        case .gaussian: return "gaussian"
        default: return "cell"
        }
    }
    
    var cell: AnyClass {
        switch self {
        case .canvas, .gaussian: return SliderFilterCell.self
        default: return FilterCell.self
        }
    }
    
    var height: CGFloat {
        switch self {
        case .canvas, .gaussian:
            return 68
        default:
            return 42
        }
    }
}
