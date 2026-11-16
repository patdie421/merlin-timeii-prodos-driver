## Clone
```
$ git clone https://github.com/patdie421/merlin-timeii-prodos-driver
```
## pull last version
```
$ cd <merlin-timeii-prodos-driver>
$ git pull
```
## Create disk image(s)
### 800kb
```
$ acx create -d disk.po --prodos --size=800kb
```
### 140kb
```
$ acx create -d disk1.po --prodos --size=140kb
$ acx create -d disk2.po --prodos --size=140kb
```
## Copy files to disk images(s)
### 800kb
$ cd <merlin-timeii-prodos-driver>
$ tools/put_files_to_image.ksh disk.po disk/files.lst ""
### 140kb
```
$ cd <merlin-timeii-prodos-driver>
$ tools/put_files_to_image.ksh disk1.po disk/files.d1.lst ""
$ tools/put_files_to_image.ksh disk2.po disk/files.d2.lst ""
```## Existing hd image
To copy files in DEV directory
```
$ cd <merlin-timeii-prodos-driver>
$ tools/put_files_to_image.ksh -d hdimage.po disk/files.lst "DEV/"
```
