# syntax=docker/dockerfile:1.4
# BuildKit is required to build this Dockerfile

# Based on LFS 11.1-systemd (March 1st, 2022)

###############################
# II. Preparing for the Build #
###############################

# All multi-line scripts are run using this command
ARG SH="sh -eu"

ARG LFS=/lfs
ARG LFS_TGT=x86_64-lfs-linux-gnu
ARG LFS_USER=lfs
ARG LFS_GROUOP=lfs
ARG LFS_HOSTNAME=lfs
ARG ENABLE_TESTS=false
ARG MAKEFLAGS=-j8

ARG ISO_VOLUME_ID=LFS
ARG ISO_GRUB_PRELOAD_MODULES="part_gpt part_msdos linux normal iso9660 udf all_video video_fb search configfile echo cat"

############################
# Image 0. Source Tarballs #
############################
FROM scratch AS sources

# NOTE: Even if this list is updated, BuildKit will only rebuild layers that use the updated files
# NOTE: If you have already downloaded all required source files, you can
# put all of them into a local directory sources/, then uncomment the following line
# to REPLACE all ADD commands in this stage.
# ADD sources /

ADD https://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz .
ADD https://download.savannah.gnu.org/releases/attr/attr-2.5.1.tar.gz .
ADD https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.xz .
ADD https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.xz .
ADD https://ftp.gnu.org/gnu/bash/bash-5.1.16.tar.gz .
ADD https://github.com/gavinhoward/bc/releases/download/5.2.2/bc-5.2.2.tar.xz .
ADD https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.xz .
ADD https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz .
ADD https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz .
ADD https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz .
ADD https://ftp.gnu.org/gnu/coreutils/coreutils-9.0.tar.xz .
ADD https://dbus.freedesktop.org/releases/dbus/dbus-1.12.20.tar.gz .
ADD https://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz .
ADD https://ftp.gnu.org/gnu/diffutils/diffutils-3.8.tar.xz .
ADD https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.46.5/e2fsprogs-1.46.5.tar.gz .
ADD https://sourceware.org/ftp/elfutils/0.186/elfutils-0.186.tar.bz2 .
ADD https://github.com/eudev-project/eudev/releases/download/v3.2.11/eudev-3.2.11.tar.gz .
ADD https://prdownloads.sourceforge.net/expat/expat-2.4.6.tar.xz .
ADD https://prdownloads.sourceforge.net/expect/expect5.45.4.tar.gz .
ADD https://astron.com/pub/file/file-5.41.tar.gz .
ADD https://ftp.gnu.org/gnu/findutils/findutils-4.9.0.tar.xz .
ADD https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz .
ADD https://ftp.gnu.org/gnu/gawk/gawk-5.1.1.tar.xz .
ADD https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz .
ADD https://ftp.gnu.org/gnu/gdbm/gdbm-1.23.tar.gz .
ADD https://ftp.gnu.org/gnu/gettext/gettext-0.21.tar.xz .
ADD https://ftp.gnu.org/gnu/glibc/glibc-2.35.tar.xz .
ADD https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz .
ADD https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz .
ADD https://ftp.gnu.org/gnu/grep/grep-3.7.tar.xz .
ADD https://ftp.gnu.org/gnu/groff/groff-1.22.4.tar.gz .
ADD https://ftp.gnu.org/gnu/grub/grub-2.06.tar.xz .
ADD https://ftp.gnu.org/gnu/gzip/gzip-1.11.tar.xz .
ADD https://github.com/Mic92/iana-etc/releases/download/20220207/iana-etc-20220207.tar.gz .
ADD https://ftp.gnu.org/gnu/inetutils/inetutils-2.2.tar.xz .
ADD https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz .
ADD https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-5.16.0.tar.xz .
ADD https://files.pythonhosted.org/packages/source/J/Jinja2/Jinja2-3.0.3.tar.gz .
ADD https://www.kernel.org/pub/linux/utils/kbd/kbd-2.4.0.tar.xz .
ADD https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-29.tar.xz .
ADD https://www.greenwoodsoftware.com/less/less-590.tar.gz .
ADD https://www.linuxfromscratch.org/lfs/downloads/11.1/lfs-bootscripts-20210608.tar.xz .
ADD https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.63.tar.xz .
ADD https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz .
ADD https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.5.tar.gz .
ADD https://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.xz .
ADD https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.16.9.tar.xz .
ADD https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz .
ADD https://ftp.gnu.org/gnu/make/make-4.3.tar.gz .
ADD https://download.savannah.gnu.org/releases/man-db/man-db-2.10.1.tar.xz .
ADD https://www.kernel.org/pub/linux/docs/man-pages/man-pages-5.13.tar.xz .
ADD https://files.pythonhosted.org/packages/source/M/MarkupSafe/MarkupSafe-2.0.1.tar.gz .
ADD https://github.com/mesonbuild/meson/releases/download/0.61.1/meson-0.61.1.tar.gz .
ADD https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz .
ADD https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz .
ADD https://invisible-mirror.net/archives/ncurses/ncurses-6.3.tar.gz .
ADD https://github.com/ninja-build/ninja/archive/v1.10.2/ninja-1.10.2.tar.gz .
ADD https://www.openssl.org/source/openssl-3.0.1.tar.gz .
ADD https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz .
ADD https://www.cpan.org/src/5.0/perl-5.34.0.tar.xz .
ADD https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz .
ADD https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-3.3.17.tar.xz .
ADD https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.4.tar.xz .
ADD https://www.python.org/ftp/python/3.10.2/Python-3.10.2.tar.xz .
ADD https://www.python.org/ftp/python/doc/3.10.2/python-3.10.2-docs-html.tar.bz2 .
ADD https://ftp.gnu.org/gnu/readline/readline-8.1.2.tar.gz .
ADD https://ftp.gnu.org/gnu/sed/sed-4.8.tar.xz .
ADD https://github.com/shadow-maint/shadow/releases/download/v4.11.1/shadow-4.11.1.tar.xz .
ADD https://www.infodrom.org/projects/sysklogd/download/sysklogd-1.5.1.tar.gz .
ADD https://github.com/systemd/systemd/archive/v250/systemd-250.tar.gz .
ADD https://anduin.linuxfromscratch.org/LFS/systemd-man-pages-250.tar.xz .
ADD https://download.savannah.gnu.org/releases/sysvinit/sysvinit-3.01.tar.xz .
ADD https://ftp.gnu.org/gnu/tar/tar-1.34.tar.xz .
ADD https://downloads.sourceforge.net/tcl/tcl8.6.12-src.tar.gz .
ADD https://downloads.sourceforge.net/tcl/tcl8.6.12-html.tar.gz .
ADD https://ftp.gnu.org/gnu/texinfo/texinfo-6.8.tar.xz .
ADD https://www.iana.org/time-zones/repository/releases/tzdata2021e.tar.gz .
ADD https://anduin.linuxfromscratch.org/LFS/udev-lfs-20171102.tar.xz .
ADD https://www.kernel.org/pub/linux/utils/util-linux/v2.37/util-linux-2.37.4.tar.xz .
ADD https://anduin.linuxfromscratch.org/LFS/vim-8.2.4383.tar.gz .
ADD https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.46.tar.gz .
ADD https://tukaani.org/xz/xz-5.2.5.tar.xz .
ADD https://zlib.net/zlib-1.2.12.tar.xz .
ADD https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz .
ADD https://www.linuxfromscratch.org/patches/lfs/11.1/binutils-2.38-lto_fix-1.patch .
ADD https://www.linuxfromscratch.org/patches/lfs/11.1/bzip2-1.0.8-install_docs-1.patch .
ADD https://www.linuxfromscratch.org/patches/lfs/11.1/coreutils-9.0-i18n-1.patch .
ADD https://www.linuxfromscratch.org/patches/lfs/11.1/coreutils-9.0-chmod_fix-1.patch .
ADD https://www.linuxfromscratch.org/patches/lfs/11.1/glibc-2.35-fhs-1.patch .
ADD https://www.linuxfromscratch.org/patches/lfs/11.1/kbd-2.4.0-backspace-1.patch .
ADD https://www.linuxfromscratch.org/patches/lfs/11.1/perl-5.34.0-upstream_fixes-1.patch .
ADD https://www.linuxfromscratch.org/patches/lfs/11.1/sysvinit-3.01-consolidated-1.patch .
ADD https://www.linuxfromscratch.org/patches/lfs/11.1/systemd-250-upstream_fixes-1.patch .
ADD https://www.busybox.net/downloads/binaries/1.28.1-defconfig-multiarch/busybox-x86_64 .

#################
# Image 1. Host #
#################
FROM alpine:3.16 AS host
ARG SH

# 2.2. Host System Requirements
# TODO: remove the mirrors here
RUN apk add --no-cache \
        --repository https://mirrors.ustc.edu.cn/alpine/v3.16/main/ \
        --repository https://mirrors.ustc.edu.cn/alpine/v3.16/community/ \
        --repositories-file /dev/null \
        bash binutils bison \
        coreutils diffutils findutils \
        gawk gcc g++ grep gzip m4 make \
        patch perl python3 sed tar \
        texinfo wget xz shadow

# Change the default shell to bash
RUN <<'EOT' $SH
    ln -svf /bin/bash /bin/sh
    ln -svf /bin/bash /bin/ash
    echo "/bin/bash" >> /etc/shells
    usermod -s /bin/bash root
EOT

ARG LFS
ENV PATH=${LFS}/tools/bin:/bin:/sbin:/usr/bin:/usr/sbin
ENV LC_ALL=POSIX
ENV CONFIG_SITE=${LFS}/usr/share/config.site

# 4.2. Creating a limited directory layout in LFS filesystem
RUN <<'EOT' $SH
    mkdir -pv $LFS $LFS/{etc,var,lib64,sources} $LFS/usr/{bin,lib,sbin}
    ln -sv usr/bin $LFS/bin
    ln -sv usr/lib $LFS/lib
    ln -sv usr/sbin $LFS/sbin
EOT

# 4.3. Adding the LFS User
ARG LFS_USER
ARG LFS_GROUOP
RUN <<'EOT' $SH
    adduser -D -s /bin/bash $LFS_USER
    adduser $LFS_USER $LFS_GROUOP
    chown -Rv $LFS_USER $LFS
EOT
USER ${LFS_USER}

#############################################################
# III. Building the LFS Cross Toolchain and Temporary Tools #
#############################################################

ARG LFS_TGT
ARG MAKEFLAGS

WORKDIR /tmp

# 5.2. Binutils-2.38 - Pass 1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=binutils-2.38.tar.xz,target=binutils-2.38.tar.xz \
<<'EOT' $SH
    tar -xf binutils-2.38.tar.xz
    cd binutils-2.38
    mkdir -v build
    cd build
    ../configure --prefix=$LFS/tools \
                 --with-sysroot=$LFS \
                 --target=$LFS_TGT   \
                 --disable-nls       \
                 --disable-werror
    make
    make install
EOT

# 5.3. GCC-11.2.0 - Pass 1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gcc-11.2.0.tar.xz,target=gcc-11.2.0.tar.xz \
    --mount=from=sources,source=mpfr-4.1.0.tar.xz,target=mpfr-4.1.0.tar.xz \
    --mount=from=sources,source=gmp-6.2.1.tar.xz,target=gmp-6.2.1.tar.xz \
    --mount=from=sources,source=mpc-1.2.1.tar.gz,target=mpc-1.2.1.tar.gz \
<<'EOT' $SH
    tar -xf gcc-11.2.0.tar.xz
    cd gcc-11.2.0
    tar -xf ../mpfr-4.1.0.tar.xz
    mv -v mpfr-4.1.0 mpfr
    tar -xf ../gmp-6.2.1.tar.xz
    mv -v gmp-6.2.1 gmp
    tar -xf ../mpc-1.2.1.tar.gz
    mv -v mpc-1.2.1 mpc
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
    mkdir -v build
    cd build
    ../configure                  \
        --target=$LFS_TGT         \
        --prefix=$LFS/tools       \
        --with-glibc-version=2.35 \
        --with-sysroot=$LFS       \
        --with-newlib             \
        --without-headers         \
        --enable-initfini-array   \
        --disable-nls             \
        --disable-shared          \
        --disable-multilib        \
        --disable-decimal-float   \
        --disable-threads         \
        --disable-libatomic       \
        --disable-libgomp         \
        --disable-libquadmath     \
        --disable-libssp          \
        --disable-libvtv          \
        --disable-libstdcxx       \
        --enable-languages=c,c++
    make
    make install
    cd ..
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
        `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h
EOT

# 5.4. Linux-5.16.9 API Headers
RUN --mount=type=tmpfs \
    --mount=from=sources,source=linux-5.16.9.tar.xz,target=linux-5.16.9.tar.xz \
<<'EOT' $SH
    tar -xf linux-5.16.9.tar.xz
    cd linux-5.16.9
    make mrproper
    make headers
    find usr/include -name '.*' -delete
    rm usr/include/Makefile
    cp -rv usr/include $LFS/usr
EOT

# 5.5. Glibc-2.35
RUN --mount=type=tmpfs \
    --mount=from=sources,source=glibc-2.35.tar.xz,target=glibc-2.35.tar.xz \
    --mount=from=sources,source=glibc-2.35-fhs-1.patch,target=glibc-2.35-fhs-1.patch \
<<'EOT' $SH
    tar -xf glibc-2.35.tar.xz
    cd glibc-2.35
    ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
    ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    patch -Np1 -i ../glibc-2.35-fhs-1.patch
    mkdir -v build
    cd build
    echo "rootsbindir=/usr/sbin" > configparms
    ../configure                           \
        --prefix=/usr                      \
        --host=$LFS_TGT                    \
        --build=$(../scripts/config.guess) \
        --enable-kernel=3.2                \
        --with-headers=$LFS/usr/include    \
        libc_cv_slibdir=/usr/lib
    make
    make DESTDIR=$LFS install
    sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd
    $LFS/tools/libexec/gcc/$LFS_TGT/11.2.0/install-tools/mkheaders
EOT

# 5.6. Libstdc++ from GCC-11.2.0, Pass 1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gcc-11.2.0.tar.xz,target=gcc-11.2.0.tar.xz \
<<'EOT' $SH
    tar -xf gcc-11.2.0.tar.xz
    pushd gcc-11.2.0
    mkdir -v build
    cd build
    ../libstdc++-v3/configure      \
        --host=$LFS_TGT            \
        --build=$(../config.guess) \
        --prefix=/usr              \
        --disable-multilib         \
        --disable-nls              \
        --disable-libstdcxx-pch    \
        --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/11.2.0
    make
    make DESTDIR=$LFS install
EOT

# 6.2. M4-1.4.19
RUN --mount=type=tmpfs \
    --mount=from=sources,source=m4-1.4.19.tar.xz,target=m4-1.4.19.tar.xz \
<<'EOT' $SH
    tar -xf m4-1.4.19.tar.xz
    cd m4-1.4.19
    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
EOT

# 6.3. Ncurses-6.3
RUN --mount=type=tmpfs \
    --mount=from=sources,source=ncurses-6.3.tar.gz,target=ncurses-6.3.tar.gz \
<<'EOT' $SH
    tar -xf ncurses-6.3.tar.gz
    cd ncurses-6.3
    sed -i s/mawk// configure
    mkdir build
    pushd build
    ../configure
    make -C include
    make -C progs tic
    popd
    ./configure --prefix=/usr                \
                --host=$LFS_TGT              \
                --build=$(./config.guess)    \
                --mandir=/usr/share/man      \
                --with-manpage-format=normal \
                --with-shared                \
                --without-debug              \
                --without-ada                \
                --without-normal             \
                --disable-stripping          \
                --enable-widec
    make
    make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
    echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so
EOT

# 6.4. Bash-5.1.16
RUN --mount=type=tmpfs \
    --mount=from=sources,source=bash-5.1.16.tar.gz,target=bash-5.1.16.tar.gz \
<<'EOT' $SH
    tar -xf bash-5.1.16.tar.gz
    cd bash-5.1.16
    ./configure --prefix=/usr                   \
                --build=$(support/config.guess) \
                --host=$LFS_TGT                 \
                --without-bash-malloc
    make
    make DESTDIR=$LFS install
    ln -sv bash $LFS/bin/sh
EOT

# 6.5. Coreutils-9.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=coreutils-9.0.tar.xz,target=coreutils-9.0.tar.xz \
<<'EOT' $SH
    tar -xf coreutils-9.0.tar.xz
    cd coreutils-9.0
    ./configure --prefix=/usr                     \
                --host=$LFS_TGT                   \
                --build=$(build-aux/config.guess) \
                --enable-install-program=hostname \
                --enable-no-install-program=kill,uptime
    make
    make DESTDIR=$LFS install
    mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
    mkdir -pv $LFS/usr/share/man/man8
    mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
    sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8
EOT

# 6.6. Diffutils-3.8
RUN --mount=type=tmpfs \
    --mount=from=sources,source=diffutils-3.8.tar.xz,target=diffutils-3.8.tar.xz \
<<'EOT' $SH
    tar -xf diffutils-3.8.tar.xz
    cd diffutils-3.8
    ./configure --prefix=/usr --host=$LFS_TGT
    make
    make DESTDIR=$LFS install
EOT

# 6.7. File-5.41
RUN --mount=type=tmpfs \
    --mount=from=sources,source=file-5.41.tar.gz,target=file-5.41.tar.gz \
<<'EOT' $SH
    tar -xf file-5.41.tar.gz
    cd file-5.41
    mkdir build
    pushd build
    ../configure --disable-bzlib      \
                 --disable-libseccomp \
                 --disable-xzlib      \
                 --disable-zlib
    make
    popd
    ./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
    make FILE_COMPILE=$(pwd)/build/src/file
    make DESTDIR=$LFS install
EOT

# 6.8. Findutils-4.9.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=findutils-4.9.0.tar.xz,target=findutils-4.9.0.tar.xz \
<<'EOT' $SH
    tar -xf findutils-4.9.0.tar.xz
    cd findutils-4.9.0
    ./configure --prefix=/usr                   \
                --localstatedir=/var/lib/locate \
                --host=$LFS_TGT                 \
                --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
EOT

# 6.9. Gawk-5.1.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gawk-5.1.1.tar.xz,target=gawk-5.1.1.tar.xz \
<<'EOT' $SH
    tar -xf gawk-5.1.1.tar.xz
    cd gawk-5.1.1
    sed -i 's/extras//' Makefile.in
    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
EOT

# 6.10. Grep-3.7
RUN --mount=type=tmpfs \
    --mount=from=sources,source=grep-3.7.tar.xz,target=grep-3.7.tar.xz \
<<'EOT' $SH
    tar -xf grep-3.7.tar.xz
    cd grep-3.7
    ./configure --prefix=/usr --host=$LFS_TGT
    make
    make DESTDIR=$LFS install
EOT

# 6.11. Gzip-1.11
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gzip-1.11.tar.xz,target=gzip-1.11.tar.xz \
<<'EOT' $SH
    tar -xf gzip-1.11.tar.xz
    cd gzip-1.11
    ./configure --prefix=/usr --host=$LFS_TGT
    make
    make DESTDIR=$LFS install
EOT

# 6.12. Make-4.3
RUN --mount=type=tmpfs \
    --mount=from=sources,source=make-4.3.tar.gz,target=make-4.3.tar.gz \
<<'EOT' $SH
    tar -xf make-4.3.tar.gz
    cd make-4.3
    ./configure --prefix=/usr   \
                --without-guile \
                --host=$LFS_TGT \
                --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
EOT

# 6.13. Patch-2.7.6
RUN --mount=type=tmpfs \
    --mount=from=sources,source=patch-2.7.6.tar.xz,target=patch-2.7.6.tar.xz \
<<'EOT' $SH
    tar -xf patch-2.7.6.tar.xz
    pushd patch-2.7.6
    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
EOT

# 6.14. Sed-4.8
RUN --mount=type=tmpfs \
    --mount=from=sources,source=sed-4.8.tar.xz,target=sed-4.8.tar.xz \
<<'EOT' $SH
    tar -xf sed-4.8.tar.xz
    cd sed-4.8
    ./configure --prefix=/usr --host=$LFS_TGT
    make
    make DESTDIR=$LFS install
EOT

# 6.15. Tar-1.34
RUN --mount=type=tmpfs \
    --mount=from=sources,source=tar-1.34.tar.xz,target=tar-1.34.tar.xz \
<<'EOT' $SH
    tar -xf tar-1.34.tar.xz
    cd tar-1.34
    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(build-aux/config.guess)
    make
    make DESTDIR=$LFS install
EOT

# 6.16. Xz-5.2.5
RUN --mount=type=tmpfs \
    --mount=from=sources,source=xz-5.2.5.tar.xz,target=xz-5.2.5.tar.xz \
<<'EOT' $SH
    tar -xf xz-5.2.5.tar.xz
    cd xz-5.2.5
    ./configure --prefix=/usr                     \
                --host=$LFS_TGT                   \
                --build=$(build-aux/config.guess) \
                --disable-static                  \
                --docdir=/usr/share/doc/xz-5.2.5
    make
    make DESTDIR=$LFS install
EOT

# 6.17. Binutils-2.38 - Pass 2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=binutils-2.38.tar.xz,target=binutils-2.38.tar.xz \
<<'EOT' $SH
    tar -xf binutils-2.38.tar.xz
    cd binutils-2.38
    sed '6009s/$add_dir//' -i ltmain.sh
    mkdir -v build
    cd build
    ../configure --prefix=/usr              \
                 --build=$(../config.guess) \
                 --host=$LFS_TGT            \
                 --disable-nls              \
                 --enable-shared            \
                 --disable-werror           \
                 --enable-64-bit-bfd
    make
    make DESTDIR=$LFS install
EOT

# 6.18. GCC-11.2.0 - Pass 2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gcc-11.2.0.tar.xz,target=gcc-11.2.0.tar.xz \
    --mount=from=sources,source=mpfr-4.1.0.tar.xz,target=mpfr-4.1.0.tar.xz \
    --mount=from=sources,source=gmp-6.2.1.tar.xz,target=gmp-6.2.1.tar.xz \
    --mount=from=sources,source=mpc-1.2.1.tar.gz,target=mpc-1.2.1.tar.gz \
<<'EOT' $SH
    tar -xf gcc-11.2.0.tar.xz
    cd gcc-11.2.0
    tar -xf ../mpfr-4.1.0.tar.xz
    mv -v mpfr-4.1.0 mpfr
    tar -xf ../gmp-6.2.1.tar.xz
    mv -v gmp-6.2.1 gmp
    tar -xf ../mpc-1.2.1.tar.gz
    mv -v mpc-1.2.1 mpc
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
    mkdir -v build
    cd build
    mkdir -pv $LFS_TGT/libgcc
    ln -s ../../../libgcc/gthr-posix.h $LFS_TGT/libgcc/gthr-default.h
    ../configure --build=$(../config.guess) \
                 --host=$LFS_TGT            \
                 --prefix=/usr              \
                 CC_FOR_TARGET=$LFS_TGT-gcc \
                 --with-build-sysroot=$LFS  \
                 --enable-initfini-array    \
                 --disable-nls              \
                 --disable-multilib         \
                 --disable-decimal-float    \
                 --disable-libatomic        \
                 --disable-libgomp          \
                 --disable-libquadmath      \
                 --disable-libssp           \
                 --disable-libvtv           \
                 --disable-libstdcxx        \
                 --enable-languages=c,c++
    make
    make DESTDIR=$LFS install
    ln -sv gcc $LFS/usr/bin/cc
EOT

# 7.2. Changing Ownership
USER root
RUN chown -R root:root $LFS

######################
# Image 2. Toolchain #
######################
FROM scratch AS toolchain
ARG SH
ARG LFS

# Copy the LFS root directory from previous build
COPY --from=host ${LFS} /

# NOTE: section "7.3. Preparing Virtual Kernel File Systems" is managed by Docker during the build
# We need to add them manually later (see iso-builder)

# 7.4. Entering the Chroot Environment
ENV HOME=/root
ENV PS1='[toolchain] \u:\w\$ '
ENV PATH=/bin:/usr/bin:/usr/sbin
ENTRYPOINT [ "/bin/bash" ]

# 7.5. Creating Directories
RUN <<'EOT' $SH
    mkdir -pv /{boot,home,mnt,opt,srv,run}
    mkdir -pv /etc/{opt,sysconfig}
    mkdir -pv /lib/firmware
    mkdir -pv /media/{floppy,cdrom}
    mkdir -pv /usr/{,local/}{include,src}
    mkdir -pv /usr/local/{bin,lib,sbin}
    mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
    mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
    mkdir -pv /usr/{,local/}share/man/man{1..8}
    mkdir -pv /var/{cache,local,log,mail,opt,spool}
    mkdir -pv /var/lib/{color,misc,locate}
    ln -sfv /run /var/run
    ln -sfv /run/lock /var/lock
    install -dv -m 0750 /root
    install -dv -m 1777 /tmp /var/tmp
EOT

# 7.6. Creating Essential Files and Symlinks
# Skipping `ln -sv /proc/self/mounts /etc/mtab` since it's created by Docker
# Skipping setting /etc/hosts since it's managed by Docker
ADD <<-'EOT' /etc/passwd
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/usr/bin/false
EOT

ADD <<-'EOT' /etc/group
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOT

RUN <<'EOT' $SH
    echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
    echo "tester:x:101:" >> /etc/group
    install -o tester -d /home/tester
    touch /var/log/{btmp,lastlog,faillog,wtmp}
    chgrp -v utmp /var/log/lastlog
    chmod -v 664  /var/log/lastlog
    chmod -v 600  /var/log/btmp
EOT

ARG LFS_TGT
ARG MAKEFLAGS

WORKDIR /tmp

# 7.7. Libstdc++ from GCC-11.2.0, Pass 2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gcc-11.2.0.tar.xz,target=gcc-11.2.0.tar.xz \
<<'EOT' $SH
    tar -xf gcc-11.2.0.tar.xz
    cd gcc-11.2.0
    ln -s gthr-posix.h libgcc/gthr-default.h
    mkdir -v build
    cd build
    ../libstdc++-v3/configure           \
        CXXFLAGS="-g -O2 -D_GNU_SOURCE" \
        --prefix=/usr                   \
        --disable-multilib              \
        --disable-nls                   \
        --host=$LFS_TGT                 \
        --disable-libstdcxx-pch
    make
    make install
EOT

# 7.8. Gettext-0.21
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gettext-0.21.tar.xz,target=gettext-0.21.tar.xz \
<<'EOT' $SH
    tar -xf gettext-0.21.tar.xz
    cd gettext-0.21
    ./configure --disable-shared
    make
    cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
EOT

# 7.9. Bison-3.8.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=bison-3.8.2.tar.xz,target=bison-3.8.2.tar.xz \
<<'EOT' $SH
    tar -xf bison-3.8.2.tar.xz
    cd bison-3.8.2
    ./configure --prefix=/usr \
                --docdir=/usr/share/doc/bison-3.8.2
    make
    make install
EOT

# 7.10. Perl-5.34.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=perl-5.34.0.tar.xz,target=perl-5.34.0.tar.xz \
<<'EOT' $SH
    tar -xf perl-5.34.0.tar.xz
    cd perl-5.34.0
    sh Configure -des                               \
        -Dprefix=/usr                               \
        -Dvendorprefix=/usr                         \
        -Dprivlib=/usr/lib/perl5/5.34/core_perl     \
        -Darchlib=/usr/lib/perl5/5.34/core_perl     \
        -Dsitelib=/usr/lib/perl5/5.34/site_perl     \
        -Dsitearch=/usr/lib/perl5/5.34/site_perl    \
        -Dvendorlib=/usr/lib/perl5/5.34/vendor_perl \
        -Dvendorarch=/usr/lib/perl5/5.34/vendor_perl
    make
    make install
EOT

# 7.11. Python-3.10.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=Python-3.10.2.tar.xz,target=Python-3.10.2.tar.xz \
<<'EOT' $SH
    tar -xf Python-3.10.2.tar.xz
    cd Python-3.10.2
    ./configure --prefix=/usr   \
                --enable-shared \
                --without-ensurepip
    make
    make install
EOT

# 7.12. Texinfo-6.8
RUN --mount=type=tmpfs \
    --mount=from=sources,source=texinfo-6.8.tar.xz,target=texinfo-6.8.tar.xz \
<<'EOT' $SH
    tar -xf texinfo-6.8.tar.xz
    cd texinfo-6.8
    sed -e 's/__attribute_nonnull__/__nonnull/' \
        -i gnulib/lib/malloc/dynarray-skeleton.c
    ./configure --prefix=/usr
    make
    make install
EOT

# 7.13. Util-linux-2.37.4
RUN --mount=type=tmpfs \
    --mount=from=sources,source=util-linux-2.37.4.tar.xz,target=util-linux-2.37.4.tar.xz \
<<'EOT' $SH
    tar -xf util-linux-2.37.4.tar.xz
    cd util-linux-2.37.4
    mkdir -pv /var/lib/hwclock
    ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
                --libdir=/usr/lib    \
                --docdir=/usr/share/doc/util-linux-2.37.4 \
                --disable-chfn-chsh  \
                --disable-login      \
                --disable-nologin    \
                --disable-su         \
                --disable-setpriv    \
                --disable-runuser    \
                --disable-pylibmount \
                --disable-static     \
                --without-python     \
                runstatedir=/run
    make
    make install
EOT

# 7.14. Cleaning up and Saving the Temporary System
RUN <<'EOT' $SH
    rm -rf /usr/share/{info,man,doc}/*
    find /usr/{lib,libexec} -name \*.la -delete
    rm -rf /tools
EOT

###############################
# IV. Building the LFS System #
###############################

###################
# Image 3. System #
###################
FROM toolchain AS system
ARG SH
ARG ENABLE_TESTS
ARG MAKEFLAGS

WORKDIR /tmp

# 8.3. Man-pages-5.13
RUN --mount=type=tmpfs \
    --mount=from=sources,source=man-pages-5.13.tar.xz,target=man-pages-5.13.tar.xz \
<<'EOT' $SH
    tar -xf man-pages-5.13.tar.xz
    cd man-pages-5.13
    make prefix=/usr install
EOT

# 8.4. Iana-Etc-20220207
RUN --mount=type=tmpfs \
    --mount=from=sources,source=iana-etc-20220207.tar.gz,target=iana-etc-20220207.tar.gz \
<<'EOT' $SH
    tar -xf iana-etc-20220207.tar.gz
    cd iana-etc-20220207
    cp services protocols /etc
EOT

# 8.5. Glibc-2.35
# TODO: make the result of `make check` more visible
RUN --mount=type=tmpfs \
    --mount=from=sources,source=glibc-2.35.tar.xz,target=glibc-2.35.tar.xz \
    --mount=from=sources,source=glibc-2.35-fhs-1.patch,target=glibc-2.35-fhs-1.patch \
<<'EOT' $SH
    tar -xf glibc-2.35.tar.xz
    cd glibc-2.35
    patch -Np1 -i ../glibc-2.35-fhs-1.patch
    mkdir -v build
    cd build
    echo "rootsbindir=/usr/sbin" > configparms
    ../configure --prefix=/usr                   \
                 --disable-werror                \
                 --enable-kernel=3.2             \
                 --enable-stack-protector=strong \
                 --with-headers=/usr/include     \
                 libc_cv_slibdir=/usr/lib
    make
    if $ENABLE_TESTS; then (make check || true); fi
    touch /etc/ld.so.conf
    sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
    make install
    sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
    cp -v ../nscd/nscd.conf /etc/nscd.conf
    mkdir -pv /var/cache/nscd
    install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
    install -v -Dm644 ../nscd/nscd.service /usr/lib/systemd/system/nscd.service
    mkdir -pv /usr/lib/locale
    localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
    localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
    localedef -i de_DE -f ISO-8859-1 de_DE
    localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
    localedef -i de_DE -f UTF-8 de_DE.UTF-8
    localedef -i el_GR -f ISO-8859-7 el_GR
    localedef -i en_GB -f ISO-8859-1 en_GB
    localedef -i en_GB -f UTF-8 en_GB.UTF-8
    localedef -i en_HK -f ISO-8859-1 en_HK
    localedef -i en_PH -f ISO-8859-1 en_PH
    localedef -i en_US -f ISO-8859-1 en_US
    localedef -i en_US -f UTF-8 en_US.UTF-8
    localedef -i es_ES -f ISO-8859-15 es_ES@euro
    localedef -i es_MX -f ISO-8859-1 es_MX
    localedef -i fa_IR -f UTF-8 fa_IR
    localedef -i fr_FR -f ISO-8859-1 fr_FR
    localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
    localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
    localedef -i is_IS -f ISO-8859-1 is_IS
    localedef -i is_IS -f UTF-8 is_IS.UTF-8
    localedef -i it_IT -f ISO-8859-1 it_IT
    localedef -i it_IT -f ISO-8859-15 it_IT@euro
    localedef -i it_IT -f UTF-8 it_IT.UTF-8
    localedef -i ja_JP -f EUC-JP ja_JP
    (localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true)
    localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
    localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
    localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
    localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
    localedef -i se_NO -f UTF-8 se_NO.UTF-8
    localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
    localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
    localedef -i zh_CN -f GB18030 zh_CN.GB18030
    localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
    localedef -i zh_TW -f UTF-8 zh_TW.UTF-8
EOT

# 8.5.2. Configuring Glibc
# NOTE: defaulting to US eastern time
ADD <<-'EOT' /etc/nsswitch.conf
passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files
EOT

ADD <<-'EOT' /etc/ld.so.conf
/usr/local/lib
/opt/lib

# Add an include directory
include /etc/ld.so.conf.d/*.conf
EOT

RUN --mount=type=tmpfs \
    --mount=from=sources,source=tzdata2021e.tar.gz,target=tzdata2021e.tar.gz \
<<'EOT' $SH
    tar -xf tzdata2021e.tar.gz
    ZONEINFO=/usr/share/zoneinfo
    mkdir -pv $ZONEINFO/{posix,right}
    for tz in etcetera southamerica northamerica europe africa antarctica \
            asia australasia backward; do
        zic -L /dev/null   -d $ZONEINFO       ${tz} || exit 1;
        zic -L /dev/null   -d $ZONEINFO/posix ${tz} || exit 1;
        zic -L leapseconds -d $ZONEINFO/right ${tz} || exit 1;
    done
    cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
    zic -d $ZONEINFO -p America/New_York
    unset ZONEINFO
    ln -sfv /usr/share/zoneinfo/America/New_York /etc/localtime
    mkdir -pv /etc/ld.so.conf.d
EOT

# 8.6. Zlib-1.2.12
# NOTE: the original LFS 11.1 uses Zlib-1.2.11
RUN --mount=type=tmpfs \
    --mount=from=sources,source=zlib-1.2.12.tar.xz,target=zlib-1.2.12.tar.xz \
<<'EOT' $SH
    tar -xf zlib-1.2.12.tar.xz
    cd zlib-1.2.12
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    rm -fv /usr/lib/libz.a
EOT

# 8.7. Bzip2-1.0.8
RUN --mount=type=tmpfs \
    --mount=from=sources,source=bzip2-1.0.8.tar.gz,target=bzip2-1.0.8.tar.gz \
    --mount=from=sources,source=bzip2-1.0.8-install_docs-1.patch,target=bzip2-1.0.8-install_docs-1.patch \
<<'EOT' $SH
    tar -xf bzip2-1.0.8.tar.gz
    cd bzip2-1.0.8
    patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
    sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
    sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
    make -f Makefile-libbz2_so
    make clean
    make
    make PREFIX=/usr install
    cp -av libbz2.so.* /usr/lib
    ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
    cp -v bzip2-shared /usr/bin/bzip2
    ln -sfv bzip2 /usr/bin/bzcat
    ln -sfv bzip2 /usr/bin/bunzip2
    rm -fv /usr/lib/libbz2.a
EOT

# 8.8. Xz-5.2.5
RUN --mount=type=tmpfs \
    --mount=from=sources,source=xz-5.2.5.tar.xz,target=xz-5.2.5.tar.xz \
<<'EOT' $SH
    tar -xf xz-5.2.5.tar.xz
    cd xz-5.2.5
    ./configure --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/xz-5.2.5
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    rm -fv /usr/lib/libz.a
EOT

# 8.9. Zstd-1.5.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=zstd-1.5.2.tar.gz,target=zstd-1.5.2.tar.gz \
<<'EOT' $SH
    tar -xf zstd-1.5.2.tar.gz
    cd zstd-1.5.2
    make
    if $ENABLE_TESTS; then make check; fi
    make prefix=/usr install
    rm -fv /usr/lib/libzstd.a
EOT

# 8.10. File-5.41
RUN --mount=type=tmpfs \
    --mount=from=sources,source=file-5.41.tar.gz,target=file-5.41.tar.gz \
<<'EOT' $SH
    tar -xf file-5.41.tar.gz
    cd file-5.41
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.11. Readline-8.1.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=readline-8.1.2.tar.gz,target=readline-8.1.2.tar.gz \
<<'EOT' $SH
    tar -xf readline-8.1.2.tar.gz
    cd readline-8.1.2
    sed -i '/MV.*old/d' Makefile.in
    sed -i '/{OLDSUFF}/c:' support/shlib-install
    ./configure --prefix=/usr \
        --disable-static \
        --with-curses    \
        --docdir=/usr/share/doc/readline-8.1.2
    make SHLIB_LIBS="-lncursesw"
    make SHLIB_LIBS="-lncursesw" install
    install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.1.2
EOT

# 8.12. M4-1.4.19
RUN --mount=type=tmpfs \
    --mount=from=sources,source=m4-1.4.19.tar.xz,target=m4-1.4.19.tar.xz \
<<'EOT' $SH
    tar -xf m4-1.4.19.tar.xz
    cd m4-1.4.19
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.13. Bc-5.2.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=bc-5.2.2.tar.xz,target=bc-5.2.2.tar.xz \
<<'EOT' $SH
    tar -xf bc-5.2.2.tar.xz
    cd bc-5.2.2
    CC=gcc ./configure --prefix=/usr -G -O3
    make
    if $ENABLE_TESTS; then make test; fi
    make install
EOT

# 8.14. Flex-2.6.4
RUN --mount=type=tmpfs \
    --mount=from=sources,source=flex-2.6.4.tar.gz,target=flex-2.6.4.tar.gz \
<<'EOT' $SH
    tar -xf flex-2.6.4.tar.gz
    cd flex-2.6.4
    ./configure --prefix=/usr \
        --docdir=/usr/share/doc/flex-2.6.4 \
        --disable-static
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    ln -sv flex /usr/bin/lex
EOT

# 8.15. Tcl-8.6.12
RUN --mount=type=tmpfs \
    --mount=from=sources,source=tcl8.6.12-src.tar.gz,target=tcl8.6.12-src.tar.gz \
    --mount=from=sources,source=tcl8.6.12-html.tar.gz,target=tcl8.6.12-html.tar.gz \
<<'EOT' $SH
    tar -xf tcl8.6.12-src.tar.gz
    cd tcl8.6.12
    tar -xf ../tcl8.6.12-html.tar.gz --strip-components=1
    SRCDIR=$(pwd)
    cd unix
    ./configure --prefix=/usr           \
                --mandir=/usr/share/man \
                --enable-64bit
    make
    sed -e "s|$SRCDIR/unix|/usr/lib|" \
        -e "s|$SRCDIR|/usr/include|"  \
        -i tclConfig.sh
    sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.3|/usr/lib/tdbc1.1.3|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.3/generic|/usr/include|"    \
        -e "s|$SRCDIR/pkgs/tdbc1.1.3/library|/usr/lib/tcl8.6|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.3|/usr/include|"            \
        -i pkgs/tdbc1.1.3/tdbcConfig.sh
    sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.2|/usr/lib/itcl4.2.2|" \
        -e "s|$SRCDIR/pkgs/itcl4.2.2/generic|/usr/include|"    \
        -e "s|$SRCDIR/pkgs/itcl4.2.2|/usr/include|"            \
        -i pkgs/itcl4.2.2/itclConfig.sh
    unset SRCDIR
    if $ENABLE_TESTS; then make test; fi
    make install
    chmod -v u+w /usr/lib/libtcl8.6.so
    make install-private-headers
    ln -sfv tclsh8.6 /usr/bin/tclsh
    mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
    mkdir -v -p /usr/share/doc/tcl-8.6.12
    cp -v -r  ../html/* /usr/share/doc/tcl-8.6.12
EOT

# 8.16. Expect-5.45.4
RUN --mount=type=tmpfs \
    --mount=from=sources,source=expect5.45.4.tar.gz,target=expect5.45.4.tar.gz \
<<'EOT' $SH
    tar -xf expect5.45.4.tar.gz
    cd expect5.45.4
    ./configure --prefix=/usr   \
        --with-tcl=/usr/lib     \
        --enable-shared         \
        --mandir=/usr/share/man \
        --with-tclinclude=/usr/include
    make
    if $ENABLE_TESTS; then make test; fi
    make install
    ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
EOT

# 8.17. DejaGNU-1.6.3
RUN --mount=type=tmpfs \
    --mount=from=sources,source=dejagnu-1.6.3.tar.gz,target=dejagnu-1.6.3.tar.gz \
<<'EOT' $SH
    tar -xf dejagnu-1.6.3.tar.gz
    cd dejagnu-1.6.3
    mkdir -v build
    cd build
    ../configure --prefix=/usr
    makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
    makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
    make install
    install -v -dm755  /usr/share/doc/dejagnu-1.6.3
    install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
    if $ENABLE_TESTS; then make check; fi
EOT

# 8.18. Binutils-2.38
# NOTE: skipping the PTY test here since we don't have any during docker build
RUN --mount=type=tmpfs \
    --mount=from=sources,source=binutils-2.38.tar.xz,target=binutils-2.38.tar.xz \
    --mount=from=sources,source=binutils-2.38-lto_fix-1.patch,target=binutils-2.38-lto_fix-1.patch \
<<'EOT' $SH
    tar -xf binutils-2.38.tar.xz
    cd binutils-2.38
    patch -Np1 -i ../binutils-2.38-lto_fix-1.patch
    sed -e '/R_386_TLS_LE /i \   || (TYPE) == R_386_TLS_IE \\' \
        -i ./bfd/elfxx-x86.h
    mkdir -v build
    cd build
    ../configure --prefix=/usr \
        --enable-gold       \
        --enable-ld=default \
        --enable-plugins    \
        --enable-shared     \
        --disable-werror    \
        --enable-64-bit-bfd \
        --with-system-zlib
    make tooldir=/usr
    if $ENABLE_TESTS; then make -k check; fi
    make tooldir=/usr install
    rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.a
EOT

# 8.19. GMP-6.2.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gmp-6.2.1.tar.xz,target=gmp-6.2.1.tar.xz \
<<'EOT' $SH
    tar -xf gmp-6.2.1.tar.xz
    cd gmp-6.2.1
    cp -v configfsf.guess config.guess
    cp -v configfsf.sub   config.sub
    ./configure --prefix=/usr \
        --enable-cxx     \
        --disable-static \
        --docdir=/usr/share/doc/gmp-6.2.1 \
        --build=x86_64-pc-linux-gnu
    make
    make html
    if $ENABLE_TESTS; then \
        make check 2>&1 | tee gmp-check-log
        awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log; \
    fi
    make install
    make install-html
EOT

# 8.20. MPFR-4.1.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=mpfr-4.1.0.tar.xz,target=mpfr-4.1.0.tar.xz \
<<'EOT' $SH
    tar -xf mpfr-4.1.0.tar.xz
    cd mpfr-4.1.0
    ./configure --prefix=/usr \
        --disable-static     \
        --enable-thread-safe \
        --docdir=/usr/share/doc/mpfr-4.1.0
    make
    make html
    if $ENABLE_TESTS; then make check; fi
    make install
    make install-html
EOT

# 8.21. MPC-1.2.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=mpc-1.2.1.tar.gz,target=mpc-1.2.1.tar.gz \
<<'EOT' $SH
    tar -xf mpc-1.2.1.tar.gz
    cd mpc-1.2.1
    ./configure --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/mpc-1.2.1
    make
    make html
    if $ENABLE_TESTS; then make check; fi
    make install
    make install-html
EOT

# 8.22. Attr-2.5.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=attr-2.5.1.tar.gz,target=attr-2.5.1.tar.gz \
<<'EOT' $SH
    tar -xf attr-2.5.1.tar.gz
    cd attr-2.5.1
    ./configure --prefix=/usr \
        --disable-static  \
        --sysconfdir=/etc \
        --docdir=/usr/share/doc/attr-2.5.1
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.23. Acl-2.3.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=acl-2.3.1.tar.xz,target=acl-2.3.1.tar.xz \
<<'EOT' $SH
    tar -xf acl-2.3.1.tar.xz
    cd acl-2.3.1
    ./configure --prefix=/usr \
        --disable-static      \
        --docdir=/usr/share/doc/acl-2.3.1
    make
    make install
EOT

# 8.24. Libcap-2.63
RUN --mount=type=tmpfs \
    --mount=from=sources,source=libcap-2.63.tar.xz,target=libcap-2.63.tar.xz \
<<'EOT' $SH
    tar -xf libcap-2.63.tar.xz
    cd libcap-2.63
    sed -i '/install -m.*STA/d' libcap/Makefile
    make prefix=/usr lib=lib
    if $ENABLE_TESTS; then make test; fi
    make prefix=/usr lib=lib install
EOT

# 8.25. Shadow-4.11.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=shadow-4.11.1.tar.xz,target=shadow-4.11.1.tar.xz \
<<'EOT' $SH
    tar -xf shadow-4.11.1.tar.xz
    cd shadow-4.11.1
    sed -i 's/groups$(EXEEXT) //' src/Makefile.in
    find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
    find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
    find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
    sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
        -e 's:/var/spool/mail:/var/mail:'                 \
        -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                \
        -i etc/login.defs
    touch /usr/bin/passwd
    ./configure --sysconfdir=/etc \
                --disable-static  \
                --with-group-name-max-length=32
    make
    make exec_prefix=/usr install
    make -C man install-man
EOT

# 8.25.2. Configuring Shadow
RUN <<'EOT' $SH
    pwconv
    grpconv
    mkdir -p /etc/default
    useradd -D --gid 999

    # For convenience, allow root login without password
    passwd -d root
EOT

# 8.26. GCC-11.2.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gcc-11.2.0.tar.xz,target=gcc-11.2.0.tar.xz \
<<'EOT' $SH
    tar -xf gcc-11.2.0.tar.xz
    cd gcc-11.2.0
    sed -e '/static.*SIGSTKSZ/d' \
        -e 's/return kAltStackSize/return SIGSTKSZ * 4/' \
        -i libsanitizer/sanitizer_common/sanitizer_posix_libcdep.cpp
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
    mkdir -v build
    cd build
    ../configure --prefix=/usr   \
        LD=ld                    \
        --enable-languages=c,c++ \
        --disable-multilib       \
        --disable-bootstrap      \
        --with-system-zlib
    make
    if $ENABLE_TESTS; then \
        ulimit -s 32768
        chown -Rv tester .
        (su tester -c "PATH=$PATH make -k check" || true); \
    fi
    make install
    rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/11.2.0/include-fixed/bits/
    chown -v -R root:root \
        /usr/lib/gcc/*linux-gnu/11.2.0/include{,-fixed}
    ln -svr /usr/bin/cpp /usr/lib
    ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/11.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/
    mkdir -pv /usr/share/gdb/auto-load/usr/lib
    mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
EOT

# 8.27. Pkg-config-0.29.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=pkg-config-0.29.2.tar.gz,target=pkg-config-0.29.2.tar.gz \
<<'EOT' $SH
    tar -xf pkg-config-0.29.2.tar.gz
    cd pkg-config-0.29.2
    ./configure --prefix=/usr              \
                --with-internal-glib       \
                --disable-host-tool        \
                --docdir=/usr/share/doc/pkg-config-0.29.2
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.28. Ncurses-6.3
RUN --mount=type=tmpfs \
    --mount=from=sources,source=ncurses-6.3.tar.gz,target=ncurses-6.3.tar.gz \
<<'EOT' $SH
    tar -xf ncurses-6.3.tar.gz
    cd ncurses-6.3
    ./configure --prefix=/usr           \
                --mandir=/usr/share/man \
                --with-shared           \
                --without-debug         \
                --without-normal        \
                --enable-pc-files       \
                --enable-widec          \
                --with-pkg-config-libdir=/usr/lib/pkgconfig
    make
    make DESTDIR=$PWD/dest install
    install -vm755 dest/usr/lib/libncursesw.so.6.3 /usr/lib
    rm -v  dest/usr/lib/{libncursesw.so.6.3,libncurses++w.a}
    cp -av dest/* /
    for lib in ncurses form panel menu; do \
        rm -vf                    /usr/lib/lib${lib}.so || exit 1; \
        echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so || exit 1; \
        ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc || exit 1; \
    done
    rm -vf                     /usr/lib/libcursesw.so
    echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
    ln -sfv libncurses.so      /usr/lib/libcurses.so
    mkdir -pv      /usr/share/doc/ncurses-6.3
    cp -v -R doc/* /usr/share/doc/ncurses-6.3
EOT

# 8.29. Sed-4.8
RUN --mount=type=tmpfs \
    --mount=from=sources,source=sed-4.8.tar.xz,target=sed-4.8.tar.xz \
<<'EOT' $SH
    tar -xf sed-4.8.tar.xz
    cd sed-4.8
    ./configure --prefix=/usr
    make
    make html
    if $ENABLE_TESTS; then \
        chown -Rv tester .
        su tester -c "PATH=$PATH make check"; \
    fi
    make install
    install -d -m755           /usr/share/doc/sed-4.8
    install -m644 doc/sed.html /usr/share/doc/sed-4.8
EOT

# 8.30. Psmisc-23.4
RUN --mount=type=tmpfs \
    --mount=from=sources,source=psmisc-23.4.tar.xz,target=psmisc-23.4.tar.xz \
<<'EOT' $SH
    tar -xf psmisc-23.4.tar.xz
    cd psmisc-23.4
    ./configure --prefix=/usr
    make
    make install
EOT

# 8.31. Gettext-0.21
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gettext-0.21.tar.xz,target=gettext-0.21.tar.xz \
<<'EOT' $SH
    tar -xf gettext-0.21.tar.xz
    cd gettext-0.21
    ./configure --prefix=/usr    \
                --disable-static \
                --docdir=/usr/share/doc/gettext-0.21
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    chmod -v 0755 /usr/lib/preloadable_libintl.so
EOT

# 8.32. Bison-3.8.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=bison-3.8.2.tar.xz,target=bison-3.8.2.tar.xz \
<<'EOT' $SH
    tar -xf bison-3.8.2.tar.xz
    cd bison-3.8.2
    ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.33. Grep-3.7
RUN --mount=type=tmpfs \
    --mount=from=sources,source=grep-3.7.tar.xz,target=grep-3.7.tar.xz \
<<'EOT' $SH
    tar -xf grep-3.7.tar.xz
    cd grep-3.7
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.34. Bash-5.1.16
# NOTE: skipping tests since no PTY is available
RUN --mount=type=tmpfs \
    --mount=from=sources,source=bash-5.1.16.tar.gz,target=bash-5.1.16.tar.gz \
<<'EOT' $SH
    tar -xf bash-5.1.16.tar.gz
    cd bash-5.1.16
    ./configure --prefix=/usr                       \
                --docdir=/usr/share/doc/bash-5.1.16 \
                --without-bash-malloc               \
                --with-installed-readline
    make
    make install
EOT

# 8.35. Libtool-2.4.6
RUN --mount=type=tmpfs \
    --mount=from=sources,source=libtool-2.4.6.tar.xz,target=libtool-2.4.6.tar.xz \
<<'EOT' $SH
    tar -xf libtool-2.4.6.tar.xz
    cd libtool-2.4.6
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    rm -fv /usr/lib/libltdl.a
EOT

# 8.36. GDBM-1.23
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gdbm-1.23.tar.gz,target=gdbm-1.23.tar.gz \
<<'EOT' $SH
    tar -xf gdbm-1.23.tar.gz
    cd gdbm-1.23
    ./configure --prefix=/usr    \
                --disable-static \
                --enable-libgdbm-compat
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.37. Gperf-3.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gperf-3.1.tar.gz,target=gperf-3.1.tar.gz \
<<'EOT' $SH
    tar -xf gperf-3.1.tar.gz
    cd gperf-3.1
    ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
    make
    if $ENABLE_TESTS; then make -j1 check; fi
    make install
EOT

# 8.38. Expat-2.4.6
RUN --mount=type=tmpfs \
    --mount=from=sources,source=expat-2.4.6.tar.xz,target=expat-2.4.6.tar.xz \
<<'EOT' $SH
    tar -xf expat-2.4.6.tar.xz
    cd expat-2.4.6
    ./configure --prefix=/usr    \
                --disable-static \
                --docdir=/usr/share/doc/expat-2.4.6
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.4.6
EOT

# 8.39. Inetutils-2.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=inetutils-2.2.tar.xz,target=inetutils-2.2.tar.xz \
<<'EOT' $SH
    tar -xf inetutils-2.2.tar.xz
    cd inetutils-2.2
    ./configure --prefix=/usr        \
                --bindir=/usr/bin    \
                --localstatedir=/var \
                --disable-logger     \
                --disable-whois      \
                --disable-rcp        \
                --disable-rexec      \
                --disable-rlogin     \
                --disable-rsh        \
                --disable-servers
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    mv -v /usr/{,s}bin/ifconfig
EOT

# 8.40. Less-590
RUN --mount=type=tmpfs \
    --mount=from=sources,source=less-590.tar.gz,target=less-590.tar.gz \
<<'EOT' $SH
    tar -xf less-590.tar.gz
    cd less-590
    ./configure --prefix=/usr --sysconfdir=/etc
    make
    make install
EOT

# 8.41. Perl-5.34.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=perl-5.34.0.tar.xz,target=perl-5.34.0.tar.xz \
    --mount=from=sources,source=perl-5.34.0-upstream_fixes-1.patch,target=perl-5.34.0-upstream_fixes-1.patch \
<<'EOT' $SH
    tar -xf perl-5.34.0.tar.xz
    cd perl-5.34.0
    patch -Np1 -i ../perl-5.34.0-upstream_fixes-1.patch
    export BUILD_ZLIB=False
    export BUILD_BZIP2=0
    sh Configure -des                                         \
                 -Dprefix=/usr                                \
                 -Dvendorprefix=/usr                          \
                 -Dprivlib=/usr/lib/perl5/5.34/core_perl      \
                 -Darchlib=/usr/lib/perl5/5.34/core_perl      \
                 -Dsitelib=/usr/lib/perl5/5.34/site_perl      \
                 -Dsitearch=/usr/lib/perl5/5.34/site_perl     \
                 -Dvendorlib=/usr/lib/perl5/5.34/vendor_perl  \
                 -Dvendorarch=/usr/lib/perl5/5.34/vendor_perl \
                 -Dman1dir=/usr/share/man/man1                \
                 -Dman3dir=/usr/share/man/man3                \
                 -Dpager="/usr/bin/less -isR"                 \
                 -Duseshrplib                                 \
                 -Dusethreads
    make
    if $ENABLE_TESTS; then make test; fi
    make install
    unset BUILD_ZLIB BUILD_BZIP2
EOT

# 8.42. XML::Parser-2.46
RUN --mount=type=tmpfs \
    --mount=from=sources,source=XML-Parser-2.46.tar.gz,target=XML-Parser-2.46.tar.gz \
<<'EOT' $SH
    tar -xf XML-Parser-2.46.tar.gz
    cd XML-Parser-2.46
    perl Makefile.PL
    make
    if $ENABLE_TESTS; then make test; fi
    make install
EOT

# 8.43. Intltool-0.51.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=intltool-0.51.0.tar.gz,target=intltool-0.51.0.tar.gz \
<<'EOT' $SH
    tar -xf intltool-0.51.0.tar.gz
    cd intltool-0.51.0
    sed -i 's:\\\${:\\\$\\{:' intltool-update.in
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
EOT

# 8.44. Autoconf-2.71
RUN --mount=type=tmpfs \
    --mount=from=sources,source=autoconf-2.71.tar.xz,target=autoconf-2.71.tar.xz \
<<'EOT' $SH
    tar -xf autoconf-2.71.tar.xz
    cd autoconf-2.71
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.45. Automake-1.16.5
RUN --mount=type=tmpfs \
    --mount=from=sources,source=automake-1.16.5.tar.xz,target=automake-1.16.5.tar.xz \
<<'EOT' $SH
    tar -xf automake-1.16.5.tar.xz
    cd automake-1.16.5
    ./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.46. OpenSSL-3.0.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=openssl-3.0.1.tar.gz,target=openssl-3.0.1.tar.gz \
<<'EOT' $SH
    tar -xf openssl-3.0.1.tar.gz
    cd openssl-3.0.1
    ./config --prefix=/usr         \
             --openssldir=/etc/ssl \
             --libdir=lib          \
             shared                \
             zlib-dynamic
    make
    if $ENABLE_TESTS; then make test || true; fi
    sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
    make MANSUFFIX=ssl install
    mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.0.1
    cp -vfr doc/* /usr/share/doc/openssl-3.0.1
EOT

# 8.47. Kmod-29
RUN --mount=type=tmpfs \
    --mount=from=sources,source=kmod-29.tar.xz,target=kmod-29.tar.xz \
<<'EOT' $SH
    tar -xf kmod-29.tar.xz
    cd kmod-29
    ./configure --prefix=/usr          \
                --sysconfdir=/etc      \
                --with-openssl         \
                --with-xz              \
                --with-zstd            \
                --with-zlib
    make
    make install
    for target in depmod insmod modinfo modprobe rmmod; do \
        ln -sfv ../bin/kmod /usr/sbin/$target || exit 1; \
    done
    ln -sfv kmod /usr/bin/lsmod
EOT

# 8.48. Libelf from Elfutils-0.186
RUN --mount=type=tmpfs \
    --mount=from=sources,source=elfutils-0.186.tar.bz2,target=elfutils-0.186.tar.bz2 \
<<'EOT' $SH
    tar -xf elfutils-0.186.tar.bz2
    cd elfutils-0.186
    ./configure --prefix=/usr                \
                --disable-debuginfod         \
                --enable-libdebuginfod=dummy
    make
    if $ENABLE_TESTS; then make check; fi
    make -C libelf install
    install -vm644 config/libelf.pc /usr/lib/pkgconfig
    rm /usr/lib/libelf.a
EOT

# 8.49. Libffi-3.4.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=libffi-3.4.2.tar.gz,target=libffi-3.4.2.tar.gz \
<<'EOT' $SH
    tar -xf libffi-3.4.2.tar.gz
    cd libffi-3.4.2
    ./configure --prefix=/usr          \
                --disable-static       \
                --with-gcc-arch=native \
                --disable-exec-static-tramp
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.50. Python-3.10.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=Python-3.10.2.tar.xz,target=Python-3.10.2.tar.xz \
    --mount=from=sources,source=python-3.10.2-docs-html.tar.bz2,target=python-3.10.2-docs-html.tar.bz2 \
<<'EOT' $SH
    tar -xf Python-3.10.2.tar.xz
    cd Python-3.10.2
    ./configure --prefix=/usr        \
                --enable-shared      \
                --with-system-expat  \
                --with-system-ffi    \
                --with-ensurepip=yes \
                --enable-optimizations
    make
    make install
    install -v -dm755 /usr/share/doc/python-3.10.2/html
    tar --strip-components=1  \
        --no-same-owner       \
        --no-same-permissions \
        -C /usr/share/doc/python-3.10.2/html \
        -xvf ../python-3.10.2-docs-html.tar.bz2
EOT

# 8.51. Ninja-1.10.2
# NOTE: skipping setting NINJAJOBS
RUN --mount=type=tmpfs \
    --mount=from=sources,source=ninja-1.10.2.tar.gz,target=ninja-1.10.2.tar.gz \
<<'EOT' $SH
    tar -xf ninja-1.10.2.tar.gz
    cd ninja-1.10.2
    sed -i '/int Guess/a \
        int   j = 0;\
        char* jobs = getenv( "NINJAJOBS" );\
        if ( jobs != NULL ) j = atoi( jobs );\
        if ( j > 0 ) return j;\
        ' src/ninja.cc
    python3 configure.py --bootstrap
    if $ENABLE_TESTS; then \
        ./ninja ninja_test
        ./ninja_test --gtest_filter=-SubprocessTest.SetWithLots; \
    fi
    install -vm755 ninja /usr/bin/
    install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
    install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
EOT

# 8.52. Meson-0.61.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=meson-0.61.1.tar.gz,target=meson-0.61.1.tar.gz \
<<'EOT' $SH
    tar -xf meson-0.61.1.tar.gz
    cd meson-0.61.1
    python3 setup.py build
    python3 setup.py install --root=dest
    cp -rv dest/* /
    install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
    install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
EOT

# 8.53. Coreutils-9.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=coreutils-9.0.tar.xz,target=coreutils-9.0.tar.xz \
    --mount=from=sources,source=coreutils-9.0-i18n-1.patch,target=coreutils-9.0-i18n-1.patch \
    --mount=from=sources,source=coreutils-9.0-chmod_fix-1.patch,target=coreutils-9.0-chmod_fix-1.patch \
<<'EOT' $SH
    tar -xf coreutils-9.0.tar.xz
    cd coreutils-9.0
    patch -Np1 -i ../coreutils-9.0-i18n-1.patch
    patch -Np1 -i ../coreutils-9.0-chmod_fix-1.patch
    autoreconf -fiv
    FORCE_UNSAFE_CONFIGURE=1 ./configure \
                --prefix=/usr            \
                --enable-no-install-program=kill,uptime
    make
    if $ENABLE_TESTS; then \
        make NON_ROOT_USERNAME=tester check-root
        echo "dummy:x:102:tester" >> /etc/group
        chown -Rv tester .
        su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
        sed -i '/dummy/d' /etc/group; \
    fi
    make install
    mv -v /usr/bin/chroot /usr/sbin
    mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
    sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
EOT

# 8.54. Check-0.15.2
RUN --mount=type=tmpfs \
    --mount=from=sources,source=check-0.15.2.tar.gz,target=check-0.15.2.tar.gz \
<<'EOT' $SH
    tar -xf check-0.15.2.tar.gz
    cd check-0.15.2
    ./configure --prefix=/usr --disable-static
    make
    if $ENABLE_TESTS; then make check; fi
    make docdir=/usr/share/doc/check-0.15.2 install
EOT

# 8.55. Diffutils-3.8
RUN --mount=type=tmpfs \
    --mount=from=sources,source=diffutils-3.8.tar.xz,target=diffutils-3.8.tar.xz \
<<'EOT' $SH
    tar -xf diffutils-3.8.tar.xz
    cd diffutils-3.8
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.56. Gawk-5.1.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gawk-5.1.1.tar.xz,target=gawk-5.1.1.tar.xz \
<<'EOT' $SH
    tar -xf gawk-5.1.1.tar.xz
    cd gawk-5.1.1
    sed -i 's/extras//' Makefile.in
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    mkdir -pv                                   /usr/share/doc/gawk-5.1.1
    cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.1.1
EOT

# 8.57. Findutils-4.9.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=findutils-4.9.0.tar.xz,target=findutils-4.9.0.tar.xz \
<<'EOT' $SH
    tar -xf findutils-4.9.0.tar.xz
    cd findutils-4.9.0
    ./configure --prefix=/usr --localstatedir=/var/lib/locate
    make
    if $ENABLE_TESTS; then \
        chown -Rv tester .
        su tester -c "PATH=$PATH make check"; \
    fi
    make install
EOT

# 8.58. Groff-1.22.4
RUN --mount=type=tmpfs \
    --mount=from=sources,source=groff-1.22.4.tar.gz,target=groff-1.22.4.tar.gz \
<<'EOT' $SH
    tar -xf groff-1.22.4.tar.gz
    cd groff-1.22.4
    PAGE=letter ./configure --prefix=/usr
    make -j1
    make install
EOT

# 8.59. GRUB-2.06
RUN --mount=type=tmpfs \
    --mount=from=sources,source=grub-2.06.tar.xz,target=grub-2.06.tar.xz \
<<'EOT' $SH
    tar -xf grub-2.06.tar.xz
    cd grub-2.06
    ./configure --prefix=/usr          \
                --sysconfdir=/etc      \
                --disable-efiemu       \
                --disable-werror
    make
    make install
    mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
EOT

# TODO: The GRUB images used later to make the bootable ISO
#       should preferably come from here. To do that, we need to compile
#       GRUB using the following command instead.
# NOTE: Building with UEFI support (see https://www.linuxfromscratch.org/blfs/view/11.1-systemd/postlfs/grub-efi.html)
# NOTE: since FreeType-2.11.1 and efibootmgr-17 are not installed at this point,
#       Some functionalities might be missing
# RUN --mount=type=tmpfs \
#     --mount=from=sources,source=grub-2.06.tar.xz,target=grub-2.06.tar.xz \
# <<'EOT' $SH
#     tar -xf grub-2.06.tar.xz
#     cd grub-2.06
#     # We need both i386-pc and x86_64-efi targets
#     ./configure --prefix=/usr          \
#                 --sysconfdir=/etc      \
#                 --disable-efiemu       \
#                 --disable-werror       \
#                 --target=i386          \
#                 --with-platform=pc
#     make
#     make install
#     make clean
#     ./configure --prefix=/usr          \
#                 --sysconfdir=/etc      \
#                 --disable-efiemu       \
#                 --disable-werror       \
#                 --with-platform=efi
#     make
#     make install
#     mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
# EOT

# 8.60. Gzip-1.11
RUN --mount=type=tmpfs \
    --mount=from=sources,source=gzip-1.11.tar.xz,target=gzip-1.11.tar.xz \
<<'EOT' $SH
    tar -xf gzip-1.11.tar.xz
    cd gzip-1.11
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.61. IPRoute2-5.16.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=iproute2-5.16.0.tar.xz,target=iproute2-5.16.0.tar.xz \
<<'EOT' $SH
    tar -xf iproute2-5.16.0.tar.xz
    cd iproute2-5.16.0
    sed -i /ARPD/d Makefile
    rm -fv man/man8/arpd.8
    make
    make SBINDIR=/usr/sbin install
    mkdir -pv             /usr/share/doc/iproute2-5.16.0
    cp -v COPYING README* /usr/share/doc/iproute2-5.16.0
EOT

# 8.62. Kbd-2.4.0
RUN --mount=type=tmpfs \
    --mount=from=sources,source=kbd-2.4.0.tar.xz,target=kbd-2.4.0.tar.xz \
    --mount=from=sources,source=kbd-2.4.0-backspace-1.patch,target=kbd-2.4.0-backspace-1.patch \
<<'EOT' $SH
    tar -xf kbd-2.4.0.tar.xz
    cd kbd-2.4.0
    patch -Np1 -i ../kbd-2.4.0-backspace-1.patch
    sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
    sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
    ./configure --prefix=/usr --disable-vlock
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    mkdir -pv           /usr/share/doc/kbd-2.4.0
    cp -R -v docs/doc/* /usr/share/doc/kbd-2.4.0
EOT

# 8.63. Libpipeline-1.5.5
RUN --mount=type=tmpfs \
    --mount=from=sources,source=libpipeline-1.5.5.tar.gz,target=libpipeline-1.5.5.tar.gz \
<<'EOT' $SH
    tar -xf libpipeline-1.5.5.tar.gz
    cd libpipeline-1.5.5
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.64. Make-4.3
RUN --mount=type=tmpfs \
    --mount=from=sources,source=make-4.3.tar.gz,target=make-4.3.tar.gz \
<<'EOT' $SH
    tar -xf make-4.3.tar.gz
    cd make-4.3
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.65. Patch-2.7.6
RUN --mount=type=tmpfs \
    --mount=from=sources,source=patch-2.7.6.tar.xz,target=patch-2.7.6.tar.xz \
<<'EOT' $SH
    tar -xf patch-2.7.6.tar.xz
    cd patch-2.7.6
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.66. Tar-1.34
RUN --mount=type=tmpfs \
    --mount=from=sources,source=tar-1.34.tar.xz,target=tar-1.34.tar.xz \
<<'EOT' $SH
    tar -xf tar-1.34.tar.xz
    cd tar-1.34
    FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    make -C doc install-html docdir=/usr/share/doc/tar-1.34
EOT

# 8.67. Texinfo-6.8
RUN --mount=type=tmpfs \
    --mount=from=sources,source=texinfo-6.8.tar.xz,target=texinfo-6.8.tar.xz \
<<'EOT' $SH
    tar -xf texinfo-6.8.tar.xz
    cd texinfo-6.8
    ./configure --prefix=/usr
    sed -e 's/__attribute_nonnull__/__nonnull/' \
        -i gnulib/lib/malloc/dynarray-skeleton.c
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    make TEXMF=/usr/share/texmf install-tex
EOT

# 8.68. Vim-8.2.4383
RUN --mount=type=tmpfs \
    --mount=from=sources,source=vim-8.2.4383.tar.gz,target=vim-8.2.4383.tar.gz \
<<'EOT' $SH
    tar -xf vim-8.2.4383.tar.gz
    cd vim-8.2.4383
    echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
    ./configure --prefix=/usr
    make
    if $ENABLE_TESTS; then \
        chown -Rv tester .
        su tester -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log
        grep -q "ALL DONE" vim-test.log; \
    fi
    make install
    ln -sv vim /usr/bin/vi
    for L in /usr/share/man/{,*/}man1/vim.1; do \
        ln -sv vim.1 $(dirname $L)/vi.1 || exit 1; \
    done
    ln -sv ../vim/vim82/doc /usr/share/doc/vim-8.2.4383
EOT

ADD <<-'EOT' /etc/vimrc
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif
EOT

# 8.69. MarkupSafe-2.0.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=MarkupSafe-2.0.1.tar.gz,target=MarkupSafe-2.0.1.tar.gz \
<<'EOT' $SH
    tar -xf MarkupSafe-2.0.1.tar.gz
    cd MarkupSafe-2.0.1
    python3 setup.py build
    python3 setup.py install --optimize=1
EOT

# 8.70. Jinja2-3.0.3
RUN --mount=type=tmpfs \
    --mount=from=sources,source=Jinja2-3.0.3.tar.gz,target=Jinja2-3.0.3.tar.gz \
<<'EOT' $SH
    tar -xf Jinja2-3.0.3.tar.gz
    cd Jinja2-3.0.3
    python3 setup.py install --optimize=1
EOT

# 8.71. Systemd-250
RUN --mount=type=tmpfs \
    --mount=from=sources,source=systemd-250.tar.gz,target=systemd-250.tar.gz \
    --mount=from=sources,source=systemd-250-upstream_fixes-1.patch,target=systemd-250-upstream_fixes-1.patch \
    --mount=from=sources,source=systemd-man-pages-250.tar.xz,target=systemd-man-pages-250.tar.xz \
<<'EOT' $SH
    tar -xf systemd-250.tar.gz
    cd systemd-250
    patch -Np1 -i ../systemd-250-upstream_fixes-1.patch
    sed -i -e 's/GROUP="render"/GROUP="video"/' \
        -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
    mkdir -p build
    cd build
    meson --prefix=/usr                 \
          --sysconfdir=/etc             \
          --localstatedir=/var          \
          --buildtype=release           \
          -Dblkid=true                  \
          -Ddefault-dnssec=no           \
          -Dfirstboot=false             \
          -Dinstall-tests=false         \
          -Dldconfig=false              \
          -Dsysusers=false              \
          -Db_lto=false                 \
          -Drpmmacrosdir=no             \
          -Dhomed=false                 \
          -Duserdb=false                \
          -Dman=false                   \
          -Dmode=release                \
          -Ddocdir=/usr/share/doc/systemd-250 \
          ..
    ninja
    ninja install
    tar -xf ../../systemd-man-pages-250.tar.xz --strip-components=1 -C /usr/share/man
    rm -rf /usr/lib/pam.d
    systemd-machine-id-setup
    systemctl preset-all
EOT

# 8.72. D-Bus-1.12.20
RUN --mount=type=tmpfs \
    --mount=from=sources,source=dbus-1.12.20.tar.gz,target=dbus-1.12.20.tar.gz \
<<'EOT' $SH
    tar -xf dbus-1.12.20.tar.gz
    cd dbus-1.12.20
    ./configure --prefix=/usr                        \
                --sysconfdir=/etc                    \
                --localstatedir=/var                 \
                --disable-static                     \
                --disable-doxygen-docs               \
                --disable-xml-docs                   \
                --docdir=/usr/share/doc/dbus-1.12.20 \
                --with-console-auth-dir=/run/console \
                --with-system-pid-file=/run/dbus/pid \
                --with-system-socket=/run/dbus/system_bus_socket
    make
    make install
    ln -sfv /etc/machine-id /var/lib/dbus
EOT

# 8.73. Man-DB-2.10.1
RUN --mount=type=tmpfs \
    --mount=from=sources,source=man-db-2.10.1.tar.xz,target=man-db-2.10.1.tar.xz \
<<'EOT' $SH
    tar -xf man-db-2.10.1.tar.xz
    cd man-db-2.10.1
    ./configure --prefix=/usr                         \
                --docdir=/usr/share/doc/man-db-2.10.1 \
                --sysconfdir=/etc                     \
                --disable-setuid                      \
                --enable-cache-owner=bin              \
                --with-browser=/usr/bin/lynx          \
                --with-vgrind=/usr/bin/vgrind         \
                --with-grap=/usr/bin/grap
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.74. Procps-ng-3.3.17
RUN --mount=type=tmpfs \
    --mount=from=sources,source=procps-ng-3.3.17.tar.xz,target=procps-ng-3.3.17.tar.xz \
<<'EOT' $SH
    tar -xf procps-ng-3.3.17.tar.xz
    cd procps-3.3.17
    ./configure --prefix=/usr                            \
                --docdir=/usr/share/doc/procps-ng-3.3.17 \
                --disable-static                         \
                --disable-kill                           \
                --with-systemd
    make
    if $ENABLE_TESTS; then make check; fi
    make install
EOT

# 8.75. Util-linux-2.37.4
RUN --mount=type=tmpfs \
    --mount=from=sources,source=util-linux-2.37.4.tar.xz,target=util-linux-2.37.4.tar.xz \
<<'EOT' $SH
    tar -xf util-linux-2.37.4.tar.xz
    cd util-linux-2.37.4
    ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
                --bindir=/usr/bin    \
                --libdir=/usr/lib    \
                --sbindir=/usr/sbin  \
                --docdir=/usr/share/doc/util-linux-2.37.4 \
                --disable-chfn-chsh  \
                --disable-login      \
                --disable-nologin    \
                --disable-su         \
                --disable-setpriv    \
                --disable-runuser    \
                --disable-pylibmount \
                --disable-static     \
                --without-python
    make
    if $ENABLE_TESTS; then \
        chown -Rv tester .
        su tester -c "make -k check"; \
    fi
    make install
EOT

# 8.76. E2fsprogs-1.46.5
RUN --mount=type=tmpfs \
    --mount=from=sources,source=e2fsprogs-1.46.5.tar.gz,target=e2fsprogs-1.46.5.tar.gz \
<<'EOT' $SH
    tar -xf e2fsprogs-1.46.5.tar.gz
    cd e2fsprogs-1.46.5
    mkdir -v build
    cd build
    ../configure --prefix=/usr           \
                 --sysconfdir=/etc       \
                 --enable-elf-shlibs     \
                 --disable-libblkid      \
                 --disable-libuuid       \
                 --disable-uuidd         \
                 --disable-fsck
    make
    if $ENABLE_TESTS; then make check; fi
    make install
    rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
    gunzip -v /usr/share/info/libext2fs.info.gz
    install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
    makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
    install -v -m644 doc/com_err.info /usr/share/info
    install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
EOT

# 8.78. Stripping
RUN <<'EOT' $SH
save_usrlib="$(cd /usr/lib; ls ld-linux*)
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.29
             libitm.so.1.0.0
             libatomic.so.1.2.0"

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

online_usrbin="bash find strip"
online_usrlib="libbfd-2.38.so
               libhistory.so.8.1
               libncursesw.so.6.3
               libm.so.6
               libreadline.so.8.1
               libz.so.1.2.12
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-unneeded /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done

for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    # Some files may have unrecognized format so we need to ignore some errors
    strip --strip-unneeded /tmp/$LIB || true
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * ) strip --strip-unneeded $i || true
            ;;
    esac
done

unset BIN LIB save_usrlib online_usrbin online_usrlib
EOT

# 8.79. Cleaning Up
ARG LFS_TGT
RUN <<'EOT' $SH
    rm -rf /tmp/*
    find /usr/lib /usr/libexec -name \*.la -delete
    find /usr -depth -name $LFS_TGT\* | xargs rm -rf
    userdel -r tester
EOT

# 9.2. General Network Configuration
# is done later when building the ISO image

# 9.3 - 9.6 skipped

# 9.7. Configuring the System Locale
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 9.8. Creating the /etc/inputrc File
ADD <<-'EOT' /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line
EOT

# 9.9. Creating the /etc/shells File
ADD <<-'EOT' /etc/shells
/bin/sh
/bin/bash
EOT

# Skipping 10.2. Creating the /etc/fstab File

# 10.3. Linux-5.16.9
RUN --mount=type=tmpfs \
    --mount=from=sources,source=linux-5.16.9.tar.xz,target=linux-5.16.9.tar.xz \
<<'EOT' $SH
    tar -xf linux-5.16.9.tar.xz
    cd linux-5.16.9
    make mrproper
    make defconfig
    # Edit required flags
    scripts/kconfig/merge_config.sh .config <<-'EOT2'
# Config required by LFS
CONFIG_AUDIT=n
CONFIG_IKHEADERS=n
CONFIG_CGROUPS=y
CONFIG_MEMCG=y
CONFIG_SYSFS_DEPRECATED=n
CONFIG_EXPERT=y
CONFIG_FHANDLE=y
CONFIG_PSI=y
CONFIG_SECCOMP=y
CONFIG_IPV6=y
CONFIG_DMIID=y
CONFIG_FB=y
CONFIG_UEVENT_HELPER=n
CONFIG_DEVTMPFS=y
CONFIG_FW_LOADER_USER_HELPER=n
CONFIG_INOTIFY_USER=y
CONFIG_TMPFS_POSIX_ACL=y

# Support UEFI
CONFIG_EFI=y
CONFIG_EFI_STUB=y
CONFIG_EFI_VARS=n
CONFIG_EFI_RUNTIME_MAP=y
CONFIG_PARTITION_ADVANCED=y
CONFIG_EFI_PARTITION=y
CONFIG_FB_EFI=y
CONFIG_FRAMEBUFFER_CONSOLE=y
CONFIG_EFIVAR_FS=y

# Add support for squashfs and overlayfs
CONFIG_SQUASHFS=y
CONFIG_OVERLAY_FS=y

# Suppress stack usage prompt
CONFIG_DEBUG_STACK_USAGE=n
EOT2
    make
    make modules_install
    cp -iv arch/x86/boot/bzImage /boot/vmlinuz-5.16.9
    cp -iv System.map /boot/System.map-5.16.9
    cp -iv .config /boot/config-5.16.9
    # Install documentation
    install -d /usr/share/doc/linux-5.16.9
    cp -r Documentation/* /usr/share/doc/linux-5.16.9
    # 10.3.2. Configuring Linux Module Load Order
    install -v -m755 -d /etc/modprobe.d
    echo 'install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true' >> /etc/modprobe.d/usb.conf
    echo 'install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true' >> /etc/modprobe.d/usb.conf
EOT

WORKDIR /

# Update shell prompt
RUN echo 'PS1='"'"'\u@\h:\w\$ '"'" >> /etc/profile

########################
# Image 4. ISO Builder #
########################
FROM alpine:3.16 AS iso-builder
ARG SH

# TODO: remove the mirrors here
RUN apk add --no-cache \
        --repository https://mirrors.ustc.edu.cn/alpine/v3.16/main/ \
        --repository https://mirrors.ustc.edu.cn/alpine/v3.16/community/ \
        --repositories-file /dev/null \
        squashfs-tools xorriso cpio wget \
        dosfstools mtools \
        grub grub-efi grub-bios

RUN mkdir -pv /build

RUN mkdir /build/initramfs_root /build/iso_root

#################################################
# Pack the entire LFS system in squashfs format #
#################################################

WORKDIR /build

# Copy the entire root directory for further processing
COPY --from=system / lfs
RUN rm -r lfs/sources

# 9.2. General Network Configuration
# This is done here since in the previous stage,
# /etc/hostname and /etc/hosts would be overwritten by Docker
ARG LFS_HOSTNAME
RUN echo "$LFS_HOSTNAME" > lfs/etc/hostname

# NOTE: EOT is not quoted here since we need $LFS_HOSTNAME to be expanded
ADD <<-EOT lfs/etc/hosts
127.0.0.1 localhost
127.0.1.1 $LFS_HOSTNAME
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOT

RUN mkdir -pv lfs/proc lfs/sys lfs/dev

RUN <<'EOT' $SH
    mksquashfs lfs iso_root/system.squashfs
    rm -r lfs
EOT

##################
# Make initramfs #
##################

WORKDIR /build/initramfs_root

RUN mkdir -pv bin lib dev proc sys tmp
ADD <<-'EOT' init
#!/bin/sh

# Mount all essential virtual file systems
mount -t devtmpfs  devtmpfs  /dev
mount -t proc      proc      /proc
mount -t sysfs     sysfs     /sys
mount -t tmpfs     tmpfs     /tmp

cd /tmp
mkdir -p boot lower upper work system

# Find the boot device and switch_root
find_system() {
    IFS="
"; for device in $(blkid); do
        dev_path=$(echo $device | cut -d ":" -f 1)

        echo "Checking if $dev_path is the boot device"

        # Check if a device contains system.squashfs
        # If so, mount system.squashfs and switch_root to it
        if ! mount $dev_path boot; then
            echo "Failed to mount device $dev_path"
            continue
        fi

        if ! [ -e boot/system.squashfs ]; then
            echo "Failed to find system.squashfs on $dev_path"
            umount boot
            continue
        fi

        # Mount system.squashfs
        if ! mount -t squashfs boot/system.squashfs lower; then
            echo "Failed to mount system.squashfs on $dev_path"
            exec sh
        fi

        # Add an overlay fs on top of system.squashfs
        if ! mount -t overlay \
                -o lowerdir=/tmp/lower,upperdir=/tmp/upper,workdir=/tmp/work \
                overlay system; then
            echo "Failed to mount overlayfs for $dev_path"
            exec sh
        fi

        echo "Found boot device $dev_path, switch_root now"
        exec switch_root system /sbin/init
    done

    return 1
}

# Check multiple times since the device may not be set up yet
find_system || sleep 1
find_system || sleep 1
find_system || sleep 1
find_system || sleep 1
find_system || sleep 1
find_system || sleep 1
find_system || sleep 1
find_system || sleep 1
find_system || sleep 1
find_system

echo "Could not find the boot device"
exec sh
EOT

# Install busybox to initramfs
RUN --mount=from=sources,source=busybox-x86_64,target=/tmp/busybox-x86_64 \
<<'EOT' $SH
    cp /tmp/busybox-x86_64 bin/busybox
    # Use the busybox binary on the host system to install symbolic links
    /bin/busybox --install -s bin
    chmod +x bin/busybox
    chmod +x init
    find . | cpio -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
EOT

##################
# Make ISO image #
##################

WORKDIR /build/iso_root

# Prepare file structure
RUN mkdir boot boot/grub boot/grub/i386-pc boot/grub/x86_64-efi

# Copy kernel from the built system
COPY --from=system /boot/vmlinuz-5.16.9 boot/vmlinuz

# Copy the initramfs we just made
RUN cp ../initramfs.cpio.gz boot/initramfs.cpio.gz

ARG ISO_GRUB_PRELOAD_MODULES

RUN mkdir -pv tmp

# Prepare image for BIOS booting
RUN <<'EOT' $SH
    grub-mkimage        \
        -o tmp/core.img \
        -O i386-pc      \
        -p /boot/grub   \
        $ISO_GRUB_PRELOAD_MODULES biosdisk
    cat /usr/lib/grub/i386-pc/cdboot.img tmp/core.img \
        > boot/grub/i386-pc/eltorito.img
EOT

# Prepare image for UEFI booting
# TODO: check if the size of efi.img is large enough
ADD <<-'EOT' tmp/grub-stub.cfg
# Trying to find a device containing the file /system.squashfs
# as the new root. TODO: This may not be reliable.
search --set=root --file /system.squashfs
set prefix=($root)/boot/grub
configfile /boot/grub/grub.cfg
EOT

RUN <<'EOT' $SH
    grub-mkimage             \
        -o tmp/bootx64.efi   \
        -O x86_64-efi        \
        -c tmp/grub-stub.cfg \
        -p /boot/grub        \
        $ISO_GRUB_PRELOAD_MODULES
    # Compute the minimal size for efi.img
    bootx64_size=$(du tmp/bootx64.efi | cut -f 1)
    bootx64_size=$((bootx64_size + 511))
    num_sectors=$((bootx64_size / 512 + 1))
    num_sectors=$((num_sectors < 1440 ? 1440 : num_sectors))
    # Create a FAT-format image and copy bootx64.efi into it
    dd if=/dev/zero of=tmp/efi.img bs=512 count=$num_sectors
    mkfs.vfat -n ESP tmp/efi.img
    mmd -i tmp/efi.img efi efi/boot
    mcopy -i tmp/efi.img tmp/bootx64.efi ::efi/boot/bootx64.efi
    cp tmp/efi.img boot/grub/x86_64-efi/efi.img
EOT

# Also copy efi/boot/bootx64.efi to the root of the ISO image
RUN <<'EOT' $SH
    mkdir -pv efi/boot
    cp -v tmp/bootx64.efi efi/boot/bootx64.efi
EOT

ADD <<-'EOT' boot/grub/grub.cfg
set pager=1

menuentry "LFS" {
   echo "Booting /boot/vmlinuz with initrd=/boot/initramfs.cpio.gz"
   linux /boot/vmlinuz
   initrd /boot/initramfs.cpio.gz
}
EOT

# Make an ISO image that is bootable (supposedly)
# from any combination of BIOS/UEFI on USB/CD
ARG ISO_VOLUME_ID
RUN rm -rv tmp && \
    xorriso -as mkisofs                   \
        -V $ISO_VOLUME_ID                 \
        -c boot/boot.cat                  \
        # First boot entry
        -b boot/grub/i386-pc/eltorito.img \
        -no-emul-boot                     \
        -boot-load-size 4                 \
        -boot-info-table                  \
        --grub2-boot-info                 \
        --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        # Second boot entry
        -eltorito-alt-boot                \
        -e boot/grub/x86_64-efi/efi.img   \
        -no-emul-boot                     \
        # -isohybrid-gpt-basdat             \
        # Allow longer and more complex file names
        -r -J --joliet-long               \
        -allow-lowercase                  \
        -allow-multidot                   \
        -o ../lfs.iso                     \
        .

WORKDIR /build

###############################
# Image 5. The Final Artifact #
###############################
FROM scratch
COPY --from=iso-builder /build/lfs.iso /
