//
//  OrderFormTimeScheduleCell.swift
//  mala-ios
//
//  Created by 王新宇 on 16/5/13.
//  Copyright © 2016年 Mala Online. All rights reserved.
//

import UIKit

class OrderFormTimeScheduleCell: UITableViewCell {

    // MARK: - Property
    /// 课时
    var classPeriod: Int = 0 {
        didSet {
            periodLabel.text = String(format: "%d", classPeriod)
        }
    }
    /// 上课时间列表
    var timeSchedules: [[TimeInterval]]? {
        didSet {
            if timeSchedules != nil {
                parseTimeSchedules()
            }
        }
    }
    /// 是否隐藏时间表（默认隐藏）
    var shouldHiddenTimeSlots: Bool = true {
        didSet {
            self.timeLineView?.isHidden = shouldHiddenTimeSlots
        }
    }
    
    
    // MARK: - Components
    /// 布局容器
    private lazy var content: UIView = {
        let view = UIView(UIColor.white)
        return view
    }()
    /// 顶部布局容器
    private lazy var topLayoutView: UIView = {
        let view = UIView()
        return view
    }()
    /// 分割线
    private lazy var separatorLine: UIView = {
        let view = UIView(MalaColor_E5E5E5_0)
        return view
    }()
    /// 图标
    private lazy var iconView: UIView = {
        let view = UIView(MalaColor_82B4D9_0)
        return view
    }()
    /// cell标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel(
            text: "上课时间",
            fontSize: 15,
            textColor: MalaColor_333333_0
        )
        return label
    }()
    /// 课时
    private lazy var periodLabel: UILabel = {
        let label = UILabel(
            text: "0",
            fontSize: 13,
            textColor: MalaColor_333333_0
        )
        return label
    }()
    private lazy var periodLeftLabel: UILabel = {
        let label = UILabel(
            text: "共计",
            fontSize: 13,
            textColor: MalaColor_6C6C6C_0
        )
        return label
    }()
    private lazy var periodRightLabel: UILabel = {
        let label = UILabel(
            text: "课时",
            fontSize: 13,
            textColor: MalaColor_6C6C6C_0
        )
        return label
    }()
    /// 上课时间表控件
    private  var timeLineView: ThemeTimeLine?
    
    
    // MARK: - Contructed
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUserInterface()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Private Method
    private func setupUserInterface() {
        // Style
        contentView.backgroundColor = MalaColor_EDEDED_0
        
        // SubViews
        contentView.addSubview(content)
        content.addSubview(topLayoutView)
        topLayoutView.addSubview(separatorLine)
        topLayoutView.addSubview(iconView)
        topLayoutView.addSubview(titleLabel)
        
        topLayoutView.addSubview(periodRightLabel)
        topLayoutView.addSubview(periodLabel)
        topLayoutView.addSubview(periodLeftLabel)
        
        // Autolayout
        content.snp.makeConstraints { (maker) in
            maker.top.equalTo(contentView)
            maker.left.equalTo(contentView).offset(12)
            maker.right.equalTo(contentView).offset(-12)
            maker.bottom.equalTo(contentView)
        }
        topLayoutView.snp.makeConstraints { (maker) in
            maker.top.equalTo(content)
            maker.left.equalTo(content)
            maker.right.equalTo(content)
            maker.height.equalTo(35)
            maker.bottom.equalTo(content).offset(-12)
        }
        separatorLine.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(topLayoutView)
            maker.left.equalTo(topLayoutView)
            maker.right.equalTo(topLayoutView)
            maker.height.equalTo(MalaScreenOnePixel)
        }
        iconView.snp.makeConstraints { (maker) in
            maker.left.equalTo(topLayoutView)
            maker.centerY.equalTo(topLayoutView)
            maker.height.equalTo(19)
            maker.width.equalTo(3)
        }
        titleLabel.snp.updateConstraints { (maker) -> Void in
            maker.centerY.equalTo(topLayoutView)
            maker.left.equalTo(topLayoutView).offset(12)
            maker.height.equalTo(15)
        }
        periodRightLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(topLayoutView)
            maker.right.equalTo(topLayoutView).offset(-12)
            maker.height.equalTo(13)
        }
        periodLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(topLayoutView)
            maker.right.equalTo(periodRightLabel.snp.left).offset(-5)
            maker.height.equalTo(13)
        }
        periodLeftLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(topLayoutView)
            maker.right.equalTo(periodLabel.snp.left).offset(-5)
            maker.height.equalTo(13)
        }
    }
    
    private func parseTimeSchedules() {
        
        // 解析时间表数据
        let result = parseTimeSlots((self.timeSchedules ?? []))
        
        // 设置UI
        self.timeLineView = ThemeTimeLine(times: result.dates, descs: result.times)
        timeLineView?.isHidden = true
        
        self.contentView.addSubview(timeLineView!)
        topLayoutView.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(timeLineView!.snp.top).offset(-10)
        }
        timeLineView!.snp.makeConstraints { (maker) in
            maker.top.equalTo(topLayoutView.snp.bottom).offset(10)
            maker.left.equalTo(content).offset(12)
            maker.right.equalTo(content).offset(-12)
            maker.bottom.equalTo(content).offset(-16)
            maker.height.equalTo(result.height)
        }
    }
}
