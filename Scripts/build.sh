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

VERSION=DEV

#Clear Derived Data to have clean build
rm -rf ~/Library/Developer/Xcode/DerivedData/*

#clean up build folder 
rm -rf HotlineSDK/build
rm -rf buildtmp
mkdir buildtmp

IS_RELEASE="NO"
if [ "$1" == "release" ]
then 
  IS_RELEASE="YES"
  if [ $# -ge 2 ]
  then
    VERSION=$2
    if [ `git tag -l | grep "${VERSION}" | wc -l` -gt 0 ] 
    then 
      printHeader "Version ${VERSION} already exists"
      exit; 
    fi;
  else
    printHeader "Please provide a version Number for release"
    exit;
  fi;
fi;

CONSTANTS_FILE=HotlineSDK/HotlineSDK/Utilities/HLVersionConstants.h
#fix version in file
git checkout ${CONSTANTS_FILE} # make pristine
cp ${CONSTANTS_FILE} ${CONSTANTS_FILE}.original
PREV_VERSION=`cat ${CONSTANTS_FILE} | grep HOTLINE_SDK_VERSION | awk -F'"' ' {print $2 }'`
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
    osascript -e 'display notification ":(" with title "Build failed"'
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
cp LICENSE $OUTPUTDIR
cp ./HotlineSDK/HotlineSDK/Hotline.h $OUTPUTDIR
cp -R ${RESOURCES_DIR}/KonotorModels.bundle  $OUTPUTDIR
cp -R ${RESOURCES_DIR}/HLResources.bundle $OUTPUTDIR
cp -R ${RESOURCES_DIR}/HLLocalization.bundle $OUTPUTDIR
REL_NOTES=$OUTPUTDIR/ReleaseNotes.txt
RELEASE_HEADER=$( cat <<RELEASEINFO
Hotline iOS SDK - Powered by Freshdesk

Documentation   : https://hotline.freshdesk.com/support/solutions
Support Email   : support@hotline.io 
Version         : $VERSION

RELEASEINFO
)

cat << HELP_TXT > /tmp/rel_notes.txt


# Please enter the Release notes. Line starting with # will be removed" 
# 
# Changes/Commits from ${PREV_VERSION}" 
# 
HELP_TXT
git log --pretty=oneline --abbrev-commit v${PREV_VERSION}...HEAD | sed -e 's/^/# /g' >> /tmp/rel_notes.txt

if [ "$IS_RELEASE" == "YES" ] 
then 
  vim /tmp/rel_notes.txt
  if [ `cat /tmp/rel_notes.txt | sed '/^\s*#/d;/^\s*$/d' | wc -l` -eq 0 ] 
  then
    printHeader "No release notes added. Exiting" 
    exit
  fi;
fi;

echo "${RELEASE_HEADER}" >> $REL_NOTES

git checkout ReleaseNotes.txt # make sure it is pristine
mv ReleaseNotes.txt ReleaseNotes_v.txt

cat <<RELEASE_NOTES_M > ReleaseNotes.txt

Ver ${VERSION} 
__________________________
RELEASE_NOTES_M


cat /tmp/rel_notes.txt  |  sed '/^\s*#/d;/^\s*$/d'  >> ReleaseNotes.txt
cat ReleaseNotes_v.txt >> ReleaseNotes.txt


cat ReleaseNotes.txt >> $REL_NOTES

cd dist 
zip -rv ${REL_NAME}.zip *
cp ${REL_NAME}.zip hotline_sdk_ios.zip 
cd ..

if [ "$IS_RELEASE" == "YES" ] 
then 
  git add ${CONSTANTS_FILE}
  git add ReleaseNotes.txt
  git commit -m "Release [${VERSION}] Build[${BUILD_NUMBER}] - `git config user.name`" 
  git tag v${VERSION}
  rm ${CONSTANTS_FILE}.old ${CONSTANTS_FILE}.original
  rm ReleaseNotes_v.txt
  git tag -l | grep build | xargs git tag -d  #remove old build tags so that they are not pushed
else
  mv ${CONSTANTS_FILE}.original ${CONSTANTS_FILE} 
  rm ${CONSTANTS_FILE}.old
  mv ReleaseNotes_v.txt ReleaseNotes.txt
fi;
printHeader "Version [$VERSION] Package Size[`ls -lh dist/hotline_sdk_ios.zip | awk '{print $5}'`] Build[${BUILD_NUMBER}] Commit[`git log --pretty=format:'%h' -n 1`]"
osascript -e 'display notification "Hotline iOS SDK build '$BUILD_NUMBER' is ready" with title "Build succeeded"'

if [ "$IS_RELEASE" == "YES" ] 
then 
  printHeader "All good. run [git push --tags] to release to git"
fi;
#Documentation
command -v appledoc >/dev/null 2>&1 || { echo "Appledoc not installed. Skipping Docs" >&2; exit 1; }
printHeader "Generating docs"
xcodebuild -project HotlineSDK/HotlineSDK.xcodeproj -target Documentation -configuration build
