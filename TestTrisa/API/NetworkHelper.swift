//
//  NetworkHelper.swift
//  TRISAAPI
//
//  Created by CVN on 22/01/19.
//  Copyright © 2019 Agiliztech. All rights reserved.
//

import Foundation
import UIKit 
import Alamofire

let API_HEADER_FIELD_NONE_MATCH             : String    = "If-None-Match"
let API_HEADER_FIELD_ETAG                   : String    = "Etag"
let API_REQUEST_SUCCESS                     : Int       = 200
let API_REQUEST_CACHED                      : Int       = 304

public class Connectivity {
    class var isConnectedToInternet:Bool {
        return NetworkReachabilityManager()!.isReachable
    }
}
public class NetworkHelper: NSObject {
    
    open var useEtagInHeader = false
    public static let sharedInstance = NetworkHelper()
    public let imageCache = NSCache <NSString, UIImage>()
    
    
    /// Generic function for get request
    ///
    /// Neet to pass Model class for api andkey for local storage
    
    public func callGetRequest<T: Codable>(strUrl:String,paramsDict:[String : Any],userToken:String?, andkey:String, completion: @escaping (T,Bool) -> () , failureBlock:@escaping (String) ->()) {
        
        var headers:HTTPHeaders? = nil
        
        // add etag in header
        
        if let etag = self.ETagForURL(urlString: strUrl) , useEtagInHeader == true {
            headers = [
                // "token": userToken?.count ?? 0 > 0 ? userToken ?? "" : "",
                API_HEADER_FIELD_NONE_MATCH:etag,
                "Authorization" : "Bearer         eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOjE0MDMsImlzcyI6Imh0dHA6XC9cLzM0LjIwMy4xNC43OVwvYXBpXC92M1wvdXNlclwvbG9naW4uanNvbiIsImlhdCI6MTU0OTI3NDcxMSwiZXhwIjoxNzI5Mjc0NzExLCJuYmYiOjE1NDkyNzQ3MTEsImp0aSI6ImJEcTVGMkszWG9XVGg3a3AifQ.FZDKAfplGHyE-ny7Eu7ezgDNbiJn_CVgl7I1LifkkU4"
            ]
        }
        if !Connectivity.isConnectedToInternet {
            print("API callGetRequest in no internet connection ")
            let info = Storage.retrieve(andkey, from: .caches, as: T.self)
            completion(info, true)
        }
        Alamofire.request(strUrl,method: .get, parameters: paramsDict, encoding: Alamofire.URLEncoding.default, headers: headers).responseJSON
            {(response) in
             
                guard let statusCode = response.response?.statusCode else {
                   
                    return
                }
                
                 let json = try? JSONDecoder().decode(T.self, from: response.data!)
                
                switch statusCode{
                case 200...299:
                    print("API callGetRequest in 200 ")
                    if (response.error == nil && response.data != nil) {
                        debugPrint(response.result)
                        // Update Etag
                        self .updateETag(urlResponse: response.response)
                        
                       
                        
                        guard let result:T = json else { return }
                        Storage.store(result, to: .caches, as: andkey)
                        completion(result, false)
                        
                    }
                    break
                
                case API_REQUEST_CACHED:
                    print("API callGetRequest in 304 ")
                    let info = Storage.retrieve(andkey, from: .caches, as: T.self)
                    completion(info, false)
                    break
                    
                case 401...499:
                    print("API callGetRequest in 401 ")
                    debugPrint(response.result)
                    // Update Etag
                    self .updateETag(urlResponse: response.response)
                    guard let result:T = json else { return }
                    //Storage.store(result, to: .caches, as: andkey)
                    completion(result, false)
                    
                    break
                    
                case 500...599:
                    print("API callGetRequest in 500 ")
                    if self.useEtagInHeader && Session.sharedInstance.getEtagForRequest(key: andkey).count > 0{
                        let info = Storage.retrieve(andkey, from: .caches, as: T.self)
                        completion(info, false)
                    }
                    debugPrint("ErrorResult ==>",response.error?.localizedDescription ?? "NO Error")
                    failureBlock("Server error")
                    break
                    
                default:
                    break
                }
                
//                if (response.response?.statusCode == API_REQUEST_SUCCESS && response.error == nil && response.data != nil) {
//                    debugPrint(response.result)
//                    // Update Etag
//                    self .updateETag(urlResponse: response.response)
//
//                    let json = try? JSONDecoder().decode(T.self, from: response.data!)
//
//                    guard let result:T = json else { return }
//                    Storage.store(result, to: .caches, as: andkey)
//                    completion(result)
//
//                }
//                else if (response.response?.statusCode == API_REQUEST_CACHED) {
//                    let info = Storage.retrieve(andkey, from: .caches, as: T.self)
//                    completion(info)
//                }
//                else if response.result.isFailure {
//                    if self.useEtagInHeader && Session.sharedInstance.getEtagForRequest(key: andkey).count > 0{
//                        let info = Storage.retrieve(andkey, from: .caches, as: T.self)
//                        completion(info)
//                    }
//                    debugPrint("ErrorResult ==>",response.error?.localizedDescription ?? "NO Error")
//                    failureBlock("Server error")
//                }
        }
    }
    
    public func callGetApiForArrayResp<T: Codable>(strUrl:String,paramsDict:[String : Any],userToken:String?, andkey:String, completion: @escaping ([T],Bool) -> () , failureBlock:@escaping (String) ->()) {
        
        var headers:HTTPHeaders? = nil
        if useEtagInHeader == true {
            headers = [
                "token": userToken?.count ?? 0 > 0 ? userToken ?? "" : "",
                "If-None-Match":Session.sharedInstance.getEtagForRequest(key: andkey)
            ]
        }
        if !Connectivity.isConnectedToInternet {
            print("API callGetApiForArrayResp in no internet connection ")
            let comments = Storage.retrieve(andkey, from: .caches, as: [T].self)
            completion(comments,true)
        }
        Alamofire.request(strUrl,method: .get, parameters: paramsDict, encoding: Alamofire.URLEncoding.default, headers: headers).responseJSON
            {(response) in
                
                if response.result.isSuccess {
                    debugPrint(response.result)
                     print("API callGetApiForArrayResp isSuccess ")
                    // get and save etag from header
                    let Etag =  response.response?.allHeaderFields["Etag"] as? String
                    if let etag = Etag {
                        Session.sharedInstance.setEtagForRequest(key: andkey, etag: etag)
                    }
                    
                    let json = try? JSONDecoder().decode([T].self, from: response.data!)
                    
                    guard let result:[T] = json else { return }
                    Storage.store(result, to: .caches, as: andkey)
                    completion(result, false)
                }
                    
                else if response.result.isFailure {
                    print("API callGetApiForArrayResp isSucceisFailure ")
                    debugPrint("ErrorResult ==>",response.error?.localizedDescription ?? "NO Error")
                    if self.useEtagInHeader && Session.sharedInstance.getEtagForRequest(key: andkey).count > 0 {
                        let info = Storage.retrieve(andkey, from: .caches, as: [T].self)
                        completion(info, false)
                    }
                    failureBlock("Server error")
                }
                
        }
    }
    public func callPostApi<T: Codable>(strUrl:String,dictParameters:[String : Any],userToken:String?, andkey:String, completion: @escaping (T,Bool) -> () , failureBlock:@escaping (String) ->()) {
        
        var headers:HTTPHeaders? = nil
        if userToken?.count ?? 0 > 0 {
            headers = (["Content-Type" : "application/json; charset=utf-8","token": userToken,"language":"en"] as! HTTPHeaders)
        }
        
        if !Connectivity.isConnectedToInternet {
             print("API callPostApi in no internet connection ")
            let info = Storage.retrieve(andkey, from: .caches, as: T.self)
            completion(info, true)
        }
        debugPrint("APICall ==>\(strUrl)? \(self.paramToJson(params: headers)) \(self.paramToJson(params: dictParameters))")
        
        
        Alamofire.request(strUrl, method : .post, parameters : dictParameters, encoding : JSONEncoding.default , headers : headers).responseData {
            (dataResponse) in
            
            print(dataResponse.request as Any) // your request
            print(dataResponse.response as Any) // your response
            print(dataResponse.result.value as Any) // your response
            
            if dataResponse.result.isSuccess {
                print("API callPostApi isSuccess")
                debugPrint(dataResponse.result)
                let json = try? JSONDecoder().decode(T.self, from: dataResponse.data!)
                
                guard let result:T = json else { return }
                Storage.store(result, to: .caches, as: andkey)
                completion(result, false)
            }
                
            else if dataResponse.result.isFailure {
                print("API callPostApi isFailure")
                debugPrint("ErrorResult ==>",dataResponse.error?.localizedDescription ?? "NO Error")
                failureBlock("Server error")
            }
        }
        
    }
    public func callPostApiForArrayResp<T: Codable>(strUrl:String,dictParameters:[String : Any],userToken:String?, andkey:String, completion: @escaping ([T],Bool) -> () , failureBlock:@escaping (String) ->()) {
        
        var headers:HTTPHeaders? = nil
        if userToken?.count ?? 0 > 0 {
            headers = (["Content-Type" : "application/json; charset=utf-8","token": userToken,"language":"en"] as! HTTPHeaders)
        }
        
        if !Connectivity.isConnectedToInternet {
             print("API callPostApiForArrayResp in no internet connection ")
            let comments = Storage.retrieve(andkey, from: .caches, as: [T].self)
            completion(comments, true)
        }
        debugPrint("APICall ==>\(strUrl)? \(self.paramToJson(params: headers)) \(self.paramToJson(params: dictParameters))")
        
        
        Alamofire.request(strUrl, method : .post, parameters : dictParameters, encoding : JSONEncoding.default , headers : headers).responseData {
            (dataResponse) in
            
            print(dataResponse.request as Any) // your request
            print(dataResponse.response as Any) // your response
            print(dataResponse.result.value as Any) // your response
            
            if dataResponse.result.isSuccess {
                print("API callPostApiForArrayResp isSuccess")
                debugPrint(dataResponse.result)
                let json = try? JSONDecoder().decode([T].self, from: dataResponse.data!)
                
                guard let result:[T] = json else { return }
                Storage.store(result, to: .caches, as: andkey)
                completion(result, false)
            }
                
            else if dataResponse.result.isFailure {
                print("API callPostApiForArrayResp isFailure")
                debugPrint("ErrorResult ==>",dataResponse.error?.localizedDescription ?? "NO Error")
                failureBlock("Server error")
            }
        }
        
    }
    
    // MARK:- set and Get Etag
    
    func ETagForURL(urlString: String) -> String? {
        // return the saved ETag value for the given URL
        return Session.sharedInstance.getEtagForRequest(key: urlString)
    }
    
    func updateETag(urlResponse: URLResponse!) {
        if let httpResponse = urlResponse as? HTTPURLResponse {
            if let urlString = httpResponse.url?.absoluteString {
                if let etag = httpResponse.allHeaderFields[API_HEADER_FIELD_ETAG] as? String {
                    // save the etag header value with the url as a key.
                    let validEtag = etag.replacingOccurrences(of: "\"", with: "")
                    let spacedRemoevedEtag = validEtag.trimmingCharacters(in: .whitespaces)
                    
                    Session.sharedInstance.setEtagForRequest(key: urlString, etag: spacedRemoevedEtag)
                }
            }
        }
    }
    
    private func paramToJson(params:[String:Any]?) -> String {
        if params != nil{
            let data = try? JSONSerialization.data(withJSONObject: params ?? ["":""], options: .prettyPrinted)
            return String(data: data!, encoding: .utf8)!
        }
        return ""
    }
    
    
}
