//
//  ThemeTags.swift
//  mala-ios
//
//  Created by 王新宇 on 1/19/16.
//  Copyright © 2016 Mala Online. All rights reserved.
//

import UIKit

class ThemeTags: UIView {
    
    
    enum TagsArray {
        case higherArray
        case lowerArray
    }
    
    // MARK: - Property
    /// 按钮字典
    var buttons: [String: UIButton] = [String: UIButton]()
    /// 标签高度
    var itemHeight: CGFloat = 26
    /// 水平间距
    var verticalMargin: CGFloat = 7
    /// 垂直间距
    var horizontalMargin: CGFloat = 7
    /// 折行字数临界值
    var critical: Int = 4
    /// [不限] 按钮
    var allButton: UIButton? {
        get {
            return self.subviews[0] as? UIButton
        }
    }
    /// 字数小于临界值-字符串数组
    private var lowerArray: [String] = []
    /// 字数较少标签--每行最大个数
    var numbersForLowerInRow: Int = 3
    /// 字数大于临界值-字符串数组
    private var higherArray: [String] = []
    /// 字数较多标签--每行最大个数
    var numbersForHigherInRow: Int = 2
    /// 标签字符串数组
    var tags: [String]? {
        didSet {
            // 遍历数组，过滤出高、低临界值数组
            tags?.insert("不限", at: 0)
            for string in tags ?? [] {
                string.characters.count <= critical ? lowerArray.append(string) : higherArray.append(string)
            }
            self.layoutTags()
        }
    }
    // 当前选中项字符串数组
    private(set) var selectedItems: [String] = MalaFilterIndexObject.tags
    // 当前布局高度
    private var currentHeight: CGFloat = 0
    // 当前布局宽度
    private var currentWidth: CGFloat = 0
    // 小标签宽度
    private var lowWidth: CGFloat {
        get {
            return (self.frame.width - 1 - verticalMargin*2) / 3
        }
    }
    // 大标签宽度
    private var highWidth: CGFloat {
        get {
            return (self.frame.width - 1 - verticalMargin) / 2
        }
    }
    

    // MARK: - Contructed
    init(frame: CGRect, tags: [String]) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        self.tags = tags
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    // MARK: - Private Method
    private func layoutTags() {
        // 将两数组可整行显示的标签，进行排列布局显示
        layoutFillRowWithArray(.lowerArray)
        layoutFillRowWithArray(.higherArray)
        
        // 排列显示低于临界值数组 剩余标签
        // 若两数组均剩余一字符串，则同行显示，否则分行显示。
        if lowerArray.count == 1 {
            layoutRemainder(.lowerArray)
        }else {
            layoutRemainder(.lowerArray)
            currentHeight += horizontalMargin + itemHeight
            currentWidth = 0
        }
        
        // 排列显示高于临界值数组 剩余标签
        layoutRemainder(.higherArray)
//        self.allButton?.selected = true
    }
    
    ///  将指定数组的可整行排列的标签，进行显示
    ///
    ///  - parameter arrayType: 数组类型
    private func layoutFillRowWithArray(_ arrayType: TagsArray) {
        let numbers = arrayType == .higherArray ? numbersForHigherInRow : numbersForLowerInRow
        repeat {
            for _ in 1...numbers {
                arrayType == .higherArray ? setupItem(.higherArray) : setupItem(.lowerArray)
            }
            currentHeight += horizontalMargin + itemHeight
            currentWidth = 0
        } while (arrayType == .higherArray ? higherArray : lowerArray).count >= numbers
    }
    
    ///  排列指定数组余下的标签
    ///
    ///  - parameter array: 标签数组
    private func layoutRemainder(_ arrayType: TagsArray) {
        for _ in (arrayType == .higherArray ? higherArray : lowerArray) {
            setupItem(arrayType)
        }
    }
    
    ///  排列指定数组中的第一个标签
    ///
    ///  - parameter arrayType: 数组类型
    private func setupItem(_ arrayType: TagsArray) {
        let buttonWidth = arrayType == .higherArray ? highWidth : lowWidth
        // 创建一个标签并布局、设置变量之后，从数组中remove这个标签文字
        let title = (arrayType == .higherArray ? higherArray : lowerArray)[0]
        let button = UIButton(
            title: title,
            borderColor: MalaRandomColor(),
            target: self,
            action: #selector(ThemeTags.buttonDidTap(_:))
        )
        button.setTitleColor(UIColor(named: .HeaderTitle), for: .normal)
        self.addSubview(button)
        self.buttons[title] = button
        
        // 若此风格标签已被选中，则渲染选中样式
        if MalaFilterIndexObject.tags.contains(title) {
            button.isSelected = true
        }
        
        // 每行首个按钮无Margin
        let x = currentWidth == 0 ? currentWidth+1 : currentWidth + verticalMargin
        button.frame = CGRect(x: x, y: currentHeight, width: buttonWidth, height: itemHeight)
        currentWidth = (button.frame).maxX
        if arrayType == .higherArray {
            higherArray.remove(at: 0)
        }else if arrayType == .lowerArray {
            lowerArray.remove(at: 0)
        }
    }
    
    
    // MARK: - Event Response
    @objc private func buttonDidTap(_ sender: UIButton) {
        sender.isHighlighted = !sender.isHighlighted
        sender.isSelected = !sender.isSelected
        
        if sender == allButton {
            // 点击[不限]按钮
            for button in self.subviews {
                (button as? UIButton)?.isSelected = false
            }
            allButton?.isSelected = true
            selectedItems = []
        }else {
            // 点击其他按钮
            allButton?.isSelected = false
            // 处理选中字符串
            let string = sender.titleLabel!.text!
            let stringIndex = selectedItems.index(of: string)
            if stringIndex == nil {
                selectedItems.append(string)
            }else {
                selectedItems.remove(at: stringIndex!)
            }
        }
    }
}
