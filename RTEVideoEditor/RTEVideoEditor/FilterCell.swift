//
//  FilterCell.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit
import SnapKit

class FilterCell: UITableViewCell {
    static let identifier = "FilterCell"
    
    private lazy var checkMark: UIImageView = {
        let imageView = UIImageView.init(frame: .zero)
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupWith(filterItem: FilterItem) {
        self.textLabel?.text = filterItem.type.rawValue
        checkMark.image = filterItem.isSelected ? UIImage.init(named: "check-mark") : nil
    }
    
    private func setupViews() {
        addSubview(checkMark)
        
        checkMark.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize.init(width: 20, height: 20))
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }
}
