//
//  SingleAbilityData.swift
//  mala-ios
//
//  Created by 王新宇 on 16/5/31.
//  Copyright © 2016年 Mala Online. All rights reserved.
//

import UIKit

class SingleAbilityData: NSObject {
    
    // MARK: - Property
    /// 能力名称（简略）
    var key: String = ""
    /// 数值
    var val: Int = 0 {
        didSet {
            if val == 0 {
                val = 1
            }
        }
    }
    /// 能力
    var ability: MalaStudyReportAbility {
        get {
            return MalaStudyReportAbility(rawValue: key) ?? .unkown
        }
    }
    /// 能力字符串
    var abilityString: String {
        get {
            switch ability {
            case .abstract:
                return "抽象概括"
                
            case .reason:
                return "推理论证"
                
            case .appl:
                return "实际应用"
                
            case .spatial:
                return "空间想象"
                
            case .calc:
                return "运算求解"
                
            case .data:
                return "数据分析"
                
            case .unkown:
                return ""
            }
        }
    }
    
    
    // MARK: - Constructed
    override init() {
        super.init()
    }
    
    init(dict: [String: AnyObject]) {
        super.init()
        setValuesForKeys(dict)
    }
    
    
    convenience init(key: String, value: Int) {
        self.init()
        self.key = key
        self.val = value
    }
}
