//
//  Qiscus.swift
//  qonsultant
//
//  Created by Ahmad Athaullah on 7/17/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit

open class Qiscus: NSObject {
    open static let sharedInstance = Qiscus()
    
    open var config = QiscusConfig.sharedInstance
    open var commentService = QiscusCommentClient.sharedInstance
    
    open class var commentService:QiscusCommentClient{
        get{
            return QiscusCommentClient.sharedInstance
        }
    }
    
    fileprivate override init() {}
    
    
    open class func setConfiguration(_ baseURL:String, uploadURL: String, userEmail:String, userToken:String, commentPerLoad:Int! = 10, headers: [String:String]? = nil){
        let config = QiscusConfig.sharedInstance
        
        config.BASE_URL = baseURL
        config.UPLOAD_URL = uploadURL
        config.USER_EMAIL = userEmail
        config.USER_TOKEN = userToken
        config.commentPerLoad = commentPerLoad
        config.requestHeader = headers
    }
}
