#!/bin/sh
set -e
TMP_DIR=`mktemp -d ./tmp.XXXXXXXX`
mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}"
: "${ARCH:=${1:-amd64}}"
: "${TYPE:=${2:-stage3}}"
: "${DISTFILES_BASE:=https://distfiles.gentoo.org}"
: "${KEYSERVER:=https://keys.gentoo.org}"
: "${WGET:=wget -T 5}"

gpg --auto-key-locate=clear,nodefault,wkd --locate-key releng@gentoo.org

DISTFILES="${DISTFILES_BASE}/releases/${ARCH}/autobuilds/"
LATEST_FILE="latest-${TYPE}.txt"
LATEST_URL="${DISTFILES}${LATEST_FILE}"

${WGET} -O "${LATEST_FILE}" "${LATEST_URL}"

gpg --verify "${LATEST_FILE}"

PATHS=$(
	awk '
		/^-----BEGIN PGP SIGNED MESSAGE-----/ {inmsg=1; next}
		/^-----BEGIN PGP SIGNATURE-----/ {exit}
		inmsg && /^[^#[:space:]]/ {print $1}
	' ${LATEST_FILE}
)

set -- $PATHS
shift 1
i=1
for p in "$@"
do
	printf "%d) %s\n" "$i" "$p"
	i=$((i + 1))
done
printf "choose: "
read CHOICE

case ${CHOICE} in
	''|*[!0-9]*) echo "not a number"; exit 1 ;;
esac

if [ "${CHOICE}" -lt 1 ] || [ "${CHOICE}" -gt "$#" ]; then
	echo "out of range"
	exit 1
fi

eval "SELECTED=\${${CHOICE}}"

FULL_URL="${DISTFILES}${SELECTED}"
FILENAME="${SELECTED##*/}"

echo "selected: ${FILENAME}"

getfile()
{
	echo "${FILENAME}${1}"
}

get()
{
	${WGET} -O `getfile ${1}` "${FULL_URL}${1}"
}

get
get .asc
get .DIGESTS
gpg --verify `getfile .asc` `getfile`
gpg --verify `getfile .DIGESTS`
awk '/^# SHA512 HASH/{getline; print; exit}' `getfile .DIGESTS` | sha512sum -c -

mv `getfile` ..
cd ..
rm -rf "${TMP_DIR}"

exit

gentoo shitty install guide (i left out binpkgs cuz fuck you)
do not follow this if u havent installed a gentoo system using the official handbook first
i assume you already know yo shit
partition yo shit
format that shit
mount that shit
cd to that shit
run this script
use this big fat motherfucker
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
actually shi dont use v since u probly on vesa or gop
mount proc devtmpfs sysfs to yo shit
chroot . to that shit
set yo /etc/resolv.conf
example nameserver 1.1.1.1
emaint -a sync that shit
recommend emerging tmux and your favorite editor by this stage as well as cpuid2cpuflags for CPU_FLAGS_*
and gentoolkit for good shits
eselect profile list/set if not already set
usually already set in modern tarballs
set yo /etc/portage/make.conf to your good shit
emerge -avuDN @world that shit
echo "Asia/Singapore" > /etc/timezone or whatever region u in
emerge --config sys-libs/timezone-data
maybe do manually `ln -sf /usr/share/zoneinfo/Asia/Singapore /etc/localtime` if no work
edit /etc/locale.gen and uncomment yo shit like en_US
locale-gen
eselect locale list
eselect locale set yo shit
env-update && . /etc/profile
accept firmware like sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE or linux-fw-redistributable
emerge gentoo-sources grub linux-firmware optionally genkernel if you a lazy bastard or efibootmgr if you on uefi
and whatever fucking network shit u use like dhcpcd or networkmanager
and installkernel cuz you not a fucking lilo user
set yo fstab like some /dev/sda1 / ext4 defaults 0 1 or whatever the fuck disk or fs u got
eselect kernel list
eselect kernel set to yo shit
cd /usr/src/linux
do yo thang wit make menuconfig
make install that shit
or just fuckin genkernel if you lazy
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install to yo drive like /dev/sda
or if efi grub-install --efi-directory=/mnt but mount boot partition like /dev/sda1 first
where you mount does not matter unless you want to always mount it in fstab
set up user and password
reboot this bitch

example shits (example for my pc)
im on CPU: 12th Gen Intel(R) Core(TM) i5-12600KF (16) @ 4.90 GHz
      GPU: NVIDIA GeForce RTX 3060 [Discrete]
	  and you might not be
	  so dont blindly copy you dumbahh monkey
make.conf
# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.
COMMON_FLAGS="-march=alderlake -O2 -pipe -flto"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"
MAKEOPTS="-j16" # or however many fakin shit u got
ACCEPT_KEYWORDS="~amd64"

USE="-systemd -kde -gnome X -wayland nvidia cuda nvenc -amdgpu pipewire pulseaudio vulkan opengl dbus vaapi vdpau x264 opus venus"
VIDEO_CARDS="nvidia"
CPU_FLAGS_X86="aes avx avx2 avx_vnni bmi1 bmi2 f16c fma3 mmx mmxext pclmul popcnt rdrand sha sse sse2 sse3 sse4_1 sse4_2 ssse3 vpclmulqd"

QEMU_SOFTMMU_TARGETS="riscv64 x86_64 i386" # or whatever shit u needs
QEMU_USER_TARGETS="riscv64 x86_64 i386"

MODULES_SIGN_KEY="/usr/src/linux/certs/signing_key.pem"
MODULES_SIGN_CERT="/usr/src/linux/certs/signing_key.x509"

# NOTE: This stage was built with the bindist USE flag enabled

# This sets the language of build output to English.
# Please keep this setting intact when reporting bugs.
LC_MESSAGES=C.UTF-8

heres some other common shits for those make.conf options
if thats not ur march u can use gcc -march=native -Q --help=target | grep -i march
VIDEO_CARDS
amdgpu radeonsi
intel iris
virtio

how to fucking update
emaint -a sync
emerge -avuDN @world
emerge -va @preserved-rebuild || revdep-rebuild
emerge -vac
eclean-dist
dispatch-conf
eselect news read

and if linux updated u needa eselect yo kernel then zcat /proc/config.gz to .config
and if u didnt have config.gz enabled check /boot
and if config not there then u just a dumbahh mf
and then just rebuild and reinstall and then reconfig grub
