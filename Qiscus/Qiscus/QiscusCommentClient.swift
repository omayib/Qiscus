//
//  QiscusCommentClient.swift
//  QiscusSDK
//
//  Created by ahmad athaullah on 7/17/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import Foundation
import UIKit
import PusherSwift
import Alamofire
import AlamofireImage
import SwiftyJSON
import AVFoundation
import Photos

let qiscus = Qiscus.sharedInstance

open class QiscusCommentClient: NSObject {
    open static let sharedInstance = QiscusCommentClient()
    
    open var commentDelegate: QCommentDelegate?
    open var roomDelegate: QiscusRoomDelegate?
    
    // MARK: - Comment Methode
    open func postMessage(message: String, topicId: Int, roomId:Int? = nil){ //USED
        let comment = QiscusComment.newCommentWithMessage(message: message, inTopicId: topicId)
        self.postComment(comment, roomId: roomId)
        self.commentDelegate?.gotNewComment([comment])
    }
    open func postComment(_ comment:QiscusComment, file:QiscusFile? = nil, roomId:Int? = nil){ //USED
        
        var parameters:Parameters = [
            "comment"  : comment.commentText,
            "topic_id" : comment.commentTopicId,
            "unique_id" : comment.commentUniqueId
        ]
        
        if QiscusConfig.sharedInstance.requestHeader == nil{
            parameters["token"] = qiscus.config.USER_TOKEN
        }
        
        if roomId != nil {
            parameters["room_id"] = roomId
        }
        
        let headers: HTTPHeaders = QiscusConfig.sharedInstance.requestHeader ?? [:]

        DispatchQueue.global(qos: .default).async {
            Alamofire.request(QiscusConfig.postCommentURL, method: .post, parameters: parameters, headers: headers)
            .responseJSON { response in
                switch response.result {
                    case .success:
                        DispatchQueue.main.async {
                            if let result = response.result.value {
                                let json = JSON(result)
                                let success = json["success"].boolValue
                                
                                if success == true {
                                    comment.updateCommentId(json["comment_id"].intValue)
                                    comment.updateCommentStatus(QiscusCommentStatus.sent)
                                    let commentBeforeid = QiscusComment.getCommentBeforeIdFromJSON(json)
                                    if(QiscusComment.isValidCommentIdExist(commentBeforeid)){
                                        comment.updateCommentIsSync(true)
                                    }else{
                                        self.syncMessage(comment.commentTopicId)
                                    }
                                    
                                    self.commentDelegate?.didSuccesPostComment(comment)
                                    
                                    if file != nil {
                                        let thisComment = QiscusComment.getCommentByLocalId(comment.localId)
                                        if(file != nil){
                                            file?.updateCommentId(thisComment!.commentId)
                                        }
                                        
                                        self.commentDelegate?.didSuccessPostFile(comment)
                                    }
                                }
                            }else{
                                comment.updateCommentStatus(QiscusCommentStatus.failed)
                                self.commentDelegate?.didFailedPostComment(comment)
                                
                                if file != nil{
                                    let thisComment = QiscusComment.getCommentByLocalId(comment.localId)
                                    if(file != nil){
                                        file?.updateCommentId(thisComment!.commentId)
                                    }
                                    self.commentDelegate?.didFailedPostFile(comment)
                                }
                            }
                        }
                        break
                    case .failure(_):
                        DispatchQueue.main.async {
                            comment.updateCommentStatus(QiscusCommentStatus.failed)
                            self.commentDelegate?.didFailedPostComment(comment)
                            if file != nil{
                                let thisComment = QiscusComment.getCommentByLocalId(comment.localId)
                                if(file != nil){
                                    file?.updateCommentId(thisComment!.commentId)
                                }
                                self.commentDelegate?.didFailedPostFile(comment)
                        }
                    }
                }
            }
        }
    }
    
    open func downloadMedia(_ comment:QiscusComment){
        let headers: HTTPHeaders = QiscusConfig.sharedInstance.requestHeader ?? [:]
        let file = QiscusFile.getCommentFile(comment.commentFileId)!
        file.updateIsDownloading(true)
        
        Alamofire.request(file.fileURL, headers: headers)
            .downloadProgress { (progress) in
                print("Download progress: \(progress)")
                
                file.updateDownloadProgress(progress.fractionCompleted)
                self.commentDelegate?.downloadingMedia(comment)
            }
            .responseData { response in
                if let fileData = response.data {
                    if let image:UIImage = UIImage(data: fileData) {
                        var thumbImage = UIImage()
                        if !(file.fileExtension == "gif" || file.fileExtension == "gif_"){
                            thumbImage = QiscusFile.createThumbImage(image)
                        }
                        DispatchQueue.main.async {
                            file.updateDownloadProgress(1.0)
                            file.updateIsDownloading(false)
                        }
                        print("Download finish")
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
                        let path = "\(documentsPath)/\(file.fileName)"
                        let pathURL = URL(fileURLWithPath: path)
                        let thumbPath = "\(documentsPath)/thumb_\(file.fileName as String)"
                        let thumbPathURL = URL(fileURLWithPath: thumbPath)
                        
                        if (file.fileExtension == "png" || file.fileExtension == "png_") {
                            try! UIImagePNGRepresentation(image)?.write(to: pathURL)
                            try! UIImagePNGRepresentation(thumbImage)?.write(to: thumbPathURL)
                        } else if(file.fileExtension == "jpg" || file.fileExtension == "jpg_"){
                            try! UIImageJPEGRepresentation(image, 1.0)?.write(to: pathURL)
                            try! UIImageJPEGRepresentation(thumbImage, 1.0)?.write(to: thumbPathURL)
                        } else if(file.fileExtension == "gif" || file.fileExtension == "gif_"){
                            try! fileData.write(to: pathURL)
                            try! fileData.write(to: thumbPathURL)
                            thumbImage = image
                        }
                        
                        DispatchQueue.main.async {
                            file.updateLocalPath(path)
                            file.updateThumbPath(thumbPath)
                            
                            self.commentDelegate?.didDownloadMedia(comment)
                        }
                        
                    }else{
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
                        let path = "\(documentsPath)/\(file.fileName)"
                        let pathURL = URL(fileURLWithPath: path)
                        let thumbPath = "\(documentsPath)/thumb_\(file.fileCommentId).png"
                        let thumbPathURL = URL(fileURLWithPath: thumbPath)
                        
                        try! fileData.write(to: pathURL)
                        
                        let assetMedia = AVURLAsset(url: pathURL)
                        let thumbGenerator = AVAssetImageGenerator(asset: assetMedia)
                        thumbGenerator.appliesPreferredTrackTransform = true
                        
                        let thumbTime = CMTimeMakeWithSeconds(0, 30)
                        let maxSize = CGSize(width: file.screenWidth, height: file.screenWidth)
                        thumbGenerator.maximumSize = maxSize
                        
                        do {
                            let thumbRef = try thumbGenerator.copyCGImage(at: thumbTime, actualTime: nil)
                            let thumbImage = UIImage(cgImage: thumbRef)
                            let thumbData = UIImagePNGRepresentation(thumbImage)
                            try thumbData?.write(to: thumbPathURL)
                        } catch {
                            print("error creating thumb image")
                        }
                        
                        DispatchQueue.main.async {
                            file.updateDownloadProgress(1.0)
                            file.updateIsDownloading(false)
                            file.updateLocalPath(path)
                            file.updateThumbPath(thumbPath)
                            self.commentDelegate?.didDownloadMedia(comment)
                        }
                    }
                }
        }
    }
    open func uploadImage(_ topicId: Int,image:UIImage?,imageName:String,imagePath:URL? = nil, imageNSData:Data? = nil, roomId:Int? = nil){
        var imageData:Data = Data()
        if imageNSData != nil {
            imageData = imageNSData!
        }
        var thumbData:Data = Data()
        var imageMimeType:String = ""
        print("imageName: \(imageName)")
        let imageNameArr = imageName.characters.split(separator: ".")
        let imageExt:String = String(imageNameArr.last!).lowercased()
        let comment = QiscusComment.newCommentWithMessage(message: "", inTopicId: topicId)
        
        if image != nil {
            var thumbImage = UIImage()
            print("\(imageName) --- \(imageExt) -- \(imageExt != "gif")")
            
            let isGifImage:Bool = (imageExt == "gif" || imageExt == "gif_")
            let isJPEGImage:Bool = (imageExt == "jpg" || imageExt == "jpg_")
            let isPNGImage:Bool = (imageExt == "png" || imageExt == "png_")
            
            print("\(imagePath)")
            
            if !isGifImage{
                thumbImage = QiscusFile.createThumbImage(image!)
            }

            if isJPEGImage == true{
                let imageSize = image!.size
                let bigPart = imageSize.width > imageSize.height ? imageSize.width : imageSize.height
                
                var compressVal = CGFloat(1)
                if bigPart > 2000 {
                    compressVal = 2000 / bigPart
                }
                
                imageData = UIImageJPEGRepresentation(image!, compressVal)!
                thumbData = UIImageJPEGRepresentation(thumbImage, 1)!
                imageMimeType = "image/jpg"
            }else if isPNGImage == true{
                imageData = UIImagePNGRepresentation(image!)!
                thumbData = UIImagePNGRepresentation(thumbImage)!
                imageMimeType = "image/png"
            }else if isGifImage == true{
                if imageNSData == nil{
                    let asset = PHAsset.fetchAssets(withALAssetURLs: [imagePath!], options: nil)
                    if let phAsset = asset.firstObject {
                        
                        let option = PHImageRequestOptions()
                        option.isSynchronous = true
                        option.isNetworkAccessAllowed = true
                        PHImageManager.default().requestImageData(for: phAsset, options: option) {
                            (data, dataURI, orientation, info) -> Void in
                            imageData = data!
                            thumbData = data!
                            imageMimeType = "image/gif"
                        }
                    }
                }else{
                    imageData = imageNSData!
                    thumbData = imageNSData!
                    imageMimeType = "image/gif"
                }
            }
        }else{
            if let mime:String = QiscusFileHelper.mimeTypes["\(imageExt)"] {
                imageMimeType = mime
                print("mime: \(mime)")
            }
        }
        let imageThumbName = "thumb_\(comment.commentUniqueId).\(imageExt)"
        let fileName = "\(comment.commentUniqueId).\(imageExt)"
        
        let commentFile = QiscusFile()
        if image != nil {
            commentFile.fileLocalPath = QiscusFile.saveFile(imageData, fileName: fileName)
            commentFile.fileThumbPath = QiscusFile.saveFile(thumbData, fileName: imageThumbName)
        }else{
            commentFile.fileLocalPath = imageName
        }
        commentFile.fileTopicId = topicId
        commentFile.isUploading = true
        commentFile.uploaded = false
        commentFile.saveCommentFile()
        
        comment.updateCommentText("[file]\(fileName) [/file]")
        comment.updateCommentFileId(commentFile.fileId)
        
        commentFile.updateIsUploading(true)
        commentFile.updateUploadProgress(0.0)
        
        self.commentDelegate?.gotNewComment([comment])
        
        let headers: HTTPHeaders = QiscusConfig.sharedInstance.requestHeader ?? [:]
        
        Alamofire.upload(
            multipartFormData: { formData in
                formData.append(imageData, withName: "raw_file", fileName: "\(imageName)", mimeType: "\(imageMimeType)")
            },
            to: qiscus.config.UPLOAD_URL,
            headers: headers)
        { encodingResult in
            print("encodingResult: \(encodingResult)")
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    if let JSON = response.result.value {
                        if let responseDictionary = JSON as? Dictionary<String, Any> {
                            if let data = responseDictionary["data"] as? Dictionary<String, Any> {
                                if let file = data["file"] as? Dictionary<String, Any> {
                                    if let url = file["url"] as? String {
                                        DispatchQueue.main.async {
                                            comment.updateCommentStatus(QiscusCommentStatus.sending)
                                            comment.updateCommentText("[file]\(url) [/file]")
                                            print("upload success")
                                            
                                            commentFile.updateURL(url)
                                            commentFile.updateIsUploading(false)
                                            commentFile.updateUploadProgress(1.0)
                                            
                                            self.commentDelegate?.didUploadFile(comment)
                                            self.postComment(comment, file: commentFile, roomId: roomId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                upload.uploadProgress(closure: { progress in
                    print("upload progress: ", progress.fractionCompleted)
                    
                    commentFile.updateIsUploading(true)
                    commentFile.updateUploadProgress(progress.fractionCompleted)
                    
                    self.commentDelegate?.uploadingFile(comment)
                })
                
                upload.response(completionHandler: { response in
                    if response.response != nil {
                        if response.response!.statusCode < 400 || response.error == nil {
                            print("http response upload: \(response.response!)\n")
                        } else {
                            comment.updateCommentStatus(QiscusCommentStatus.failed)
                            commentFile.updateIsUploading(false)
                            commentFile.updateUploadProgress(0)
                            
                            self.commentDelegate?.didFailedUploadFile(comment)
                        }
                    }
                })
                break
            case .failure(_):
                print("encoding error:")
                comment.updateCommentStatus(QiscusCommentStatus.failed)
                commentFile.updateIsUploading(false)
                commentFile.updateUploadProgress(0)
                self.commentDelegate?.didFailedUploadFile(comment)
                break
            }
        }
    }
    
    // MARK: - Communicate with Server
    open func syncMessage(_ topicId: Int, triggerDelegate:Bool = false) {
        if let commentId = QiscusComment.getLastSyncCommentId(topicId) {
            
            let parameters: Parameters =  [
                "comment_id"  : commentId,
                "topic_id" : topicId,
                "after" : "true"
            ]
            
            let headers = QiscusConfig.sharedInstance.requestHeader ?? [:]
            
            Alamofire.request(QiscusConfig.LOAD_URL, parameters: parameters, headers: headers)
                .responseJSON { response in
                if let result = response.result.value {
                    let json = JSON(result)
                    let results = json["results"]
                    let error = json["error"]
                    if results != nil{
                        let comments = json["results"]["comments"].arrayValue
                        if comments.count > 0 {
                            DispatchQueue.main.async {
                                var newMessageCount: Int = 0
                                var newComments = [QiscusComment]()
                                for comment in comments {
                                    
                                    let isSaved = QiscusComment.getCommentFromJSON(comment, topicId: topicId, saved: true)
                                    
                                    if let thisComment = QiscusComment.getCommentById(QiscusComment.getCommentIdFromJSON(comment)){
                                        thisComment.updateCommentStatus(QiscusCommentStatus.delivered)
                                        if isSaved {
                                            newMessageCount += 1
                                            newComments.insert(thisComment, at: 0)
                                        }
                                    }
                                }
                                if newComments.count > 0 {
                                    self.commentDelegate?.gotNewComment(newComments)
                                }
                                if triggerDelegate{
                                    let syncData = QSyncNotifData()
                                    syncData.newMessageCount = newMessageCount
                                    syncData.topicId = topicId
                                    self.commentDelegate?.finishedLoadFromAPI(topicId)
                                }
                            }
                        }
                    }else if error != nil{
                        if triggerDelegate{
                            self.commentDelegate?.didFailedLoadDataFromAPI("failed to sync message with error \(error)")
                        }
                        print("error sync message: \(error)")
                    }
                }else{
                    if triggerDelegate{
                        self.commentDelegate?.didFailedLoadDataFromAPI("failed to sync message, connection error")
                    }
                    print("error sync message")
                }
            }
        }
    }
    
    open func getListComment(topicId: Int, commentId: Int, triggerDelegate:Bool = false, loadMore:Bool = false){ //USED
        let parameters: Parameters =  [
            "comment_id"  : commentId,
            "topic_id" : topicId,
        ]
        
        let headers = QiscusConfig.sharedInstance.requestHeader ?? [:]
        
        Alamofire.request(QiscusConfig.LOAD_URL, parameters: parameters, headers: headers)
            .responseJSON { response in
            if let result = response.result.value {
                let json = JSON(result)
                let results = json["results"]
                let error = json["error"]
                if results != nil{
                    var newMessageCount: Int = 0
                    let comments = json["results"]["comments"].arrayValue
                    if comments.count > 0 {
                        var newComments = [QiscusComment]()
                        for comment in comments {
                            let isSaved = QiscusComment.getCommentFromJSON(comment, topicId: topicId, saved: true)
                            if let thisComment = QiscusComment.getCommentById(QiscusComment.getCommentIdFromJSON(comment)){
                                thisComment.updateCommentStatus(QiscusCommentStatus.delivered)
                                if isSaved {
                                    newMessageCount += 1
                                    newComments.insert(thisComment, at: 0)
                                }
                            }
                        }
                        if newComments.count > 0 {
                            self.commentDelegate?.gotNewComment(newComments)
                        }
                        if loadMore {
                            self.commentDelegate?.didFinishLoadMore()
                        }
                    }
                    if triggerDelegate{
                        self.commentDelegate?.finishedLoadFromAPI(topicId)
                    }
                }else if error != nil{
                    print("error getListComment: \(error)")
                    if triggerDelegate{
                        self.commentDelegate?.didFailedLoadDataFromAPI("failed to load message with error \(error)")
                    }
                }
                
            }else{
                if triggerDelegate {
                    self.commentDelegate?.didFailedLoadDataFromAPI("failed to sync message, connection error")
                }
            }
        }
    }
    
    // MARK: - Load More
    open func loadMoreComment(fromCommentId commentId:Int, topicId:Int, limit:Int = 10){
        let comments = QiscusComment.loadMoreComment(fromCommentId: commentId, topicId: topicId, limit: limit)
        print("got \(comments.count) new comments")
        if comments.count > 0 {
            print("got \(comments.count) new comments")
            self.commentDelegate?.gotNewComment(comments)
            self.commentDelegate?.didFinishLoadMore()
        }else{
            self.getListComment(topicId: topicId, commentId: commentId, loadMore: true)
        }
    }
}
