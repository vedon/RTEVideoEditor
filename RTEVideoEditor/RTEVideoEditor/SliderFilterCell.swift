//
//  FilterParamCell.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/12.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit
import SnapKit

protocol SliderFilterCellDelegate: class {
    func sliderCellDidUpdate(_ cell: SliderFilterCell, value: Float, filter: RTEFilterType)
}

class SliderFilterCell: UITableViewCell {
    weak var delegate: SliderFilterCellDelegate?
    private var filterItem: FilterItem?
    
    lazy var descLabel: UILabel = {
        let label = UILabel.init(frame: .zero)
        return label
    }()
    
    private lazy var checkMark: UIImageView = {
        let imageView = UIImageView.init(frame: .zero)
        return imageView
    }()
    
    private lazy var slider: UISlider = {
        let slider = UISlider.init(frame: .zero)
        slider.addTarget(self, action: #selector(seekToValue), for: .valueChanged)
        slider.maximumValue = 1.0
        slider.minimumValue = 0.0
        return slider
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupWith(filterItem: FilterItem) {
        self.filterItem = filterItem
        self.descLabel.text = filterItem.type.rawValue
        checkMark.image = filterItem.isSelected ? UIImage.init(named: "check-mark") : nil
    }
    
    @objc func seekToValue(_ sender: UISlider) {
        guard let filterItem = self.filterItem else { return }
        delegate?.sliderCellDidUpdate(self, value: sender.value, filter: filterItem.type)
    }
    
    private func setupViews() {
        addSubview(checkMark)
        addSubview(descLabel)
        addSubview(slider)
        
        descLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(10)
        }
        
        checkMark.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize.init(width: 20, height: 20))
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(descLabel.snp.top)
        }
        
        slider.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(checkMark.snp.left).offset(-10)
            make.top.equalTo(descLabel.snp.bottom)
        }
    }
}

