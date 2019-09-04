git_hash_key=$(git rev-parse --short HEAD)
package_time=$(date '+%Y-%m-%d-%H:%M:%S')

git_remote_url=$(git remote -v show)
#reset remote url to fix request (make it single line)
b=${git_remote_url%%(*}
c=${b##*origin}
git_remote_url=`echo $c | sed -e 's/^[ \t]*//g'`

git_current_branch=$(git symbolic-ref --short -q HEAD)
progect_name=$1
oss_bucket_name=$2
oss_path=$3
app_config=$4


rm -rf /Users/bluezhang/Desktop/ReleaseNote.txt
echo "git_version=${git_hash_key}" 
echo "package_time=${package_time}" 
echo "git_remote_url=${git_remote_url}"
echo "git_current_branch=${git_current_branch}"

echo "git_version=${git_hash_key}" >> ReleaseNote.txt
echo "package_time=${package_time}" >> ReleaseNote.txt
echo "git_remote_url=${git_remote_url}" >> ReleaseNote.txt
echo "git_current_branch=${git_current_branch}" >> ReleaseNote.txt

