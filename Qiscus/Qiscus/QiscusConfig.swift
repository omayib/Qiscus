//
//  QiscusConfig.swift
//  LinkDokter
//
//  Created by Qiscus on 3/2/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit

open class QiscusConfig: NSObject {
    
    static let sharedInstance = QiscusConfig()
    
    open var commentPerLoad:Int = 10
    open var BASE_URL = "https://halodoc-messaging-dev.linkdokter.com/"
    open var UPLOAD_URL = "https://qvc-engine-staging.herokuapp.com/files/upload"
    open var USER_EMAIL = "ahmad.athaullah@gmail.com"
    open var USER_TOKEN = ""
    
    open var requestHeader:[String:String]? = nil
    
    fileprivate override init() {}
    
    open class var postCommentURL:String{
        get{
            let config = QiscusConfig.sharedInstance
            return "\(config.BASE_URL)/postcomment"
        }
    }
    
    // MARK: -URL With parameter
//    public class func SYNC_URL(topicId:Int, commentId:Int)->String{
//        let config = QiscusConfig.sharedInstance
//        return "\(config.BASE_URL)/topic_c/\(topicId)/comment/\(commentId)/token/\(config.USER_TOKEN)?after=true"
//    }
    open class var LOAD_URL:String{
        let config = QiscusConfig.sharedInstance
        //return "\(config.BASE_URL)/topic/\(topicId)/comment/\(commentId)/token/\(config.USER_TOKEN)"
        return "\(config.BASE_URL)/topic_comments/"
    }
}
