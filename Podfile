platform :ios, '9.0'

target 'Example' do
    use_frameworks!
    
    pod 'Alamofire', '~> 4.0'
    pod 'AlamofireImage', '~> 3.0'
    pod 'RxSwift', '~> 3.0'
    pod 'PusherSwift', '~> 4.0'
    pod 'RealmSwift', '~> 2.0'
    pod 'SwiftyJSON', '~> 3.0'

end

target 'Qiscus' do
    use_frameworks!
    
    pod 'Alamofire', '~> 4.0'
    pod 'AlamofireImage', '~> 3.0'
    pod 'PusherSwift', '~> 4.0'
    pod 'RealmSwift', '~> 2.0'
    pod 'SwiftyJSON', '~> 3.0'
   
    post_install do |installer|
    	installer.pods_project.targets.each do |target|
        	target.build_configurations.each do |config|
          		config.build_settings['SWIFT_VERSION'] = '3.0'
       		end
    	end
    end
end
