#####################################################################
# Build script for packaging the SDK for distribution 
#
# Author : Hrishikesh 
#####################################################################
printHeader()
{
  cat <<HEADER
******************************************************

$*

******************************************************
HEADER
}

VERSION=1.0
#BUILD_NUMBER=`date +%Y%m%d%H%M`

#Clear Derived Data to have clean build
rm -rf ~/Library/Developer/Xcode/DerivedData/*

#clean up build folder 
rm -rf HotlineSDK/build
rm -rf buildtmp
mkdir buildtmp


CONSTANTS_FILE=HotlineSDK/HotlineSDK/Utilities/HLVersionConstants.h
#fix version in file
cp ${CONSTANTS_FILE} ${CONSTANTS_FILE}.original
sed -e "s/HOTLINE_SDK_VERSION\(.*\)/HOTLINE_SDK_VERSION @\"${VERSION}\"/g" -i .old ${CONSTANTS_FILE}
BUILD_NUMBER=`cat ${CONSTANTS_FILE} | grep HOTLINE_SDK_BUILD_NUMBER | awk -F'"' ' {print $2 }'`
BUILD_NUMBER=`expr $BUILD_NUMBER + 1`
sed -e "s/HOTLINE_SDK_BUILD_NUMBER\(.*\)/HOTLINE_SDK_BUILD_NUMBER @\"${BUILD_NUMBER}\"/g" -i .old ${CONSTANTS_FILE}


CONCAT=$(cat ${CONSTANTS_FILE})
printHeader "Constants changed to $CONCAT";

#additional compiler flags to reduce package size
COMPILER_FLAGS="GCC_OPTIMIZATION_LEVEL=s GCC_GENERATE_DEBUGGING_SYMBOLS=NO"
CLANG_VER_7=`clang -v 2>&1| grep "version 7" | wc -l`
#OTHER_CFLAGS="-fembed-bitcode -emit-llvm"

#build for each version
while read buildPlatform
do 
  SDK=`echo $buildPlatform | awk '{print $1}'` 
  ARCH=`echo $buildPlatform | awk '{print $2}'` 
  if [ $CLANG_VER_7 -eq 1 ] 
  then
    OTHER_CFLAGS=`echo $buildPlatform | awk '{print $3}'` 
  else 
    OTHER_CFLAGS=""
  fi;

  printHeader "Building SDK for $SDK with Architecture $ARCH"

  xcodebuild $COMPILER_FLAGS OTHER_CFLAGS="${OTHER_CFLAGS}" -project HotlineSDK/HotlineSDK.xcodeproj -target HotlineSDK -sdk $SDK -arch $ARCH -configuration Release clean build
  if [ $? -ne 0 ] 
  then 
    printHeader "build Failed :(" 
    exit
  fi;

  cp ./HotlineSDK/build/Release-$SDK/libHotlineSDK.a buildtmp/libHotlineSDK-$SDK-$ARCH.a
  
done <<ARCHLIST
iphonesimulator i386
iphonesimulator x86_64
iphoneos armv7 -fembed-bitcode
iphoneos armv7s -fembed-bitcode
iphoneos arm64 -fembed-bitcode
ARCHLIST

# Now Lets Package it 
printHeader "Packing SDK for Version $VERSION"
REL_NAME=hotline_ios_v${VERSION}
OUTPUTDIR=dist/$REL_NAME
rm -rf dist
mkdir -p $OUTPUTDIR

RESOURCES_DIR=Hotline/SDKResources
ls buildtmp/*.a | xargs lipo -create -output $OUTPUTDIR/libFDHotlineSDK.a  
cp ./HotlineSDK/HotlineSDK/Hotline.h $OUTPUTDIR
cp -R ${RESOURCES_DIR}/KonotorModels.bundle  $OUTPUTDIR
cp -R ${RESOURCES_DIR}/HLResources.bundle $OUTPUTDIR
cp -R ${RESOURCES_DIR}/HLLocalization $OUTPUTDIR
REL_NOTES=$OUTPUTDIR/ReleaseNotes.txt
RELEASE_HEADER=$( cat <<RELEASEINFO
Hotline iOS SDK - Powered by Freshdesk

Documentation   : <API integration page>
Support         : 
Email           : support@freshdesk.com 
Version         : $VERSION

RELEASEINFO
)

echo "${RELEASE_HEADER}" >> $REL_NOTES
cat ReleaseNotes.txt >> $REL_NOTES

cd dist 
zip -rv ${REL_NAME}.zip *
cp ${REL_NAME}.zip hotline_sdk_ios.zip 
cd ..

mv ${CONSTANTS_FILE}.original ${CONSTANTS_FILE} 
rm ${CONSTANTS_FILE}.old
printHeader "All Set for Version $VERSION.  Package Size = `ls -lh dist/*.zip | awk '{print $5}'` "
printHeader " Build           : ${BUILD_NUMBER}_`git log --pretty=format:'%h' -n 1`"
