//
//  String+extension.swift
//  LocalizationDemo
//
//  Created by CVN on 24/12/18.
//  Copyright © 2018 Agiliztech. All rights reserved.
//

import Foundation
import UIKit

extension String {
    public func localizedString(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        return NSLocalizedString(self, tableName: tableName, value: "**\(self)**", comment: "")
    }
}

var bundleKey: UInt8 = 0

public class AnyLanguageBundle: Bundle {
    
    override public func localizedString(forKey key: String,
                                  value: String?,
                                  table tableName: String?) -> String {
        
        guard let path = objc_getAssociatedObject(self, &bundleKey) as? String,
            let bundle = Bundle(path: path) else {
                
                return super.localizedString(forKey: key, value: value, table: tableName)
        }
        
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    
   public class func setLanguage(_ language: String) {
        
        defer {
            
            object_setClass(Bundle.main, AnyLanguageBundle.self)
        }
        
        objc_setAssociatedObject(Bundle.main, &bundleKey,    Bundle.main.path(forResource: language, ofType: "lproj"), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
