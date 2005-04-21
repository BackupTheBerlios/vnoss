#!/bin/bash
# $Header: /home/xubuntu/berlios_backup/github/tmp-cvs/vnoss/Repository/livecd/scripts/install.sh,v 1.2 2005/04/21 17:39:41 langthang Exp $
#------------------------------------------
# Installation script for VnOSS LiveCD
#
# Version 0.3 (06:45:26 CN  17 Thg 4 2005 ICT)
# - Add Timezone selection feature
# - mykernel=$(uname -r)
# - fixed /etc/profile
#
# Version: 0.2
# Date: Sat Apr 16 13:52:40 CEST 2005
# Changes:
#  - Configurable for Windows entry in grub conf
#  - Checking for *_PARTITION before doing commands
#  - Could work with/without /boot partition (?) 
#
#
#------------------------------------------

#----- Configurable Variables -------
# Partitions
SWAP_PARTITION="/dev/hda2"
ROOT_PARTITION="/dev/hda3"
BOOT_PARTITION="/dev/hda1"
#BOOT_PARTITION=""

# Filesystem "ext3" or reiserfs 
ROOT_FS="ext3"
#ROOT_FS="reiserfs"

# GRUB configuration 
GRUB_DEVICE="/dev/hda"

# Linux image
GRUB_LINUX_TITLE="Gentoo Linux $(uname -r)"
GRUB_LINUX_ROOT="hd0"

# set GRUB_WIN_TITLE="" if no need Windows entry in grub
GRUB_WIN_TITLE="Windows"
GRUB_WIN_ROOT="hd0"

#--------------------------------------------
# Hostname
myhost="vnoss"
# Domain name
mydomain="mydomain.net"
# Kernel (exact name of kernel)
mykernel=$(uname -r)


#--- WARNING: Don't change any thing after this line -----------

# always use ext3 for /boot partition
BOOT_FS="ext3"

# When no /boot partition, we use _ext3_ filesystem
if [ "$BOOT_PARTITION" = "" ]; then
	ROOT_FS="ext3"
fi

myroot="/mnt/gentoo"

#f_profile="$myroot/etc/profile"
f_profile="/etc/profile"
f_fstab="$myroot/etc/fstab"
f_hosts="$myroot/etc/hosts"
f_inittab="$myroot/etc/inittab"
f_hostname="$myroot/etc/conf.d/hostname"
f_domainname="$myroot/etc/conf.d/domainname"
f_grub_conf="$myroot/boot/grub/grub.conf"


#Set up colors
NO=$'\x1b[0;0m'
BR=$'\x1b[0;01m'
RD=$'\x1b[31;01m' Rd=$'\x1b[00;31m'
GR=$'\x1b[32;01m' Gr=$'\x1b[00;32m'
YL=$'\x1b[33;01m' Yl=$'\x1b[00;33m'
BL=$'\x1b[34;01m' Bl=$'\x1b[00;34m'
MG=$'\x1b[35;01m' Mg=$'\x1b[00;35m'
CY=$'\x1b[36;01m' Cy=$'\x1b[00;36m'

#------- Functions ---------------------------------------------
function myinfo() {
	echo " ${GR}*${NO} ${BL}$*${NO}"
}

function myerror() {
	echo " ${RD}!!! LỖI: $*${NO}"
}

function settimezone(){
	myroot=$1
#	echo "====  Xác lập múi giờ cho hệ thống ===="
	echo ""
	echo "1.Athens	7.Los Angeles	13.Dubai"
	echo "2.Brussels	8.New York 	14.Saigon"
	echo "3.Moscow 	9.Santiago	15.Bangkok "
	echo "4.London 	10.Chicago	16.Tokyo "
	echo "5.Hensinki	11.Toronto 	17.Jakarta"
	echo "6.Melbourbe	12.Sydney 	18.Singapore"
	echo ""
	echo -n "Lựa chọn múi giờ: "
	read myzone
	case "$myzone" in
	"1") zone="Europe/Athens" ;;
	"2") zone="Europe/Brussels" ;;
	"3") zone="Europe/Moscow" ;;
	"4") zone="Europe/London" ;;
	"5") zone="Europe/Hensinki" ;;
	"6") zone="Australia/Melbourne" ;;

	"7") zone="America/Los_Angeles" ;;
	"8") zone="America/New_York" ;;
	"9") zone="America/Santiago" ;;
	"10") zone="America/Chicago" ;;
	"11") zone="America/Toronto" ;;
	"12") zone="Australia/Sydney" ;;

	"13") zone="Asia/Dubai" ;;
	"14") zone="Asia/Saigon" ;;
	"15") zone="Asia/Bangkok" ;;
	"16") zone="Asia/Tokyo" ;;
	"17") zone="Asia/Jakarta" ;;
	"18") zone="Asia/Singapore" ;;
	   *) zone="Europe/London" ;;
	esac
	ln -sf /usr/share/zoneinfo/$zone $myroot/etc/localtime
}
#----------------------------------------------------------------

# root privilege required
#-------------------------------------------------
if [[ $UID != 0 ]]; then
	myerror "bạn cần quyền root để chạy chương trình này"
	exit 1
fi

#-------------------------------------------------
# swap
if [ "$SWAP_PARTITION" != "" ]; then
	myinfo "Tạo phân vùng SWAP và sử dụng ${SWAP_PARTITION} cho bộ nhớ swap ..."
	if mkswap $SWAP_PARTITION; then
		myinfo "tạo phân vùng SWAP $SWAP_PARTITION thành công."
		swapon $SWAP_PARTITION
	else
		myerror "trong khi tạo phân vùng SWAP gặp lỗi ở trên."
		exit 1
	fi
else
	myerror "Cần phải định nghĩa phân vùng swap trong SWAP_PARTITION !!!"
	exit 1
fi


# /boot 
if [ "$BOOT_PARTITION" != "" ]; then
	myinfo "Tạo phân vùng /boot ..."
	if mkfs.ext3 $BOOT_PARTITION; then
		myinfo "tạo phân vùng /boot $BOOT_PARTITION thành công"
	else
		myerror "trong khi tạo phân vùng /boot gặp lỗi ở trên."
		exit 1
	fi
fi

# /
msg_info="tạo hệ thống hồ sơ dạng $ROOT_FS trên $ROOT_PARTITION thành công."
msg_error="trong trong khi tạo hệ thống hồ sơ dạng $ROOT_FS trên $ROOT_PARTITION gặp lỗi ở trên"
if [ "$ROOT_PARTITION" != "" ]; then
	if mkfs.$ROOT_FS $ROOT_PARTITION; then
		myinfo "${msg_info}"
	else
		myerror "${msg_error}"
		exit 1
	fi
else
	myerror "Cần phải định nghĩa phân vùng gốc trong ROOT_PARTITION !!!"
	exit 1
fi


mount $ROOT_PARTITION $myroot
mkdir $myroot/{boot,dev,proc,sys}
chmod 1777 $myroot/dev
mount /dev $myroot/dev/ -o bind
mount -t proc none $myroot/proc

if [ "$BOOT_PARTITION" != "" ]; then
	mount $BOOT_PARTITION $myroot/boot
fi

myinfo "Tạo file /etc/profile ... "
#----------------- /etc/profile ---------------------------
cat > $f_profile <<PROFILE
# /etc/profile:
#
# That this file is used by any Bourne-shell derivative to setup the
# environment for login shells.

if [ -e "/etc/profile.env" ]; then
	. /etc/profile.env
fi

umask 022

if [ "$EUID" = 0 ] || [ "`/bin/whoami`" = 'root' ]; then
	PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ROOTPATH}"
else
	PATH="/usr/local/bin:/usr/bin:/bin:${PATH}"
fi
export PATH
unset ROOTPATH

# Extract the value of EDITOR
[ -z "$EDITOR" ] && EDITOR="`. /etc/rc.conf 2>/dev/null; echo $EDITOR`"
[ -z "$EDITOR" ] && EDITOR="/bin/nano"
export EDITOR

if [ -n "${BASH_VERSION}" ]; then
	if [ -f /etc/bash/bashrc ]; then
		. /etc/bash/bashrc
	else
		PS1='\u@\h \w \$ '
	fi
else
	PS1="`whoami`@`uname -n | cut -f1 -d.` \$ "
fi
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias ls='ls --color=auto'
alias ll='ls --color=auto -l'
alias grep='grep --color=auto'

PROFILE

source $f_profile

#--------- Copy files ----------------------------------------------------
myinfo "Đang chép thư mục cần thiết vào ổ cứng ..."
myinfo "Xin vui lòng chờ đợi"
time cp -a /mnt/livecd/{bin,boot,lib,opt,sbin,usr} /etc /home/ /root /tmp /var $myroot/

# ChuyÃ¡Â»Æn sang mÃÂ´i trÃÂ°Ã¡Â»Âng chroot
#######chroot $myroot /bin/bash

rm $myroot/etc/runlevels/default/mkxf86config
#rc-update del  mkxf86config
# * mkxf86config removed from the following runlevels: default
# * rc-update complete.

ln -s /etc/init.d/domainname $myroot/etc/runlevels/default/domainname
#rc-update add domainname default
# * domainname added to runlevel default
# * rc-update complete.

myinfo "Xác lập thông tin múi giờ cho hệ thống"
settimezone $myroot

sed -i -e '/^.*12345:respawn:\/sbin\/agetty -nl/d;/#c.*:12345:respawn:\/sbin\/agetty/s|^#c|c|g;' $f_inittab

myinfo "Tạo file /etc/fstab ... "
#----------- /etc/fstab ---------------------------------
cat > $f_fstab <<FSTAB

# NOTE: If your BOOT partition is ReiserFS, add the notail option to opts.
###$BOOT_PARTITION		/boot	$BOOT_FS	noatime	1 2
$ROOT_PARTITION		/		$ROOT_FS	noatime			0 1
$SWAP_PARTITION		none	swap		sw				0 0

/dev/cdroms/cdrom0 /mnt/cdrom  iso9660 noauto,ro 0 0
#/dev/fd0	/mnt/floppy	auto	noauto		0 0

# NOTE: The next line is critical for boot!
proc		/proc	proc		defaults	0 0

#  use almost no memory if not populated with files)
shm	/dev/shm	tmpfs	nodev,nosuid,noexec	0 0

FSTAB

if [ "$BOOT_PARTITION" != "" ]; then
	sed -i 's/###//' $f_fstab
fi

myinfo "Tạo file /etc/hosts ... "
#----------- /etc/hosts ---------------------------------------
cat > $f_hosts <<HOSTS
127.0.0.1   "$myhost.$mydomain" $myhost  localhost
# IPV6 versions of localhost and co
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
HOSTS

cat > $f_hostname <<HOSTNAME
HOSTNAME="$myhost"
HOSTNAME

cat > $f_domainname <<DOMAINNAME
OVERRIDE=1
DNSDOMAIN="$mydomain"
DOMAINNAME

# nano -w /etc/conf.d/net

myinfo "Xác lập cấu hình cho Grub ... "
#-------- grub.conf -------------------------------------------------
cat > $f_grub_conf <<GRUBCONF1
# Which listing to boot as default. 0 is the first, 1 the second etc.
default 0
# How many seconds to wait before the default listing is booted.
timeout 30
# Nice, fat splash-image to spice things up :)
# Comment out if you don't have a graphics card installed
splashimage=($GRUB_LINUX_ROOT,0)/grub/splash.xpm.gz

title=$GRUB_LINUX_TITLE
  root ($GRUB_LINUX_ROOT,0)
  kernel /kernel-$mykernel root=$ROOT_PARTITION

title=$GRUB_LINUX_TITLE (with initrd)
  root ($GRUB_LINUX_ROOT,0)
  kernel /kernel-$mykernel root=$ROOT_PARTITION
  initrd /initrd-$mykernel

GRUBCONF1

if [ "$GRUB_WIN_TITLE" != "" ]
then
cat >> $f_grub_conf <<GRUBCONF2

title $GRUB_WIN_TITLE
  rootnoverify ($GRUB_WIN_ROOT,0)
  chainloader +1

GRUBCONF2
fi

if grub-install --root-directory=$myroot $GRUB_DEVICE >/dev/null; then
	myinfo "Grub cài đặt thành công"
else
	myerror "trong quá trình cài Grub gặp lỗi ở trên"
fi

# Exit chroot
#exit

umount $myroot/proc $myroot/dev
#
cd $myroot/dev
mknod -m 660 console c 5 1
mknod -m 660 null c 1 3
cd /
umount $myroot/boot $myroot

echo ""
myinfo "Quá trình cài đặt lên đĩa cứng kết thúc"
myinfo "Bạn có thể khởi động lại hệ thống với lệnh reboot !"
