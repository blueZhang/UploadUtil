
# OSSUpload 工具V1.0

# 当前版本支持功能

# 1.	上传单独文件或批量上传文件至指定OSS Bucket下。
# 2.	备份指定OSS Bucket 中转包备份。
# 3.	将备份数据发布至线上。
# 4.	删除OSS Bucket 中转包测试文件。
# 注意：使用此工具需自行安装json 解析工具 jq和文件压缩工具 7z

# OSSUpload config 配置

# 使用此工具前应提前配置工具包目录下config文件
# endpoint=yourEndpoint
# accessKeyID=yourAccessKeyID 
# accessKeySecret=yourAccessKeySecret
# 注：参数说明
# endpoint：填写Bucket所在地域的域名信息，可参考访问域名和数据中心
# accessKeyID：创建用户时系统分配的accessKeyID
# accessKeySecret：创建用户时系统分配的accessKeySecret 只显示一次注意保存

#说明
show_usage="用法:  [command] [args...] [options...]\n
请使用oss_upload_util.sh -- help command来显示command命令的帮助\n

Commands:\n\n
   \t -t, --function-type    设置所需要使用的功能 \n\n
				\t  \t upload：文件上传。\n\n
				\t \t backup：备份中转包。\n\n
				\t \t pb：发布中转包至线上（publish backup）。\n\n
				\t \t dp：删除中转包（delete path）。\n\n
   \t  -n，--app-name	     设置项目名称。\n\n
   \t  -b，--access-bucket-name  设置设置远程Bucket。\n\n
   \t  -p，--bucket-file-path    设置所需要删除的中转包。\n\n
   \t  -h,--help 		     获取帮助"

function_type_option_des="功能参数输入有误 请根据如下参数进行输入： \n\n
             \t 设置所需要使用的功能\n\n
            \t  \t upload：文件上传功能。\n\n
            \t \t backup：文件备份功能。\n\n
            \t \t publish：发布备份文件至线上（publish backup）。\n\n
            \t \t delete：删除某路径下所有文件（delete path）。\n\n"

#args
script_dir=`dirname $0`
#current app name 
app_name=""

#access bucket name 
bucket_name=""

#version name 
version_name=""

#version code 
version_code=""

#bucket file path
bucket_file_path=""

#function type
function_type=""

#script file path 
file_dir=`pwd`

#root fir path 
root_dir=$(dirname $(dirname "$PWD"))

timestab=$(date '+%Y-%m-%d-%H:%M:%S')

timestab_md5=`echo "$timestab" | md5 `
# timestab_md5=`md5sum <<< $timestab | cut -d ' ' -f1`

# while [ -n "$1" ]
# do
#         case "$1" in
#                 -t|--function-type) 
#                                  function_type=$2; 
#                                   if [ $2 == "upload" ]
#                                         then
#                                              echo "###Selected function is 上传测试文件"
#                                   elif [ $2 == "backup" ]
#                                        then
#                                             echo "###Selected function is 备份中转包"
#                                   elif [ $2 == "pb" ]
#                                         then
#                                             echo "###Selected function is 发布中转包至线上"
#                                   elif [ $2 == "dp" ]
#                                         then
#                                             echo "###Selected function is 删除中转包" 
#                                   else
#                                           echo $1 $2 $function_type_option_des; exit 8;
#                                   fi
                                 
#                                  shift 2
#                                  ;;
#                 -n|--app-name) app_name=$2; shift 2;;
#                 -b|--access-bucket-name) bucket_name=$2; shift 2;;
#                 -p|--transfers-package-name) bucket_file_path=$2; shift 2;;
#                 -h|--help) echo $show_usage; exit 8; shift 1;;
#                 --) break ;;
#                 *) echo $show_usage; exit 8; break ;;
#         esac
# done

function_type=$1

app_name=$2

bucket_name=$3

bucket_file_path=$4

#project path 
project_dir=$root_dir/$app_name

echo 'app_name = '$app_name

echo 'bucket_name = '$bucket_name

echo 'bucket_file_path = '$bucket_file_path

# echo 'root_dir = '$root_dir

# echo 'project_dir = '$project_dir

# echo 'function_type = '$function_type

# echo timestab = $timestab

# echo timestab_md5 = $timestab_md5


processChannelDir(){

   if [ -f "$1" ]
     then
        file="$1/$inner"

        if [ "${file##*.}"x = "apk"x ];then
            cp $file $2
        fi

        if [ "${file##*.}"x = "txt"x ];then
             cp $file $2/mappings
        fi
       
    elif [ -d "$1" ]
     then
         for inner in `ls $1`; do
            if [ -f "$1/$inner" ]; then
                file="$1/$inner"
                if [ "${file##*.}"x = "apk"x ];then
                    cp $file $2
                fi

                if [ "${file##*.}"x = "txt"x ];then
                    cp $file $2/mappings
                fi
            fi

            if [ -d "$1/$inner" ]; then  
                processChannelDir "$1/$inner" $2
            fi
         done
    fi
}

#get app version name 
getVersionName(){
  local gv=""
  for ChannelDir in $project_dir/build/outputs/apk/*; do
      if [ -d $ChannelDir ]; then
          if [ ""=="$version_name" ];then
             getVersionNameFromJson $ChannelDir $UploadDir
          fi
          
      fi
   done
  
}

#get version name in json file 
getVersionNameFromJson(){
  local source_version_name="" 
  local va=""
  local vc=""
  
  if [ -f "$1" ]
     then
        file="$1/$inner"

        if [ "${file##*.}"x = "json"x ];then
            source_version_name=`cat $file | jq '.[0].apkInfo.versionName'`
            if [ ! -n "$source_version_name" ] ; then
               source_version_name=`cat output.json | jq '.[0].apkDate.versionName' `
            fi
            if [ "null" == "$source_version_name" ] ; then
               source_version_name=`cat output.json | jq '.[0].apkDate.versionName' `
            fi
            va=`echo $source_version_name |sed 's/\"//g'`
            vc=`cat $file | jq '.[0].apkInfo.versionCode'`
            version_name="$va"
        fi
       
    elif [ -d "$1" ]
     then
         for inner in `ls $1`; do
            if [ -f "$1/$inner" ]; then
                 file="$1/$inner"
                 if [ "${file##*.}"x = "json"x ];then 
                     source_version_name=`cat $file | jq '.[0].apkInfo.versionName'`
                     if [ ! -n "$source_version_name" ] ; then
                        source_version_name=`cat output.json | jq '.[0].apkDate.versionName' `
                     fi
                     if [ "null" == "$source_version_name" ] ; then
                        source_version_name=`cat output.json | jq '.[0].apkDate.versionName' `
                     fi
                     va=`echo $source_version_name |sed 's/\"//g'`
                     vc=`cat $file | jq '.[0].apkInfo.versionCode'`
                     version_name="$va"
                 fi
            fi

            if [ -d "$1/$inner" ]; then  
                getVersionNameFromJson "$1/$inner" $2
            fi
         done
    fi
   
}

#upload files to target oss bucket. 
uploadFile(){
  #get version name 
  getVersionName

  #Set up upload dir
  local VersionString="$version_name"-"$timestab"-"$timestab_md5"
  local UploadDir=$project_dir/build/$VersionString
  local ZipFilePath=$project_dir/build/$VersionString.7z
  local transfers_file_path=$VersionString

  mkdir -p $UploadDir/mappings
  echo "#### Upload dir is $UploadDir"

   for ChannelDir in $project_dir/build/outputs/apk/*; do
      if [ -d $ChannelDir ]; then
          processChannelDir $ChannelDir $UploadDir
      fi
   done

  echo "#### All contents copied to upoad dir $UploadDir"

  # compress mapping file
  7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on $UploadDir/mappings.7z $UploadDir/mappings

  # delete old mapping file
  rm -rf $UploadDir/mappings

  cp ReleaseNote.txt $UploadDir/ReleaseNote.txt

  # compress upload content into single file
  7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on $ZipFilePath $UploadDir

  rm -r $UploadDir/mappings.7z

  echo "#### Zipped content created"
  echo ===============================
  echo "File upload start =>>>"

  # upload dir and zip file to aliyun
  local OssPath=oss://$bucket_name/$app_name/test/$transfers_file_path/
  $script_dir/ossutilmac64 cp -r $UploadDir $OssPath -c config
  $script_dir/ossutilmac64 cp $ZipFilePath $OssPath$VersionString.7z -c config
  echo "#### "Target OSS path is : "\n" https://oss.console.aliyun.com/bucket/oss-cn-beijing/$bucket_name/object?path=$app_name%2Ftest%2F$transfers_file_path
  echo "#### "Transfers package name 中转包名称 : "\n" $transfers_file_path
  echo ===============================

}

#copy apk to new file 
copyApkFile(){
   file=$1
   if [ "${file##*.}"x = "apk"x ]||[ "${file##*.}"x = "txt"x ];then
      cp $1 $2/$1
   fi
}

#buckup file 
buckupFile(){
   echo ===============================
   echo "File buckup start =>>>"
   $script_dir/ossutilmac64 cp oss://$bucket_name/$app_name/test/$bucket_file_path/$bucket_file_path.7z oss://$bucket_name/$app_name/version-history-backup/ -r -f -c config
   echo "=>>>File buckup end"
   echo "#### "Target OSS path is : "\n" https://oss.console.aliyun.com/bucket/oss-cn-beijing/$bucket_name/object?path=$app_name/version-history-backup/$bucket_file_path.7z
   echo "#### "Transfers package name 中转包名称 : "\n" $bucket_file_path
   echo ===============================
}

#publish file to oss 
publishFile(){
   mkdir tmp
   cd tmp
   echo ===============================
   curl -O --insecure https://public-plstore-barket.oss-cn-beijing.aliyuncs.com/$app_name/version-history-backup/$bucket_file_path.7z
   #wget https://oss.console.aliyun.com/bucket/oss-cn-beijing/$bucket_name/object?path=$app_name/version-history-backup/$bucket_file_path
   echo "#### Download file：\n"https://public-plstore-barket.oss-cn-beijing.aliyuncs.com/$app_name/version-history-backup/$bucket_file_path.7z
   echo "Unzip 7z file  $bucket_file_path".7z 
   7z x $bucket_file_path.7z
   cd $bucket_file_path
   mkdir apks 
   local UploadDir=apks
   for file in `ls`
   do 
      copyApkFile $file $UploadDir
   done
  
   cd ..
   cd ..
   echo "#### File upload start=>>>"
   $script_dir/ossutilmac64 cp tmp/$bucket_file_path/apks/ oss://$bucket_name/$app_name/online/ -r -f -c config
   echo "=>>>File upload end!"
   rm -rf tmp
   echo ===============================
}

#remove oss file 
deleteFile(){
  echo ===============================
  echo "###Transfers package name :\n"$bucket_file_path 
  echo "File delete start =>>>"
  $script_dir/ossutilmac64 rm oss://$bucket_name/$app_name/test/$bucket_file_path -rm -a -f -c config 
  echo "=>>>File delete finish!\n"
  echo "### Origin oss path is :"
  echo "https://oss.console.aliyun.com/bucket/oss-cn-beijing/$bucket_name/object?path=$app_name%2Ftest%2F$bucket_file_path"
  echo ===============================
}

handleFunction(){
  if [ "upload" == "$function_type" ]
    then
         ###Selected function is 上传测试文件
        uploadFile
  elif [ "backup" == "$function_type" ]
    then
        ###Selected function is 备份中转包
        buckupFile
  elif [ "publish" == "$function_type" ]
    then
         ###Selected function is 发布中转包至线上
        publishFile
  elif [ "delete" == "$function_type" ]
    then
         ###Selected function is 删除中转包
        deleteFile
  else
       echo $1 $2 $function_type_option_des
  fi
}

handleFunction

      
        





