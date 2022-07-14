###############################
# II. Preparing for the Build #
###############################

#################
# Image 1. Host #
#################
FROM alpine:3.16 AS host

# Some temporary environment variables (including 4.4. Setting Up the Environment)
ARG LFS=/lfs
ARG LFS_USER=lfs
ARG LFS_GROUOP=lfs
ARG LFS_VERSION=11.1-systemd
ARG LC_ALL=POSIX
ARG LFS_TGT=x86_64-lfs-linux-gnu
ARG PATH=${LFS}/tools/bin:/bin:/usr/bin:/usr/sbin
ARG CONFIG_SITE=${MAKE_JOBS}/usr/share/config.site
ARG WGET="wget --no-verbose --show-progress --progress=bar:force:noscroll"
ARG MAKEFLAGS="-j8"

# 2.2. Host System Requirements
# TODO: remove the mirrors here
RUN apk add --no-cache \
        --repository https://mirrors.aliyun.com/alpine/v3.16/main/ \
        --repository https://mirrors.aliyun.com/alpine/v3.16/community/ \
        bash binutils bison \
        coreutils diffutils findutils \
        gawk gcc g++ grep gzip m4 make \
        patch perl python3 sed tar \
        texinfo wget xz

# Change the default shell to bash
RUN rm /bin/sh /bin/ash && ln -s /bin/bash /bin/sh && ln -s /bin/bash /bin/ash

# 4.2. Creating a limited directory layout in LFS filesystem
RUN mkdir -pv $LFS $LFS/{etc,var,lib64,sources} $LFS/usr/{bin,lib,sbin} && \
    ln -sv usr/bin $LFS/bin && \
    ln -sv usr/lib $LFS/lib && \
    ln -sv usr/sbin $LFS/sbin

# 4.3. Adding the LFS User
RUN adduser -D -s /bin/bash $LFS_USER && \
    adduser $LFS_USER $LFS_GROUOP && \
    chown -Rv $LFS_USER $LFS
USER ${LFS_USER}

# Add available source tarballs
# If sources is empty, the source code is downloaded only when it's needed to save space
ADD sources $LFS/sources
WORKDIR $LFS/sources

#############################################################
# III. Building the LFS Cross Toolchain and Temporary Tools #
#############################################################

# 5.2. Binutils-2.38 - Pass 1
RUN $WGET -nc https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.xz
RUN tar -xf binutils-2.38.tar.xz && \
    pushd binutils-2.38 && \
    mkdir -v build && \
    cd build && \
    ../configure --prefix=$LFS/tools \
        --with-sysroot=$LFS \
        --target=$LFS_TGT   \
        --disable-nls       \
        --disable-werror && \
    make && \
    make install && \
    popd && \
    rm -rv binutils-2.38

# 5.3. GCC-11.2.0 - Pass 1
RUN $WGET -nc \
    https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz \
    https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz \
    https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz \
    https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz
RUN tar -xf gcc-11.2.0.tar.xz && \
    pushd gcc-11.2.0 && \
    tar -xf ../mpfr-4.1.0.tar.xz && \
    mv -v mpfr-4.1.0 mpfr && \
    tar -xf ../gmp-6.2.1.tar.xz && \
    mv -v gmp-6.2.1 gmp && \
    tar -xf ../mpc-1.2.1.tar.gz && \
    mv -v mpc-1.2.1 mpc && \
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64 && \
    mkdir -v build && \
    cd build && \
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
        --enable-languages=c,c++ && \
    make && \
    make install && \
    cd .. && \
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
        `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h && \
    popd && \
    rm -rv gcc-11.2.0

# 5.4. Linux-5.16.9 API Headers
RUN $WGET -nc https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.16.9.tar.xz
RUN tar -xf linux-5.16.9.tar.xz && \
    pushd linux-5.16.9 && \
    make mrproper && \
    make headers && \
    find usr/include -name '.*' -delete && \
    rm usr/include/Makefile && \
    cp -rv usr/include $LFS/usr && \
    popd && \
    rm -rv linux-5.16.9

# 5.5. Glibc-2.35
RUN $WGET -nc \
    https://ftp.gnu.org/gnu/glibc/glibc-2.35.tar.xz \
    https://www.linuxfromscratch.org/patches/lfs/11.1/glibc-2.35-fhs-1.patch
RUN tar -xf glibc-2.35.tar.xz && \
    pushd glibc-2.35 && \
    ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64 && \
    ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3 && \
    patch -Np1 -i ../glibc-2.35-fhs-1.patch && \
    mkdir -v build && \
    cd build && \
    echo "rootsbindir=/usr/sbin" > configparms && \
    ../configure                           \
        --prefix=/usr                      \
        --host=$LFS_TGT                    \
        --build=$(../scripts/config.guess) \
        --enable-kernel=3.2                \
        --with-headers=$LFS/usr/include    \
        libc_cv_slibdir=/usr/lib && \
    make && \
    make DESTDIR=$LFS install && \
    sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd && \
    $LFS/tools/libexec/gcc/$LFS_TGT/11.2.0/install-tools/mkheaders && \
    popd && \
    rm -rv glibc-2.35

# 5.6. Libstdc++ from GCC-11.2.0, Pass 1
RUN tar -xf gcc-11.2.0.tar.xz && \
    pushd gcc-11.2.0 && \
    mkdir -v build && \
    cd build && \
    ../libstdc++-v3/configure           \
        --host=$LFS_TGT                 \
        --build=$(../config.guess)      \
        --prefix=/usr                   \
        --disable-multilib              \
        --disable-nls                   \
        --disable-libstdcxx-pch         \
        --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/11.2.0 && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv gcc-11.2.0

# 6.2. M4-1.4.19
RUN $WGET -nc \
    https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz
RUN tar -xf m4-1.4.19.tar.xz && \
    pushd m4-1.4.19 && \
    ./configure --prefix=/usr   \
        --host=$LFS_TGT         \
        --build=$(build-aux/config.guess) && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv m4-1.4.19

# 6.3. Ncurses-6.3
RUN $WGET -nc https://invisible-mirror.net/archives/ncurses/ncurses-6.3.tar.gz
RUN tar -xf ncurses-6.3.tar.gz && \
    pushd ncurses-6.3 && \
    sed -i s/mawk// configure && \
    mkdir build && \
    pushd build && \
    ../configure && \
    make -C include && \
    make -C progs tic && \
    popd && \
    ./configure --prefix=/usr            \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-debug              \
            --without-ada                \
            --without-normal             \
            --disable-stripping          \
            --enable-widec && \
    make && \
    make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install && \
    echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so && \
    popd && \
    rm -rv ncurses-6.3

# 6.4. Bash-5.1.16
RUN $WGET -nc https://ftp.gnu.org/gnu/bash/bash-5.1.16.tar.gz
RUN tar -xf bash-5.1.16.tar.gz && \
    pushd bash-5.1.16 && \
    ./configure --prefix=/usr           \
        --build=$(support/config.guess) \
        --host=$LFS_TGT                 \
        --without-bash-malloc && \
    make && \
    make DESTDIR=$LFS install && \
    ln -sv bash $LFS/bin/sh && \
    popd && \
    rm -rv bash-5.1.16

# 6.5. Coreutils-9.0
RUN $WGET -nc https://ftp.gnu.org/gnu/coreutils/coreutils-9.0.tar.xz
RUN tar -xf coreutils-9.0.tar.xz && \
    pushd coreutils-9.0 && \
    ./configure --prefix=/usr             \
        --host=$LFS_TGT                   \
        --build=$(build-aux/config.guess) \
        --enable-install-program=hostname \
        --enable-no-install-program=kill,uptime && \
    make && \
    make DESTDIR=$LFS install && \
    mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin && \
    mkdir -pv $LFS/usr/share/man/man8 && \
    mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8 && \
    sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8 && \
    popd && \
    rm -rv coreutils-9.0

# 6.6. Diffutils-3.8
RUN $WGET -nc https://ftp.gnu.org/gnu/diffutils/diffutils-3.8.tar.xz
RUN tar -xf diffutils-3.8.tar.xz && \
    pushd diffutils-3.8 && \
    ./configure --prefix=/usr --host=$LFS_TGT && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv diffutils-3.8

# 6.7. File-5.41
RUN $WGET -nc https://astron.com/pub/file/file-5.41.tar.gz
RUN tar -xf file-5.41.tar.gz && \
    pushd file-5.41 && \
    mkdir build && \
    pushd build && \
    ../configure --disable-bzlib     \
                --disable-libseccomp \
                --disable-xzlib      \
                --disable-zlib && \
    make && \
    popd && \
    ./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess) && \
    make FILE_COMPILE=$(pwd)/build/src/file && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv file-5.41

# 6.8. Findutils-4.9.0
RUN $WGET -nc https://ftp.gnu.org/gnu/findutils/findutils-4.9.0.tar.xz
RUN tar -xf findutils-4.9.0.tar.xz && \
    pushd findutils-4.9.0 && \
    ./configure --prefix=/usr           \
        --localstatedir=/var/lib/locate \
        --host=$LFS_TGT                 \
        --build=$(build-aux/config.guess) && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv findutils-4.9.0

# 6.9. Gawk-5.1.1
RUN $WGET -nc https://ftp.gnu.org/gnu/gawk/gawk-5.1.1.tar.xz
RUN tar -xf gawk-5.1.1.tar.xz && \
    pushd gawk-5.1.1 && \
    sed -i 's/extras//' Makefile.in && \
    ./configure --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess) && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv gawk-5.1.1

# 6.10. Grep-3.7
RUN $WGET -nc https://ftp.gnu.org/gnu/grep/grep-3.7.tar.xz
RUN tar -xf grep-3.7.tar.xz && \
    pushd grep-3.7 && \
    ./configure --prefix=/usr --host=$LFS_TGT && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv grep-3.7

# 6.11. Gzip-1.11
RUN $WGET -nc https://ftp.gnu.org/gnu/gzip/gzip-1.11.tar.xz
RUN tar -xf gzip-1.11.tar.xz && \
    pushd gzip-1.11 && \
    ./configure --prefix=/usr --host=$LFS_TGT && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv gzip-1.11

# 6.12. Make-4.3
RUN $WGET -nc https://ftp.gnu.org/gnu/make/make-4.3.tar.gz
RUN tar -xf make-4.3.tar.gz && \
    pushd make-4.3 && \
    ./configure         \
        --prefix=/usr   \
        --without-guile \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess) && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv make-4.3

# 6.13. Patch-2.7.6
RUN $WGET -nc https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz
RUN tar -xf patch-2.7.6.tar.xz && \
    pushd patch-2.7.6 && \
    ./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess) && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv patch-2.7.6

# 6.14. Sed-4.8
RUN $WGET -nc https://ftp.gnu.org/gnu/sed/sed-4.8.tar.xz
RUN tar -xf sed-4.8.tar.xz && \
    pushd sed-4.8 && \
    ./configure --prefix=/usr --host=$LFS_TGT && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv sed-4.8

# 6.15. Tar-1.34
RUN $WGET -nc https://ftp.gnu.org/gnu/tar/tar-1.34.tar.xz
RUN tar -xf tar-1.34.tar.xz && \
    pushd tar-1.34 && \
    ./configure --prefix=/usr                 \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv tar-1.34

# 6.16. Xz-5.2.5
RUN $WGET -nc https://tukaani.org/xz/xz-5.2.5.tar.xz
RUN tar -xf xz-5.2.5.tar.xz && \
    pushd xz-5.2.5 && \
    ./configure --prefix=/usr                 \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.2.5 && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv xz-5.2.5

# 6.17. Binutils-2.38 - Pass 2
RUN tar -xf binutils-2.38.tar.xz && \
    pushd binutils-2.38 && \
    sed '6009s/$add_dir//' -i ltmain.sh && \
    mkdir -v build && \
    cd build && \
    ../configure                   \
        --prefix=/usr              \
        --build=$(../config.guess) \
        --host=$LFS_TGT            \
        --disable-nls              \
        --enable-shared            \
        --disable-werror           \
        --enable-64-bit-bfd && \
    make && \
    make DESTDIR=$LFS install && \
    popd && \
    rm -rv binutils-2.38

# 6.18. GCC-11.2.0 - Pass 2
RUN tar -xf gcc-11.2.0.tar.xz && \
    pushd gcc-11.2.0 && \
    tar -xf ../mpfr-4.1.0.tar.xz && \
    mv -v mpfr-4.1.0 mpfr && \
    tar -xf ../gmp-6.2.1.tar.xz && \
    mv -v gmp-6.2.1 gmp && \
    tar -xf ../mpc-1.2.1.tar.gz && \
    mv -v mpc-1.2.1 mpc && \
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64 && \
    mkdir -v build && \
    cd build && \
    mkdir -pv $LFS_TGT/libgcc && \
    ln -s ../../../libgcc/gthr-posix.h $LFS_TGT/libgcc/gthr-default.h && \
    ../configure                                       \
        --build=$(../config.guess)                     \
        --host=$LFS_TGT                                \
        --prefix=/usr                                  \
        CC_FOR_TARGET=$LFS_TGT-gcc                     \
        --with-build-sysroot=$LFS                      \
        --enable-initfini-array                        \
        --disable-nls                                  \
        --disable-multilib                             \
        --disable-decimal-float                        \
        --disable-libatomic                            \
        --disable-libgomp                              \
        --disable-libquadmath                          \
        --disable-libssp                               \
        --disable-libvtv                               \
        --disable-libstdcxx                            \
        --enable-languages=c,c++ && \
    make && \
    make DESTDIR=$LFS install && \
    ln -sv gcc $LFS/usr/bin/cc && \
    popd && \
    rm -rv gcc-11.2.0

# 7.2. Changing Ownership
USER root
RUN chown -R root:root $LFS

# Download rest of the packages since we will not have network for a while
RUN $WGET -nc --input-file=wget-list

######################
# Image 2. Toolchain #
######################
FROM scratch AS toolchain

ARG LFS
ARG LFS_TGT
ARG MAKEFLAGS

# Copy the LFS root directory from previous build
COPY --from=host ${LFS} /

# NOTE: section "7.3. Preparing Virtual Kernel File Systems" is automatically set up by Docker

# 7.4. Entering the Chroot Environment
ENV HOME=/root
ENV PS1='[toolchain] \u:\w\$ '
ENV PATH=/usr/bin:/usr/sbin
ENTRYPOINT [ "/bin/bash" ]

# 7.5. Creating Directories
RUN mkdir -pv /{boot,home,mnt,opt,srv} && \
    mkdir -pv /etc/{opt,sysconfig} && \
    mkdir -pv /lib/firmware && \
    mkdir -pv /media/{floppy,cdrom} && \
    mkdir -pv /usr/{,local/}{include,src} && \
    mkdir -pv /usr/local/{bin,lib,sbin} && \
    mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man} && \
    mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo} && \
    mkdir -pv /usr/{,local/}share/man/man{1..8} && \
    mkdir -pv /var/{cache,local,log,mail,opt,spool} && \
    mkdir -pv /var/lib/{color,misc,locate} && \
    ln -sfv /run /var/run && \
    ln -sfv /run/lock /var/lock && \
    install -dv -m 0750 /root && \
    install -dv -m 1777 /tmp /var/tmp

# 7.6. Creating Essential Files and Symlinks
# Skipping `ln -sv /proc/self/mounts /etc/mtab` since it's created by Docker
ADD resources/passwd resources/group /etc/
RUN echo "127.0.0.1  localhost $(hostname)" >> /etc/hosts && \
    echo "::1        localhost" >> /etc/hosts && \
    echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd && \
    echo "tester:x:101:" >> /etc/group && \
    install -o tester -d /home/tester && \
    touch /var/log/{btmp,lastlog,faillog,wtmp} && \
    chgrp -v utmp /var/log/lastlog && \
    chmod -v 664  /var/log/lastlog && \
    chmod -v 600  /var/log/btmp

WORKDIR /sources

# 7.7. Libstdc++ from GCC-11.2.0, Pass 2
RUN tar -xf gcc-11.2.0.tar.xz && \
    pushd gcc-11.2.0 && \
    ln -s gthr-posix.h libgcc/gthr-default.h && \
    mkdir -v build && \
    cd build && \
    ../libstdc++-v3/configure            \
        CXXFLAGS="-g -O2 -D_GNU_SOURCE"  \
        --prefix=/usr                    \
        --disable-multilib               \
        --disable-nls                    \
        --host=$LFS_TGT                  \
        --disable-libstdcxx-pch && \
    make && \
    make install && \
    popd && \
    rm -rv gcc-11.2.0

# 7.8. Gettext-0.21
RUN tar -xf gettext-0.21.tar.xz && \
    pushd gettext-0.21 && \
    ./configure --disable-shared && \
    make && \
    cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin && \
    popd && \
    rm -rv gettext-0.21

# 7.9. Bison-3.8.2
RUN tar -xf bison-3.8.2.tar.xz && \
    pushd bison-3.8.2 && \
    ./configure --prefix=/usr \
        --docdir=/usr/share/doc/bison-3.8.2 && \
    make && \
    make install && \
    popd && \
    rm -rv bison-3.8.2

# 7.10. Perl-5.34.0
RUN tar -xf perl-5.34.0.tar.xz && \
    pushd perl-5.34.0 && \
    sh Configure -des                               \
        -Dprefix=/usr                               \
        -Dvendorprefix=/usr                         \
        -Dprivlib=/usr/lib/perl5/5.34/core_perl     \
        -Darchlib=/usr/lib/perl5/5.34/core_perl     \
        -Dsitelib=/usr/lib/perl5/5.34/site_perl     \
        -Dsitearch=/usr/lib/perl5/5.34/site_perl    \
        -Dvendorlib=/usr/lib/perl5/5.34/vendor_perl \
        -Dvendorarch=/usr/lib/perl5/5.34/vendor_perl && \
    make && \
    make install && \
    popd && \
    rm -rv perl-5.34.0

# 7.11. Python-3.10.2
RUN tar -xf Python-3.10.2.tar.xz && \
    pushd Python-3.10.2 && \
    ./configure --prefix=/usr   \
        --enable-shared \
        --without-ensurepip && \
    make && \
    make install && \
    popd && \
    rm -rv Python-3.10.2

# 7.12. Texinfo-6.8
RUN tar -xf texinfo-6.8.tar.xz && \
    pushd texinfo-6.8 && \
    sed -e 's/__attribute_nonnull__/__nonnull/' \
        -i gnulib/lib/malloc/dynarray-skeleton.c && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    popd && \
    rm -rv texinfo-6.8

# 7.13. Util-linux-2.37.4
RUN tar -xf util-linux-2.37.4.tar.xz && \
    pushd util-linux-2.37.4 && \
    mkdir -pv /var/lib/hwclock && \
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
        runstatedir=/run && \
    make && \
    make install && \
    popd && \
    rm -rv util-linux-2.37.4

# 7.14. Cleaning up and Saving the Temporary System
RUN rm -rf /usr/share/{info,man,doc}/* && \
    find /usr/{lib,libexec} -name \*.la -delete && \
    rm -rf /tools

###############################
# IV. Building the LFS System #
###############################
