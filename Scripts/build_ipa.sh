#!/bin/bash

xcodebuild clean -project 'Hotline Demo.xcodeproj' -configuration Release -alltargets
xcodebuild archive -project "Hotline Demo.xcodeproj" -scheme "Hotline Demo" -archivePath build/hotline.xcarchive
FILE_PATH="dist/Hotline-`date +%Y%m%d_%H%M`.ipa";
xcodebuild -exportArchive -archivePath build/hotline.xcarchive -exportPath $FILE_PATH -exportFormat ipa  -exportProvisioningProfile "Hotline Demo Dev Profile"
