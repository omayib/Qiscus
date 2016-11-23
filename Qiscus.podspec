Pod::Spec.new do |s|

s.name         = "Qiscus"
s.version      = "0.6"
s.summary      = "Qiscus SDK for iOS"

s.description  = <<-DESC
Qiscus SDK for iOS contains Qiscus public Model.
DESC

s.homepage     = "https://qisc.us"

s.license      = "MIT"
s.author       = "Ahmad Athaullah"

s.source       = { :git => "https://github.com/hanief/Qiscus.git", :branch => "swift2.3 }


s.source_files  = "Qiscus/**/*.{swift}"
s.resource_bundles = {
    'Qiscus' => ['Qiscus/**/*.{storyboard,xib,xcassets,json,imageset,png}']
}

s.platform      = :ios, "8.3"

s.dependency 'Alamofire', '3.5.0'
s.dependency 'AlamofireImage', '2.5.0'
s.dependency 'PusherSwift', :git => 'https://github.com/pusher/pusher-websocket-swift.git', :branch => 'push-notifications-swift-2.3'
s.dependency 'RealmSwift', '1.1.0'
s.dependency 'SwiftyJSON', :git => 'https://github.com/SwiftyJSON/SwiftyJSON.git', :branch => 'swift2'
s.dependency 'ReachabilitySwift', '2.4'
s.dependency 'QToasterSwift'
s.dependency 'QAsyncImageView', :git => 'https://github.com/hanief/QAsyncImageView.git', :branch => 'swift2.3'
s.dependency 'SJProgressHUD'
s.dependency 'ImageViewer', :git => 'https://github.com/hanief/ImageViewer.git'

end
