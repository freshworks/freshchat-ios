find . -name "*.h" | grep HotlineSDK > /tmp/files_to_check.txt
find . -name "*.m" | grep HotlineSDK >> /tmp/files_to_check.txt
while read fileName 
do
  Scripts/find_unused_imports.rb $fileName
done < /tmp/files_to_check.txt
