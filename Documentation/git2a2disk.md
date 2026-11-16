## Create disk image(s)
### 800kb
```
acx create -d disk.po --prodos --size=800kb
```
### 140kb
```
acx create -d disk1.po --prodos --size=140kb
acx create -d disk2.po --prodos --size=140kb
```
## Copy files to disk images(s)
### 800kb or more

### 140kb
put_files_to_image.ksh <disk-image> <list-of-files> <dest>
put_files_to_image.ksh -d disk1.po disks/list1.txt ""
