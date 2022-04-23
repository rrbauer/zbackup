#!/bin/bash

# Simple backup utility utilizing luks, zfs and snapshots
# Must be run as root (sudo)
# See README for usage details and more

ZPOOL=zbackup
ZDEV=zbackup-drive

backup_user() {
	if [ -z "$1" ] ; then
		echo "Usage: $0 backup username"
		exit
	fi

	DST=$ZPOOL/$1
	SRC=/home/$1/
	LOG=/$ZPOOL/${1}.log

	EXCLUDEOPT="--exclude=**/*tmp*/ --exclude=**/*cache*/ --exclude=**/*Cache*/ --exclude=**~ --exclude=**/*Trash*/ --exclude=**/*trash*/ --exclude=/.cache/"

	if [ ! -d $SRC ] ; then
		echo "Error: Home dir for user $1 does not exist, is not accessible, or is not a directory"
		exit
	fi

	# check if zpool exists, import if not
	if [ ! -d /$ZPOOL ] ; then
		zpool import -d /dev/mapper $ZPOOL || exit
	fi

	# check if backup dataset exists, create if not
	if [ ! -d /$DST ] ; then
		zfs create $DST || exit
	fi

	rsync -av --delete-excluded $EXCLUDEOPT --log-file=$LOG --partial --progress --stats $SRC /$DST

	# save a snapshot
	TS=`date +%Y%m%d-%H%M%S`
	zfs snapshot $DST@$TS
}

zbackup_mount() {
	DEVICE=$1
	if [ -z "$DEVICE" ] ; then
		echo "Usage: $0 mount device"
		exit
	fi

	cryptsetup luksOpen $DEVICE $ZDEV
	zpool import -d /dev/mapper $ZPOOL
}

zbackup_umount() {
	zpool export $ZPOOL
	cryptsetup luksClose $ZDEV
}

zbackup_create() {
	DEVICE=$1
	if [ -z "$DEVICE" ] ; then
		echo "Usage: $0 create device"
		exit
	fi

	parted -s $DEVICE mklabel gpt
	parted -s $DEVICE mkpart zbackup 0% 100%

	cryptsetup luksFormat ${DEVICE}1
	cryptsetup luksOpen ${DEVICE}1 $ZDEV
	zpool create $ZPOOL /dev/mapper/$ZDEV
	zfs set atime=off zbackup
	zfs set compress=on zbackup
	zpool export $ZPOOL
	cryptsetup luksClose $ZDEV
}

if [ -z "$1" ] ; then
	echo "Usage: $0 {backup|mount|umount|create} ..."
	exit
fi

case $1 in
	backup)
		backup_user $2
		;;
	mount)
		zbackup_mount $2
		;;
	umount)
		zbackup_umount
		;;
	create)
		zbackup_create $2
		;;
esac

