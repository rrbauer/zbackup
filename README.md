# zbackup
Simple backup utility utilizing luks, zfs and snapshots.
Must be run as root (sudo)

Dependencies:
1. zfsutils-linux
2. parted
3. rsync

Basic usage:
1. Create the zpool: zbackup.sh create <device>
   Note: device is the entire device, not a partition eg: /dev/sdb not /dev/sdb1.
   This removes any existing partitions, creates a gpt label and one partition using all space on the
   device, minus any needed for alignment. It creates a LUKS-encrypted container in the partition,
   then a zpool named zbackup in it. The root zfs dataset will have compression enabled, and atime
   disabled.
2. Mount the zpool: zbackup.sh mount <device>
   Note: device is the partition, eg: /dev/sdb1
3. Make a backup: zbackup.sh backup <username>
   Currently this only supports backing up the home directory for the given user. Certain files and
   directories are excluded, like .cache/ tmp/ Trash/ etc. If a zfs dataset named for the user does not
   exist, it is created.
   A zfs snapshot is created afterward. Subsequent backups will only store changed blocks. God how
   I love ZFS!
4. Unmount the zpool: zbackup.sh umount
   Does exactly what you would expect. Exports the zpool and closes the LUKS container

BIG NOTE: This is a single-drive backup solution. It does not utilize any zfs redundancy features
(mirror, raidz). If you desire redundancy (and you should), have several drives and rotate them.
This is meant to be simple, and for use on portable, external drives.

Lesser note: I use this on Linux Mint, a derivative of Ubuntu, which is a derivative of Debian. Thanks
to all the developers over the years who have made these amazing distributions.

I don't know if it will work for you. #itworksforme lol. Give it a try!
