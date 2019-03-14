//
//  Session.swift
//  AgilizTechTemplate
//
//  Created by CVN on 16/12/18.
//  Copyright © 2018 Agiliztech. All rights reserved.
//

import Foundation
import UIKit

class Session: NSObject {
    
    static let sharedInstance: Session = {
        
        let instance = Session()
        
        // setup code
        
        return instance
    }()
    
    
    // MARK: - Shared Methods
    
    func setUserToken(aStrUserToken : String) {
        
        UserDefaults.standard.set(aStrUserToken, forKey: "user_Token")
        userdefaultsSynchronize()
    }
    
    func getUserToken() -> String {
        
        
        if let token = UserDefaults.standard.string(forKey: "user_Token") {
            return token
        }
        return ""
    }
    
    func setAppLaunchIsFirstTime(isLogin : Bool) {
        
        
        UserDefaults.standard.set(isLogin, forKey: "app_launch_first_time")
        userdefaultsSynchronize()
    }
    
    func IsAppLaunchFirstTime() -> Bool {
        
        if  UserDefaults.standard.object(forKey: "app_launch_first_time") == nil {
            
            return true
        }
        
        return UserDefaults.standard.bool(forKey: "app_launch_first_time")
    }
    
    // Etag
    func setEtagForRequest(key : String, etag: String) {
        
        UserDefaults.standard.set(etag, forKey: key)
        userdefaultsSynchronize()
    }
    
    func getEtagForRequest(key : String) -> String {
        
        
        if let Etag = UserDefaults.standard.string(forKey: key) {
            return Etag
        }
        return ""
    }
    
    private func userdefaultsSynchronize() {
        
        UserDefaults.standard.synchronize()
    }
    
}
