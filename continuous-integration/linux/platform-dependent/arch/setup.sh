#!/bin/bash

pacman -Syu --noconfirm --needed \
       clang \
       clinfo \
       cmake \
       diffutils \
       fakeroot \
       git \
       intel-tbb \
       ncurses \
       ninja \
       numactl \
       python-pip \
       shellcheck \
       sudo \
       wget \
    || exit $?

function aur_install {
    PACKAGE=$1; shift
    VERSION_HASH=$1; shift
    IGNORE_DEPS=$*
    TMP_DIR=$(sudo -u nobody mktemp --tmpdir --directory zivid-python-aur-install-XXXX) || exit $?
    git clone https://aur.archlinux.org/$PACKAGE.git $TMP_DIR || exit $?
    if [[ -n $VERSION_HASH ]] ; then
        git --git-dir="$TMP_DIR/.git" --work-tree="$TMP_DIR" checkout $VERSION_HASH || exit $?
    fi
    pushd $TMP_DIR || exit $?
    for dep in $IGNORE_DEPS; do
        sed -i s/\'$dep\'//g PKGBUILD || exit $?
    done || exit $?
    PKGEXT=.pkg.tar sudo -E -u nobody makepkg || exit $?
    pacman -U --noconfirm ./*$PACKAGE*.tar || exit $?
    popd || exit $?
    rm -r $TMP_DIR || exit $?
}

# https://bugs.archlinux.org/task/69563 (core/glibc 2.33 prevents Archlinux runing under systemd-nspawn)
wget --quiet https://archive.archlinux.org/packages/g/glibc/glibc-2.32-5-x86_64.pkg.tar.zst -O /tmp/glib.pkg.tar.zst || exit $?
wget --quiet https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-10.2.0-4-x86_64.pkg.tar.zst -O /tmp/gcc-libs.pkg.tar.zst || exit $?
pacman --noconfirm -U /tmp/glib.pkg.tar.zst /tmp/gcc-libs.pkg.tar.zst || exit $?

# Use so file from ncurses instead of ncurses5-compat-libs
# as dependency for intel-opencl-runtime
ln -s /usr/lib/libtinfo.so.{6,5} || exit $?
aur_install intel-opencl-runtime a7db4fe8cfa872078034f7966bb2def788bf8e5d ncurses5-compat-libs || exit $?

aur_install zivid-telicam-driver baa42c8f93549fbf1f72755c89044a2b2553e190 || exit $?
aur_install zivid a93adfac62fc4bb934a4df41b8373bdf93dab08f || exit $?
