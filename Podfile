# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'

target 'Example' do
  use_frameworks!

    pod 'Alamofire', '~> 3.5.0'
    pod 'AlamofireImage', '~> 2.5.0'
    pod 'RxSwift', '~> 2.0'
    pod 'PusherSwift', git: 'https://github.com/pusher/pusher-websocket-swift.git', branch: 'push-notifications-swift-2.3'
    pod 'RealmSwift', '~> 2.0'
    pod 'SwiftyJSON', '2.4.0'

end

target 'Qiscus' do
    use_frameworks!
    
    pod 'Alamofire', '~> 3.5.0'
    pod 'AlamofireImage', '~> 2.5.0'
    pod 'PusherSwift', git: 'https://github.com/pusher/pusher-websocket-swift.git', branch: 'push-notifications-swift-2.3'
    pod 'RealmSwift', '~> 2.0'
    pod 'SwiftyJSON', '2.4.0'
   
    post_install do |installer|
    	installer.pods_project.targets.each do |target|
        	target.build_configurations.each do |config|
          		config.build_settings['SWIFT_VERSION'] = '2.3'
       		end
    	end
    end
end
