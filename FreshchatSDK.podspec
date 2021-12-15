
Pod::Spec.new do |s|

  s.name         		 = "FreshchatSDK"
  s.version      		 = "4.1.6"
  s.summary      		 = "Freshchat iOS SDK - Modern messaging software that your sales and customer engagement teams will love."
  s.description  		 = <<-DESC
                   			Modern messaging software that your sales and customer engagement teams will love.
                   			DESC
  s.homepage     		 = "https://www.freshchat.com"
  s.license 	 		   = { :type => 'Commercial', :file => 'FreshchatSDK/LICENSE', :text => 'See https://www.freshworks.com/terms' }
  s.author       		 = { "Freshdesk" => "support@freshchat.com" }
  s.social_media_url = "https://twitter.com/freshchatapp"
  s.platform     		 = :ios, "8.0"
  s.source       		 = { :git => "https://github.com/freshdesk/freshchat-ios.git", :tag => "v#{s.version}" }

  # Uses the legacy vendored library integration for integrating the FreshchatSDK (not compatible with Apple Silicon)
  s.subspec 'VendoredLibrary' do |ss|
    ss.source_files = "FreshchatSDK/*.{h,m}"
    ss.preserve_paths = "FreshchatSDK/*"
    ss.resources = "FreshchatSDK/FCResources.bundle", "FreshchatSDK/FreshchatModels.bundle", "FreshchatSDK/FCLocalization.bundle"
    ss.ios.vendored_library = "FreshchatSDK/libFDFreshchatSDK.a"
    ss.frameworks = "Foundation", "AVFoundation", "AudioToolbox", "CoreMedia", "CoreData", "ImageIO", "Photos", "SystemConfiguration", "Security", "WebKit", "CoreServices"
    ss.xcconfig = { 'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/FreshchatSDK"' }
    ss.requires_arc = true
  end

  # Uses the modern XCFramework bundle for integrating the FreshchatSDK (compatible with Apple Silicon)
  s.subspec 'Default' do |ss|
    ss.vendored_frameworks = "FreshchatSDK.xcframework"
  end

  s.default_subspec = 'Default'

end
