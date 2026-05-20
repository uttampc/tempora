upawar@imac-debian:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2       908G   35G  827G   4% /
upawar@imac-debian:~$ df -h |grep -v tmpfs
Filesystem      Size  Used Avail Use% Mounted on
udev            3.8G     0  3.8G   0% /dev
/dev/sda2       908G   35G  827G   4% /
/dev/sda1       975M  8.8M  966M   1% /boot/efi
/dev/sdb2       4.6T  1.2T  3.5T  26% /media/upawar/MainDrive5T
/dev/sdc2       3.7T  2.7T  1.1T  73% /media/upawar/Seagate4TB
