Pod::Spec.new do |s|

s.name         = "Qiscus"
s.version      = "0.3.3"
s.summary      = "Qiscus SDK for iOS"

s.description  = <<-DESC
Qiscus SDK for iOS contains Qiscus public Model.
DESC

s.homepage     = "https://qisc.us"

s.license      = "MIT"
s.author       = "Ahmad Athaullah"

s.source       = { :git => "https://github.com/hanief/Qiscus.git", :tag => "#{s.version}" }

s.source_files  = "Qiscus/Qiscus/*"
s.platform      = :ios, "9.0"

s.dependency 'Alamofire', '~> 4.0'
s.dependency 'AlamofireImage', '~> 3.0'
s.dependency 'PusherSwift', '~> 4.0'
s.dependency 'RealmSwift', '~> 2.0'
s.dependency 'SwiftyJSON', '~> 3.0'

end
