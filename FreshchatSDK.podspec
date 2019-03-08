
Pod::Spec.new do |s|

  s.name         		 = "FreshchatSDK"
  s.version      		 = "2.4.3"
  s.summary      		 = "Freshchat iOS SDK - Modern messaging software that your sales and customer engagement teams will love."
  s.description  		 = <<-DESC
                   			Modern messaging software that your sales and customer engagement teams will love.
                   			DESC
  s.homepage     		 = "https://www.freshchat.com"
  s.license 	 		 = { :type => 'Commercial', :file => 'FreshchatSDK/LICENSE', :text => 'See https://www.freshworks.com/terms' } 
  s.author       		 = { "Freshdesk" => "support@freshchat.com" }
  s.social_media_url     = "https://twitter.com/freshchatapp"
  s.platform     		 = :ios, "8.0"
  s.source       		 = { :git => "https://github.com/freshdesk/freshchat-ios.git", :tag => "v#{s.version}" }
  s.source_files 		 = "FreshchatSDK/*.{h,m}"
  s.preserve_paths 		 = "FreshchatSDK/*"
  s.resources 			 = "FreshchatSDK/FCResources.bundle", "FreshchatSDK/FreshchatModels.bundle", "FreshchatSDK/FCLocalization.bundle"
  s.ios.vendored_library = "FreshchatSDK/libFDFreshchatSDK.a"
  s.frameworks 			 = "Foundation", "AVFoundation", "AudioToolbox", "CoreMedia", "CoreData", "ImageIO", "Photos", "SystemConfiguration", "Security"
  s.xcconfig       		 = { 'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/FreshchatSDK"' }
  s.requires_arc 		 = true

end
