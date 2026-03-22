#!/bin/sh
set -e
TMP_DIR=`mktemp -d ./tmp.XXXXXXXX`
mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}"
: "${DISTFILES_BASE:=https://distfiles.gentoo.org}"
: "${KEYSERVER:=https://keys.gentoo.org}"
: "${WGET:=wget -T 5}"

gpg --auto-key-locate=clear,nodefault,wkd --locate-key releng@gentoo.org

printf 'arch: '
read -r ARCH
printf 'type: '
read -r TYPE
printf 'install [N/y]: '
read -r INSTALL

case "${INSTALL}" in
	[yY]*)
		printf 'disk: '
		read -r DISK

		printf 'preferred partitioner: '
		read -r PARTER
		"${PARTER}" "${DISK}"

		printf 'uefi [N/y]: '
		read -r UEFI_

		case "${UEFI_}" in
			[yY])
				UEFI=1
				;;
			*)
				UEFI=0
				;;
		esac

		[ "${UEFI}" -ne 0 ] &&
			{
				printf 'efi part: '
				read -r EFI_PART

				mkfs.vfat -F 32 "${EFI_PART}"
			}

		printf 'root part: '
		read -r ROOT_PART

		printf 'root formatter: '
		read -r ROOT_FMTR

		"${ROOT_FMTR}" "${ROOT_PART}"

		mount "${ROOT_PART}" /mnt

		cd ..
		mv "${TMP_DIR}" /mnt
		cd "/mnt/${TMP_DIR}"
		;;
	*)
		:
		;;
esac

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
read -r CHOICE

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

case "${INSTALL}" in
	[yY])
		:
		;;
	*)
		exit 1
		;;
esac

echo 'unpacking stage3'
tar xpf "${FILENAME}" -C /mnt

vi /mnt/etc/resolv.conf
vi /mnt/etc/portage/make.conf

mount -t proc none /mnt/proc
mount -t devtmpfs none /mnt/dev
mount -t sysfs none /mnt/sys

cp /etc/resolv.conf /mnt/etc/resolv.conf

emaint -a sync

echo -e 'configure:\n/etc/portage/make.conf\neselect profile/locale\n/etc/timezone\n/etc/locale.gen\nrecommended to use: cpuid2cpuflags gentoolkit\ngcc -march=native -Q --help=target | grep -i march\nexit to continue'
chroot /mnt
chroot /mnt /bin/bash -c "emerge --config sys-libs/timezone-data && locale-gen && env-update && . /etc/profile && emerge -avuDN @world"
echo 'sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE' >> /mnt/etc/portage/package.license
chroot /mnt /bin/bash -c "emerge gentoo-sources grub linux-firmware installkernel dhcpcd $( [ "${UEFI}" -ne 0 ] && echo "efibootmgr" )"
echo -e 'configure:\nfstab\neselect kernel\nbuild and install /usr/src/linux\nexit to continue'
chroot /mnt
mkdir -p /boot/grub
chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
[ "${UEFI}" -ne 0 ] &&
	{
		chroot /mnt /bin/bash -c "grub-install --efi-directory=${EFI_PART}"
	}
||
	{
		chroot /mnt /bin/bash -c "grub-install ${DISK}"
	}

chroot /mnt /bin/bash -c "passwd"

echo 'probably installed'
bash

exit

example shits (example for my pc might not work for u)
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
