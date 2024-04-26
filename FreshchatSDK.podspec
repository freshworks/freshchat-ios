
Pod::Spec.new do |s|

  s.name         		 = "FreshchatSDK"
  s.version      		 = "6.1.0"
  s.summary      		 = "Freshchat iOS SDK - Modern messaging software that your sales and customer engagement teams will love."
  s.description  		 = <<-DESC
                   			Modern messaging software that your sales and customer engagement teams will love.
                   			DESC
  s.homepage     		 = "https://www.freshchat.com"
  s.license 	 		 = { :type => 'Commercial', :file => 'FreshchatSDK/LICENSE', :text => 'See https://www.freshworks.com/terms' }
  s.author       		 = { "Freshdesk" => "support@freshchat.com" }
  s.social_media_url     = "https://twitter.com/freshchatapp"
  s.platform     		 = :ios, "12.0"
  s.source       		 = { :git => "https://github.com/freshworks/freshchat-ios.git", :tag => "v#{s.version}" }
  s.frameworks 			 = "Foundation", "AVFoundation", "AudioToolbox", "CoreMedia", "CoreData", "ImageIO", "Photos", "SystemConfiguration", "Security", "WebKit", "CoreServices", "QuickLook"
  s.requires_arc 		 = true
  s.preserve_paths      = "FreshchatSDK.xcframework"
  s.vendored_frameworks = "FreshchatSDK.xcframework"

end
