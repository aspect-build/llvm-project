# Instructions

Launch an AWS graviton instance with some base instructions. Using aws/al2023/kitchen-sink.pkr.hcl from workflows-images right now



```
sudo su -
cd /tmp
git clone https://github.com/aspect-forks/llvm-project.git
cd llvm-project/
git checkout aspect-release-14.0.0-arm
clear && git reset --hard && git checkout master && git branch -D aspect-release-14.0.0-arm && git fetch --prune && git checkout aspect-release-14.0.0-arm && docker build .
```



#23 0.214 drwxr-xr-x.  1 root root  105 Nov 28 18:58 .
#23 0.214 drwxr-xr-x.  1 root root   45 Nov 28 18:50 ..
#23 0.214 drwxr-xr-x.  2 root root 4096 Nov 28 18:58 bin
#23 0.214 drwxr-xr-x.  2 root root   36 Nov 28 18:58 etc
#23 0.214 drwxr-xr-x. 22 root root 4096 Nov 28 18:58 include
#23 0.214 drwxr-xr-x.  4 root root 4096 Nov 28 18:58 lib
#23 0.214 drwxr-xr-x.  3 root root   21 Nov 28 18:58 libexec
#23 0.214 drwxr-xr-x.  2 root root   75 Nov 28 18:58 sbin
#23 0.214 drwxr-xr-x.  4 root root   32 Nov 28 18:58 share
#23 0.214 drwxr-xr-x.  3 root root   16 Nov 28 18:58 var