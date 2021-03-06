//
//  MalaBaseCardCell.swift
//  mala-ios
//
//  Created by 王新宇 on 16/5/19.
//  Copyright © 2016年 Mala Online. All rights reserved.
//

import UIKit

class MalaBaseCardCell: UICollectionViewCell {
    
    // MARK: - Components
    /// 布局视图（卡片）
    lazy var layoutView: UIView = {
        let view = UIView(UIColor.white)
        return view
    }()
    /// 标识是否作为样本展示
    var asSample: Bool = false
    
    // MARK: - Instance Method
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUserInterface()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Private Method
    private func setupUserInterface() {
        // Style
        contentView.backgroundColor = UIColor(named: .CardBackground)
        
        // SubViews
        contentView.addSubview(layoutView)
        
        
        // Autolayout
        layoutView.snp.makeConstraints { (maker) in
            maker.top.equalTo(contentView).offset(6)
            maker.left.equalTo(contentView).offset(6)
            maker.bottom.equalTo(contentView).offset(-6)
            maker.right.equalTo(contentView).offset(-6)
        }
    }
}
