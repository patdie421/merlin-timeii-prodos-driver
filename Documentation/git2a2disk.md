## Create disk image(s)
### 800kb
```
acx create -d disk.po --prodos --size=800kb
```
### 140kb
```
$ acx create -d disk1.po --prodos --size=140kb
$ acx create -d disk2.po --prodos --size=140kb
```
## Copy files to disk images(s)
### 800kb
$ tools/put_files_to_image.ksh -d disk.po disk/files.lst ""
### 140kb
```
$ tools/put_files_to_image.ksh -d disk1.po disk/files.d1.lst ""
$ tools/put_files_to_image.ksh -d disk2.po disk/files.d2.lst ""
```
## Existing hd image
To copy files in DEV directory
```
$ tools/put_files_to_image.ksh -d hdimage.po disk/files.lst "DEV/"
```
