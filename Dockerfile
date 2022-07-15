# Based on LFS 11.1-systemd, published on March 1st, 2022

###############################
# II. Preparing for the Build #
###############################

ARG LFS=/lfs
ARG LFS_TGT=x86_64-lfs-linux-gnu
ARG LFS_USER=lfs
ARG LFS_GROUOP=lfs
ARG LFS_HOSTNAME=lfs
ARG ENABLE_TESTS=false
ARG MAKEFLAGS="-j8"

#################
# Image 1. Host #
#################
FROM alpine:3.16 AS host

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
        texinfo wget xz

# Change the default shell to bash
RUN rm /bin/sh /bin/ash && ln -s /bin/bash /bin/sh && ln -s /bin/bash /bin/ash

ARG LFS
ENV PATH=${LFS}/tools/bin:/bin:/sbin:/usr/bin:/usr/sbin
ENV LC_ALL=POSIX
ENV CONFIG_SITE=${LFS}/usr/share/config.site

# 4.2. Creating a limited directory layout in LFS filesystem
RUN mkdir -pv $LFS $LFS/{etc,var,lib64,sources} $LFS/usr/{bin,lib,sbin} && \
    ln -sv usr/bin $LFS/bin && \
    ln -sv usr/lib $LFS/lib && \
    ln -sv usr/sbin $LFS/sbin

# 4.3. Adding the LFS User
ARG LFS_USER
ARG LFS_GROUOP
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

ARG LFS_TGT
ARG MAKEFLAGS
ARG WGET="wget --no-verbose --show-progress --progress=bar:force:noscroll"

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

# Copy the LFS root directory from previous build
COPY --from=host ${LFS} /

# NOTE: section "7.3. Preparing Virtual Kernel File Systems" is automatically set up by Docker
# RUN mkdir -pv /{dev,proc,sys,run}

# 7.4. Entering the Chroot Environment
ENV HOME=/root
ENV PS1='[toolchain] \u:\w\$ '
ENV PATH=/bin:/usr/bin:/usr/sbin
ENTRYPOINT [ "/bin/bash" ]

# 7.5. Creating Directories
RUN mkdir -pv /{boot,home,mnt,opt,srv,run} && \
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
ARG LFS_TGT
ARG MAKEFLAGS

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

###################
# Image 3. System #
###################
FROM toolchain AS system

ARG ENABLE_TESTS
ARG MAKEFLAGS

# 8.3. Man-pages-5.13
RUN tar -xf man-pages-5.13.tar.xz && \
    pushd man-pages-5.13 && \
    make prefix=/usr install && \
    popd && \
    rm -rv man-pages-5.13

# 8.4. Iana-Etc-20220207
RUN tar -xf iana-etc-20220207.tar.gz && \
    pushd iana-etc-20220207 && \
    cp services protocols /etc && \
    popd && \
    rm -rv iana-etc-20220207

# 8.5. Glibc-2.35
# TODO: make the result of `make check` more visible
RUN tar -xf glibc-2.35.tar.xz && \
    pushd glibc-2.35 && \
    patch -Np1 -i ../glibc-2.35-fhs-1.patch && \
    mkdir -v build && \
    cd build && \
    echo "rootsbindir=/usr/sbin" > configparms && \
    ../configure --prefix=/usr                   \
        --disable-werror                         \
        --enable-kernel=3.2                      \
        --enable-stack-protector=strong          \
        --with-headers=/usr/include              \
        libc_cv_slibdir=/usr/lib && \
    make && \
    if $ENABLE_TESTS; then (make check || true); fi && \
    touch /etc/ld.so.conf && \
    sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile && \
    make install && \
    sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd && \
    cp -v ../nscd/nscd.conf /etc/nscd.conf && \
    mkdir -pv /var/cache/nscd && \
    install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf && \
    install -v -Dm644 ../nscd/nscd.service /usr/lib/systemd/system/nscd.service && \
    mkdir -pv /usr/lib/locale && \
    localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true && \
    localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8 && \
    localedef -i de_DE -f ISO-8859-1 de_DE && \
    localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro && \
    localedef -i de_DE -f UTF-8 de_DE.UTF-8 && \
    localedef -i el_GR -f ISO-8859-7 el_GR && \
    localedef -i en_GB -f ISO-8859-1 en_GB && \
    localedef -i en_GB -f UTF-8 en_GB.UTF-8 && \
    localedef -i en_HK -f ISO-8859-1 en_HK && \
    localedef -i en_PH -f ISO-8859-1 en_PH && \
    localedef -i en_US -f ISO-8859-1 en_US && \
    localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    localedef -i es_ES -f ISO-8859-15 es_ES@euro && \
    localedef -i es_MX -f ISO-8859-1 es_MX && \
    localedef -i fa_IR -f UTF-8 fa_IR && \
    localedef -i fr_FR -f ISO-8859-1 fr_FR && \
    localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro && \
    localedef -i fr_FR -f UTF-8 fr_FR.UTF-8 && \
    localedef -i is_IS -f ISO-8859-1 is_IS && \
    localedef -i is_IS -f UTF-8 is_IS.UTF-8 && \
    localedef -i it_IT -f ISO-8859-1 it_IT && \
    localedef -i it_IT -f ISO-8859-15 it_IT@euro && \
    localedef -i it_IT -f UTF-8 it_IT.UTF-8 && \
    localedef -i ja_JP -f EUC-JP ja_JP && \
    (localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true) && \
    localedef -i ja_JP -f UTF-8 ja_JP.UTF-8 && \
    localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro && \
    localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R && \
    localedef -i ru_RU -f UTF-8 ru_RU.UTF-8 && \
    localedef -i se_NO -f UTF-8 se_NO.UTF-8 && \
    localedef -i ta_IN -f UTF-8 ta_IN.UTF-8 && \
    localedef -i tr_TR -f UTF-8 tr_TR.UTF-8 && \
    localedef -i zh_CN -f GB18030 zh_CN.GB18030 && \
    localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS && \
    localedef -i zh_TW -f UTF-8 zh_TW.UTF-8 && \
    popd && \
    rm -rv glibc-2.35

# 8.5.2. Configuring Glibc
# NOTE: defaulting to US eastern time
ADD resources/nsswitch.conf /etc/nsswitch.conf
ADD resources/ld.so.conf /etc/ld.so.conf
RUN mkdir -v tmp && \
    pushd tmp && \
    tar -xf ../tzdata2021e.tar.gz && \
    ZONEINFO=/usr/share/zoneinfo && \
    mkdir -pv $ZONEINFO/{posix,right} && \
    for tz in etcetera southamerica northamerica europe africa antarctica \
            asia australasia backward; do \
        zic -L /dev/null   -d $ZONEINFO       ${tz} || exit 1; \
        zic -L /dev/null   -d $ZONEINFO/posix ${tz} || exit 1; \
        zic -L leapseconds -d $ZONEINFO/right ${tz} || exit 1; \
    done && \
    cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO && \
    zic -d $ZONEINFO -p America/New_York && \
    unset ZONEINFO && \
    ln -sfv /usr/share/zoneinfo/America/New_York /etc/localtime && \
    mkdir -pv /etc/ld.so.conf.d && \
    popd && \
    rm -rv tmp

# 8.6. Zlib-1.2.12
# NOTE: the original LFS 11.1 uses Zlib-1.2.11
RUN tar -xf zlib-1.2.12.tar.xz && \
    pushd zlib-1.2.12 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    rm -fv /usr/lib/libz.a && \
    popd && \
    rm -rv zlib-1.2.12

# 8.7. Bzip2-1.0.8
RUN tar -xf bzip2-1.0.8.tar.gz && \
    pushd bzip2-1.0.8 && \
    patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch && \
    sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile && \
    sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile && \
    make -f Makefile-libbz2_so && \
    make clean && \
    make && \
    make PREFIX=/usr install && \
    cp -av libbz2.so.* /usr/lib && \
    ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so && \
    cp -v bzip2-shared /usr/bin/bzip2 && \
    ln -sfv bzip2 /usr/bin/bzcat && \
    ln -sfv bzip2 /usr/bin/bunzip2 && \
    rm -fv /usr/lib/libbz2.a && \
    popd && \
    rm -rv bzip2-1.0.8

# 8.8. Xz-5.2.5
RUN tar -xf xz-5.2.5.tar.xz && \
    pushd xz-5.2.5 && \
    ./configure --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/xz-5.2.5 && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    rm -fv /usr/lib/libz.a && \
    popd && \
    rm -rv xz-5.2.5

# 8.9. Zstd-1.5.2
RUN tar -xf zstd-1.5.2.tar.gz && \
    pushd zstd-1.5.2 && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make prefix=/usr install && \
    rm -fv /usr/lib/libzstd.a && \
    popd && \
    rm -rv zstd-1.5.2

# 8.10. File-5.41
RUN tar -xf file-5.41.tar.gz && \
    pushd file-5.41 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv file-5.41

# 8.11. Readline-8.1.2
RUN tar -xf readline-8.1.2.tar.gz && \
    pushd readline-8.1.2 && \
    sed -i '/MV.*old/d' Makefile.in && \
    sed -i '/{OLDSUFF}/c:' support/shlib-install && \
    ./configure --prefix=/usr \
        --disable-static \
        --with-curses    \
        --docdir=/usr/share/doc/readline-8.1.2 && \
    make SHLIB_LIBS="-lncursesw" && \
    make SHLIB_LIBS="-lncursesw" install && \
    install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.1.2 && \
    popd && \
    rm -rv readline-8.1.2

# 8.12. M4-1.4.19
RUN tar -xf m4-1.4.19.tar.xz && \
    pushd m4-1.4.19 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv m4-1.4.19

# 8.13. Bc-5.2.2
RUN tar -xf bc-5.2.2.tar.xz && \
    pushd bc-5.2.2 && \
    CC=gcc ./configure --prefix=/usr -G -O3 && \
    make && \
    if $ENABLE_TESTS; then make test; fi && \
    make install && \
    popd && \
    rm -rv bc-5.2.2

# 8.14. Flex-2.6.4
RUN tar -xf flex-2.6.4.tar.gz && \
    pushd flex-2.6.4 && \
    ./configure --prefix=/usr \
        --docdir=/usr/share/doc/flex-2.6.4 \
        --disable-static && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    ln -sv flex /usr/bin/lex && \
    popd && \
    rm -rv flex-2.6.4

# 8.15. Tcl-8.6.12
RUN tar -xf tcl8.6.12-src.tar.gz && \
    pushd tcl8.6.12 && \
    tar -xf ../tcl8.6.12-html.tar.gz --strip-components=1 && \
    SRCDIR=$(pwd) && \
    cd unix && \
    ./configure --prefix=/usr           \
                --mandir=/usr/share/man \
                --enable-64bit && \
    make && \
    sed -e "s|$SRCDIR/unix|/usr/lib|" \
        -e "s|$SRCDIR|/usr/include|"  \
        -i tclConfig.sh && \
    sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.3|/usr/lib/tdbc1.1.3|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.3/generic|/usr/include|"    \
        -e "s|$SRCDIR/pkgs/tdbc1.1.3/library|/usr/lib/tcl8.6|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.3|/usr/include|"            \
        -i pkgs/tdbc1.1.3/tdbcConfig.sh && \
    sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.2|/usr/lib/itcl4.2.2|" \
        -e "s|$SRCDIR/pkgs/itcl4.2.2/generic|/usr/include|"    \
        -e "s|$SRCDIR/pkgs/itcl4.2.2|/usr/include|"            \
        -i pkgs/itcl4.2.2/itclConfig.sh && \
    unset SRCDIR && \
    if $ENABLE_TESTS; then make test; fi && \
    make install && \
    chmod -v u+w /usr/lib/libtcl8.6.so && \
    make install-private-headers && \
    ln -sfv tclsh8.6 /usr/bin/tclsh && \
    mv /usr/share/man/man3/{Thread,Tcl_Thread}.3 && \
    mkdir -v -p /usr/share/doc/tcl-8.6.12 && \
    cp -v -r  ../html/* /usr/share/doc/tcl-8.6.12 && \
    popd && \
    rm -rv tcl8.6.12

# 8.16. Expect-5.45.4
RUN tar -xf expect5.45.4.tar.gz && \
    pushd expect5.45.4 && \
    ./configure --prefix=/usr   \
        --with-tcl=/usr/lib     \
        --enable-shared         \
        --mandir=/usr/share/man \
        --with-tclinclude=/usr/include && \
    make && \
    if $ENABLE_TESTS; then make test; fi && \
    make install && \
    ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib && \
    popd && \
    rm -rv expect5.45.4

# 8.17. DejaGNU-1.6.3
RUN tar -xf dejagnu-1.6.3.tar.gz && \
    pushd dejagnu-1.6.3 && \
    mkdir -v build && \
    cd build && \
    ../configure --prefix=/usr && \
    makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi && \
    makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi && \
    make install && \
    install -v -dm755  /usr/share/doc/dejagnu-1.6.3 && \
    install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3 && \
    if $ENABLE_TESTS; then make check; fi && \
    popd && \
    rm -rv dejagnu-1.6.3

# 8.18. Binutils-2.38
# NOTE: skipping the PTY test here since we don't have any during docker build
RUN tar -xf binutils-2.38.tar.xz && \
    pushd binutils-2.38 && \
    patch -Np1 -i ../binutils-2.38-lto_fix-1.patch && \
    sed -e '/R_386_TLS_LE /i \   || (TYPE) == R_386_TLS_IE \\' \
        -i ./bfd/elfxx-x86.h && \
    mkdir -v build && \
    cd build && \
    ../configure --prefix=/usr \
        --enable-gold       \
        --enable-ld=default \
        --enable-plugins    \
        --enable-shared     \
        --disable-werror    \
        --enable-64-bit-bfd \
        --with-system-zlib && \
    make tooldir=/usr && \
    if $ENABLE_TESTS; then make -k check; fi && \
    make tooldir=/usr install && \
    rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.a && \
    popd && \
    rm -rv binutils-2.38

# 8.19. GMP-6.2.1
RUN tar -xf gmp-6.2.1.tar.xz && \
    pushd gmp-6.2.1 && \
    cp -v configfsf.guess config.guess && \
    cp -v configfsf.sub   config.sub && \
    ./configure --prefix=/usr \
        --enable-cxx     \
        --disable-static \
        --docdir=/usr/share/doc/gmp-6.2.1 \
        --build=x86_64-pc-linux-gnu && \
    make && \
    make html && \
    if $ENABLE_TESTS; then \
        make check 2>&1 | tee gmp-check-log && \
        awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log; \
    fi && \
    make install && \
    make install-html && \
    popd && \
    rm -rv gmp-6.2.1

# 8.20. MPFR-4.1.0
RUN tar -xf mpfr-4.1.0.tar.xz && \
    pushd mpfr-4.1.0 && \
    ./configure --prefix=/usr \
        --disable-static     \
        --enable-thread-safe \
        --docdir=/usr/share/doc/mpfr-4.1.0 && \
    make && \
    make html && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    make install-html && \
    popd && \
    rm -rv mpfr-4.1.0

# 8.21. MPC-1.2.1
RUN tar -xf mpc-1.2.1.tar.gz && \
    pushd mpc-1.2.1 && \
    ./configure --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/mpc-1.2.1 && \
    make && \
    make html && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    make install-html && \
    popd && \
    rm -rv mpc-1.2.1

# 8.22. Attr-2.5.1
RUN tar -xf attr-2.5.1.tar.gz && \
    pushd attr-2.5.1 && \
    ./configure --prefix=/usr \
        --disable-static  \
        --sysconfdir=/etc \
        --docdir=/usr/share/doc/attr-2.5.1 && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv attr-2.5.1

# 8.23. Acl-2.3.1
RUN tar -xf acl-2.3.1.tar.xz && \
    pushd acl-2.3.1 && \
    ./configure --prefix=/usr \
        --disable-static      \
        --docdir=/usr/share/doc/acl-2.3.1 && \
    make && \
    make install && \
    popd && \
    rm -rv acl-2.3.1

# 8.24. Libcap-2.63
RUN tar -xf libcap-2.63.tar.xz && \
    pushd libcap-2.63 && \
    sed -i '/install -m.*STA/d' libcap/Makefile && \
    make prefix=/usr lib=lib && \
    if $ENABLE_TESTS; then make test; fi && \
    make prefix=/usr lib=lib install && \
    popd && \
    rm -rv libcap-2.63

# 8.25. Shadow-4.11.1
RUN tar -xf shadow-4.11.1.tar.xz && \
    pushd shadow-4.11.1 && \
    sed -i 's/groups$(EXEEXT) //' src/Makefile.in && \
    find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \; && \
    find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \; && \
    find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \; && \
    sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
        -e 's:/var/spool/mail:/var/mail:'                 \
        -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                \
        -i etc/login.defs && \
    touch /usr/bin/passwd && \
    ./configure --sysconfdir=/etc \
                --disable-static  \
                --with-group-name-max-length=32 && \
    make && \
    make exec_prefix=/usr install && \
    make -C man install-man && \
    popd && \
    rm -rv shadow-4.11.1

# 8.25.2. Configuring Shadow
RUN pwconv && \
    grpconv && \
    mkdir -p /etc/default && \
    useradd -D --gid 999
# NOTE: not doing `passwd root` for now

# 8.26. GCC-11.2.0
RUN tar -xf gcc-11.2.0.tar.xz && \
    pushd gcc-11.2.0 && \
    sed -e '/static.*SIGSTKSZ/d' \
        -e 's/return kAltStackSize/return SIGSTKSZ * 4/' \
        -i libsanitizer/sanitizer_common/sanitizer_posix_libcdep.cpp && \
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64 && \
    mkdir -v build && \
    cd build && \
    ../configure --prefix=/usr   \
        LD=ld                    \
        --enable-languages=c,c++ \
        --disable-multilib       \
        --disable-bootstrap      \
        --with-system-zlib && \
    make && \
    if $ENABLE_TESTS; then \
        ulimit -s 32768 && \
        chown -Rv tester . && \
        (su tester -c "PATH=$PATH make -k check" || true); \
    fi && \
    make install && \
    rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/11.2.0/include-fixed/bits/ && \
    chown -v -R root:root \
        /usr/lib/gcc/*linux-gnu/11.2.0/include{,-fixed} && \
    ln -svr /usr/bin/cpp /usr/lib && \
    ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/11.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/ && \
    mkdir -pv /usr/share/gdb/auto-load/usr/lib && \
    mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib && \
    popd && \
    rm -rv gcc-11.2.0

# 8.27. Pkg-config-0.29.2
RUN tar -xf pkg-config-0.29.2.tar.gz && \
    pushd pkg-config-0.29.2 && \
    ./configure --prefix=/usr              \
                --with-internal-glib       \
                --disable-host-tool        \
                --docdir=/usr/share/doc/pkg-config-0.29.2 && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv pkg-config-0.29.2

# 8.28. Ncurses-6.3
RUN tar -xf ncurses-6.3.tar.gz && \
    pushd ncurses-6.3 && \
    ./configure --prefix=/usr           \
                --mandir=/usr/share/man \
                --with-shared           \
                --without-debug         \
                --without-normal        \
                --enable-pc-files       \
                --enable-widec          \
                --with-pkg-config-libdir=/usr/lib/pkgconfig && \
    make && \
    make DESTDIR=$PWD/dest install && \
    install -vm755 dest/usr/lib/libncursesw.so.6.3 /usr/lib && \
    rm -v  dest/usr/lib/{libncursesw.so.6.3,libncurses++w.a} && \
    cp -av dest/* / && \
    for lib in ncurses form panel menu; do \
        rm -vf                    /usr/lib/lib${lib}.so || exit 1; \
        echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so || exit 1; \
        ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc || exit 1; \
    done && \
    rm -vf                     /usr/lib/libcursesw.so && \
    echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so && \
    ln -sfv libncurses.so      /usr/lib/libcurses.so && \
    mkdir -pv      /usr/share/doc/ncurses-6.3 && \
    cp -v -R doc/* /usr/share/doc/ncurses-6.3 && \
    popd && \
    rm -rv ncurses-6.3

# 8.29. Sed-4.8
RUN tar -xf sed-4.8.tar.xz && \
    pushd sed-4.8 && \
    ./configure --prefix=/usr && \
    make && \
    make html && \
    if $ENABLE_TESTS; then \
        chown -Rv tester . && \
        su tester -c "PATH=$PATH make check"; \
    fi && \
    make install && \
    install -d -m755           /usr/share/doc/sed-4.8 && \
    install -m644 doc/sed.html /usr/share/doc/sed-4.8 && \
    popd && \
    rm -rv sed-4.8

# 8.30. Psmisc-23.4
RUN tar -xf psmisc-23.4.tar.xz && \
    pushd psmisc-23.4 && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    popd && \
    rm -rv psmisc-23.4

# 8.31. Gettext-0.21
RUN tar -xf gettext-0.21.tar.xz && \
    pushd gettext-0.21 && \
    ./configure --prefix=/usr    \
                --disable-static \
                --docdir=/usr/share/doc/gettext-0.21 && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    chmod -v 0755 /usr/lib/preloadable_libintl.so && \
    popd && \
    rm -rv gettext-0.21

# 8.32. Bison-3.8.2
RUN tar -xf bison-3.8.2.tar.xz && \
    pushd bison-3.8.2 && \
    ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2 && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv bison-3.8.2

# 8.33. Grep-3.7
RUN tar -xf grep-3.7.tar.xz && \
    pushd grep-3.7 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv grep-3.7

# 8.34. Bash-5.1.16
# NOTE: skipping tests since no PTY is available
RUN tar -xf bash-5.1.16.tar.gz && \
    pushd bash-5.1.16 && \
    ./configure --prefix=/usr                       \
                --docdir=/usr/share/doc/bash-5.1.16 \
                --without-bash-malloc               \
                --with-installed-readline && \
    make && \
    make install && \
    popd && \
    rm -rv bash-5.1.16

# 8.35. Libtool-2.4.6
RUN tar -xf libtool-2.4.6.tar.xz && \
    pushd libtool-2.4.6 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    rm -fv /usr/lib/libltdl.a && \
    popd && \
    rm -rv libtool-2.4.6

# 8.36. GDBM-1.23
RUN tar -xf gdbm-1.23.tar.gz && \
    pushd gdbm-1.23 && \
    ./configure --prefix=/usr    \
                --disable-static \
                --enable-libgdbm-compat && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv gdbm-1.23

# 8.37. Gperf-3.1
RUN tar -xf gperf-3.1.tar.gz && \
    pushd gperf-3.1 && \
    ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1 && \
    make && \
    if $ENABLE_TESTS; then make -j1 check; fi && \
    make install && \
    popd && \
    rm -rv gperf-3.1

# 8.38. Expat-2.4.6
RUN tar -xf expat-2.4.6.tar.xz && \
    pushd expat-2.4.6 && \
    ./configure --prefix=/usr    \
                --disable-static \
                --docdir=/usr/share/doc/expat-2.4.6 && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.4.6 && \
    popd && \
    rm -rv expat-2.4.6

# 8.39. Inetutils-2.2
RUN tar -xf inetutils-2.2.tar.xz && \
    pushd inetutils-2.2 && \
    ./configure --prefix=/usr        \
                --bindir=/usr/bin    \
                --localstatedir=/var \
                --disable-logger     \
                --disable-whois      \
                --disable-rcp        \
                --disable-rexec      \
                --disable-rlogin     \
                --disable-rsh        \
                --disable-servers && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    mv -v /usr/{,s}bin/ifconfig && \
    popd && \
    rm -rv inetutils-2.2

# 8.40. Less-590
RUN tar -xf less-590.tar.gz && \
    pushd less-590 && \
    ./configure --prefix=/usr --sysconfdir=/etc && \
    make && \
    make install && \
    popd && \
    rm -rv less-590

# 8.41. Perl-5.34.0
RUN tar -xf perl-5.34.0.tar.xz && \
    pushd perl-5.34.0 && \
    patch -Np1 -i ../perl-5.34.0-upstream_fixes-1.patch && \
    export BUILD_ZLIB=False && \
    export BUILD_BZIP2=0 && \
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
                 -Dusethreads && \
    make && \
    if $ENABLE_TESTS; then make test; fi && \
    make install && \
    unset BUILD_ZLIB BUILD_BZIP2 && \
    popd && \
    rm -rv perl-5.34.0

# 8.42. XML::Parser-2.46
RUN tar -xf XML-Parser-2.46.tar.gz && \
    pushd XML-Parser-2.46 && \
    perl Makefile.PL && \
    make && \
    if $ENABLE_TESTS; then make test; fi && \
    make install && \
    popd && \
    rm -rv XML-Parser-2.46

# 8.43. Intltool-0.51.0
RUN tar -xf intltool-0.51.0.tar.gz && \
    pushd intltool-0.51.0 && \
    sed -i 's:\\\${:\\\$\\{:' intltool-update.in && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO && \
    popd && \
    rm -rv intltool-0.51.0

# 8.44. Autoconf-2.71
RUN tar -xf autoconf-2.71.tar.xz && \
    pushd autoconf-2.71 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv autoconf-2.71

# 8.45. Automake-1.16.5
RUN tar -xf automake-1.16.5.tar.xz && \
    pushd automake-1.16.5 && \
    ./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5 && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv automake-1.16.5

# 8.46. OpenSSL-3.0.1
RUN tar -xf openssl-3.0.1.tar.gz && \
    pushd openssl-3.0.1 && \
    ./config --prefix=/usr         \
             --openssldir=/etc/ssl \
             --libdir=lib          \
             shared                \
             zlib-dynamic && \
    make && \
    if $ENABLE_TESTS; then make test || true; fi && \
    sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile && \
    make MANSUFFIX=ssl install && \
    mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.0.1 && \
    cp -vfr doc/* /usr/share/doc/openssl-3.0.1 && \
    popd && \
    rm -rv openssl-3.0.1

# 8.47. Kmod-29
RUN tar -xf kmod-29.tar.xz && \
    pushd kmod-29 && \
    ./configure --prefix=/usr          \
                --sysconfdir=/etc      \
                --with-openssl         \
                --with-xz              \
                --with-zstd            \
                --with-zlib && \
    make && \
    make install && \
    for target in depmod insmod modinfo modprobe rmmod; do \
        ln -sfv ../bin/kmod /usr/sbin/$target || exit 1; \
    done && \
    ln -sfv kmod /usr/bin/lsmod && \
    popd && \
    rm -rv kmod-29

# 8.48. Libelf from Elfutils-0.186
RUN tar -xf elfutils-0.186.tar.bz2 && \
    pushd elfutils-0.186 && \
    ./configure --prefix=/usr                \
                --disable-debuginfod         \
                --enable-libdebuginfod=dummy && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make -C libelf install && \
    install -vm644 config/libelf.pc /usr/lib/pkgconfig && \
    rm /usr/lib/libelf.a && \
    popd && \
    rm -rv elfutils-0.186

# 8.49. Libffi-3.4.2
RUN tar -xf libffi-3.4.2.tar.gz && \
    pushd libffi-3.4.2 && \
    ./configure --prefix=/usr          \
                --disable-static       \
                --with-gcc-arch=native \
                --disable-exec-static-tramp && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv libffi-3.4.2

# 8.50. Python-3.10.2
RUN tar -xf Python-3.10.2.tar.xz && \
    pushd Python-3.10.2 && \
    ./configure --prefix=/usr        \
                --enable-shared      \
                --with-system-expat  \
                --with-system-ffi    \
                --with-ensurepip=yes \
                --enable-optimizations && \
    make && \
    make install && \
    install -v -dm755 /usr/share/doc/python-3.10.2/html && \
    tar --strip-components=1  \
        --no-same-owner       \
        --no-same-permissions \
        -C /usr/share/doc/python-3.10.2/html \
        -xvf ../python-3.10.2-docs-html.tar.bz2 && \
    popd && \
    rm -rv Python-3.10.2

# 8.51. Ninja-1.10.2
# NOTE: skipping setting NINJAJOBS
RUN tar -xf ninja-1.10.2.tar.gz && \
    pushd ninja-1.10.2 && \
    sed -i '/int Guess/a \
        int   j = 0;\
        char* jobs = getenv( "NINJAJOBS" );\
        if ( jobs != NULL ) j = atoi( jobs );\
        if ( j > 0 ) return j;\
        ' src/ninja.cc && \
    python3 configure.py --bootstrap && \
    if $ENABLE_TESTS; then \
        ./ninja ninja_test && \
        ./ninja_test --gtest_filter=-SubprocessTest.SetWithLots; \
    fi && \
    install -vm755 ninja /usr/bin/ && \
    install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja && \
    install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja && \
    popd && \
    rm -rv ninja-1.10.2

# 8.52. Meson-0.61.1
RUN tar -xf meson-0.61.1.tar.gz && \
    pushd meson-0.61.1 && \
    python3 setup.py build && \
    python3 setup.py install --root=dest && \
    cp -rv dest/* / && \
    install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson && \
    install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson && \
    popd && \
    rm -rv meson-0.61.1

# 8.53. Coreutils-9.0
RUN tar -xf coreutils-9.0.tar.xz && \
    pushd coreutils-9.0 && \
    patch -Np1 -i ../coreutils-9.0-i18n-1.patch && \
    patch -Np1 -i ../coreutils-9.0-chmod_fix-1.patch && \
    autoreconf -fiv && \
    FORCE_UNSAFE_CONFIGURE=1 ./configure \
                --prefix=/usr            \
                --enable-no-install-program=kill,uptime && \
    make && \
    if $ENABLE_TESTS; then \
        make NON_ROOT_USERNAME=tester check-root && \
        echo "dummy:x:102:tester" >> /etc/group && \
        chown -Rv tester . && \
        su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check" && \
        sed -i '/dummy/d' /etc/group; \
    fi && \
    make install && \
    mv -v /usr/bin/chroot /usr/sbin && \
    mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8 && \
    sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8 && \
    popd && \
    rm -rv coreutils-9.0

# 8.54. Check-0.15.2
RUN tar -xf check-0.15.2.tar.gz && \
    pushd check-0.15.2 && \
    ./configure --prefix=/usr --disable-static && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make docdir=/usr/share/doc/check-0.15.2 install && \
    popd && \
    rm -rv check-0.15.2

# 8.55. Diffutils-3.8
RUN tar -xf diffutils-3.8.tar.xz && \
    pushd diffutils-3.8 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv diffutils-3.8

# 8.56. Gawk-5.1.1
RUN tar -xf gawk-5.1.1.tar.xz && \
    pushd gawk-5.1.1 && \
    sed -i 's/extras//' Makefile.in && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    mkdir -pv                                   /usr/share/doc/gawk-5.1.1 && \
    cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.1.1 && \
    popd && \
    rm -rv gawk-5.1.1

# 8.57. Findutils-4.9.0
RUN tar -xf findutils-4.9.0.tar.xz && \
    pushd findutils-4.9.0 && \
    ./configure --prefix=/usr --localstatedir=/var/lib/locate && \
    make && \
    if $ENABLE_TESTS; then \
        chown -Rv tester . && \
        su tester -c "PATH=$PATH make check"; \
    fi && \
    make install && \
    popd && \
    rm -rv findutils-4.9.0

# 8.58. Groff-1.22.4
RUN tar -xf groff-1.22.4.tar.gz && \
    pushd groff-1.22.4 && \
    PAGE=letter ./configure --prefix=/usr && \
    make -j1 && \
    make install && \
    popd && \
    rm -rv groff-1.22.4

# 8.59. GRUB-2.06
RUN tar -xf grub-2.06.tar.xz && \
    pushd grub-2.06 && \
    ./configure --prefix=/usr          \
                --sysconfdir=/etc      \
                --disable-efiemu       \
                --disable-werror && \
    make && \
    make install && \
    mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions && \
    popd && \
    rm -rv grub-2.06

# 8.60. Gzip-1.11
RUN tar -xf gzip-1.11.tar.xz && \
    pushd gzip-1.11 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv gzip-1.11

# 8.61. IPRoute2-5.16.0
RUN tar -xf iproute2-5.16.0.tar.xz && \
    pushd iproute2-5.16.0 && \
    sed -i /ARPD/d Makefile && \
    rm -fv man/man8/arpd.8 && \
    make && \
    make SBINDIR=/usr/sbin install && \
    mkdir -pv             /usr/share/doc/iproute2-5.16.0 && \
    cp -v COPYING README* /usr/share/doc/iproute2-5.16.0 && \
    popd && \
    rm -rv iproute2-5.16.0

# 8.62. Kbd-2.4.0
RUN tar -xf kbd-2.4.0.tar.xz && \
    pushd kbd-2.4.0 && \
    patch -Np1 -i ../kbd-2.4.0-backspace-1.patch && \
    sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure && \
    sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in && \
    ./configure --prefix=/usr --disable-vlock && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    mkdir -pv           /usr/share/doc/kbd-2.4.0 && \
    cp -R -v docs/doc/* /usr/share/doc/kbd-2.4.0 && \
    popd && \
    rm -rv kbd-2.4.0

# 8.63. Libpipeline-1.5.5
RUN tar -xf libpipeline-1.5.5.tar.gz && \
    pushd libpipeline-1.5.5 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv libpipeline-1.5.5

# 8.64. Make-4.3
RUN tar -xf make-4.3.tar.gz && \
    pushd make-4.3 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv make-4.3

# 8.65. Patch-2.7.6
RUN tar -xf patch-2.7.6.tar.xz && \
    pushd patch-2.7.6 && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv patch-2.7.6

# 8.66. Tar-1.34
RUN tar -xf tar-1.34.tar.xz && \
    pushd tar-1.34 && \
    FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    make -C doc install-html docdir=/usr/share/doc/tar-1.34 && \
    popd && \
    rm -rv tar-1.34

# 8.67. Texinfo-6.8
RUN tar -xf texinfo-6.8.tar.xz&& \
    pushd texinfo-6.8 && \
    ./configure --prefix=/usr && \
    sed -e 's/__attribute_nonnull__/__nonnull/' \
        -i gnulib/lib/malloc/dynarray-skeleton.c && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    make TEXMF=/usr/share/texmf install-tex && \
    popd && \
    rm -rv texinfo-6.8

# 8.68. Vim-8.2.4383
RUN tar -xf vim-8.2.4383.tar.gz && \
    pushd vim-8.2.4383 && \
    echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h && \
    ./configure --prefix=/usr && \
    make && \
    if $ENABLE_TESTS; then \
        chown -Rv tester . && \
        su tester -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log && \
        grep -q "ALL DONE" vim-test.log; \
    fi && \
    make install && \
    ln -sv vim /usr/bin/vi && \
    for L in /usr/share/man/{,*/}man1/vim.1; do \
        ln -sv vim.1 $(dirname $L)/vi.1 || exit 1; \
    done && \
    ln -sv ../vim/vim82/doc /usr/share/doc/vim-8.2.4383 && \
    popd && \
    rm -rv vim-8.2.4383
ADD resources/vimrc /etc/vimrc

# 8.69. MarkupSafe-2.0.1
RUN tar -xf MarkupSafe-2.0.1.tar.gz && \
    pushd MarkupSafe-2.0.1 && \
    python3 setup.py build && \
    python3 setup.py install --optimize=1 && \
    popd && \
    rm -rv MarkupSafe-2.0.1

# 8.70. Jinja2-3.0.3
RUN tar -xf Jinja2-3.0.3.tar.gz && \
    pushd Jinja2-3.0.3 && \
    python3 setup.py install --optimize=1 && \
    popd && \
    rm -rv Jinja2-3.0.3

# 8.71. Systemd-250
RUN tar -xf systemd-250.tar.gz && \
    pushd systemd-250 && \
    patch -Np1 -i ../systemd-250-upstream_fixes-1.patch && \
    sed -i -e 's/GROUP="render"/GROUP="video"/' \
        -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in && \
    mkdir -p build && \
    cd build && \
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
          .. && \
    ninja && \
    ninja install && \
    tar -xf ../../systemd-man-pages-250.tar.xz --strip-components=1 -C /usr/share/man && \
    rm -rf /usr/lib/pam.d && \
    systemd-machine-id-setup && \
    systemctl preset-all && \
    popd && \
    rm -rv systemd-250

# 8.72. D-Bus-1.12.20
RUN tar -xf dbus-1.12.20.tar.gz && \
    pushd dbus-1.12.20 && \
    ./configure --prefix=/usr                        \
                --sysconfdir=/etc                    \
                --localstatedir=/var                 \
                --disable-static                     \
                --disable-doxygen-docs               \
                --disable-xml-docs                   \
                --docdir=/usr/share/doc/dbus-1.12.20 \
                --with-console-auth-dir=/run/console \
                --with-system-pid-file=/run/dbus/pid \
                --with-system-socket=/run/dbus/system_bus_socket && \
    make && \
    make install && \
    ln -sfv /etc/machine-id /var/lib/dbus && \
    popd && \
    rm -rv dbus-1.12.20

# 8.73. Man-DB-2.10.1
RUN tar -xf man-db-2.10.1.tar.xz && \
    pushd man-db-2.10.1 && \
    ./configure --prefix=/usr                         \
                --docdir=/usr/share/doc/man-db-2.10.1 \
                --sysconfdir=/etc                     \
                --disable-setuid                      \
                --enable-cache-owner=bin              \
                --with-browser=/usr/bin/lynx          \
                --with-vgrind=/usr/bin/vgrind         \
                --with-grap=/usr/bin/grap && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv man-db-2.10.1

# 8.74. Procps-ng-3.3.17
RUN tar -xf procps-ng-3.3.17.tar.xz && \
    pushd procps-3.3.17 && \
    ./configure --prefix=/usr                            \
                --docdir=/usr/share/doc/procps-ng-3.3.17 \
                --disable-static                         \
                --disable-kill                           \
                --with-systemd && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    popd && \
    rm -rv procps-3.3.17

# 8.75. Util-linux-2.37.4
RUN tar -xf util-linux-2.37.4.tar.xz && \
    pushd util-linux-2.37.4 && \
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
                --without-python && \
    make && \
    if $ENABLE_TESTS; then \
        chown -Rv tester . && \
        su tester -c "make -k check"; \
    fi && \
    make install && \
    popd && \
    rm -rv util-linux-2.37.4

# 8.76. E2fsprogs-1.46.5
RUN tar -xf e2fsprogs-1.46.5.tar.gz && \
    pushd e2fsprogs-1.46.5 && \
    mkdir -v build && \
    cd build && \
    ../configure --prefix=/usr           \
                 --sysconfdir=/etc       \
                 --enable-elf-shlibs     \
                 --disable-libblkid      \
                 --disable-libuuid       \
                 --disable-uuidd         \
                 --disable-fsck && \
    make && \
    if $ENABLE_TESTS; then make check; fi && \
    make install && \
    rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a && \
    gunzip -v /usr/share/info/libext2fs.info.gz && \
    install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info && \
    makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo && \
    install -v -m644 doc/com_err.info /usr/share/info && \
    install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info && \
    popd && \
    rm -rv e2fsprogs-1.46.5

# 8.78. Stripping
ADD resources/strip.sh /tmp/strip.sh
RUN bash /tmp/strip.sh

# 8.79. Cleaning Up
ARG LFS_TGT
RUN rm -rf /tmp/* && \
    find /usr/lib /usr/libexec -name \*.la -delete && \
    find /usr -depth -name $LFS_TGT\* | xargs rm -rf && \
    userdel -r tester

# 9.2. General Network Configuration
# NOTE: some parts skipped
ARG LFS_HOSTNAME
RUN echo "$LFS_HOSTNAME" > /etc/hostname && \
    echo "127.0.0.1 localhost" >> /etc/hosts && \
    echo "127.0.1.1 $LFS_HOSTNAME" >> /etc/hosts && \
    echo "::1       localhost ip6-localhost ip6-loopback" >> /etc/hosts && \
    echo "ff02::1   ip6-allnodes" >> /etc/hosts && \
    echo "ff02::2   ip6-allrouters" >> /etc/hosts

# 9.3 - 9.6 skipped

# 9.7. Configuring the System Locale
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 9.8. Creating the /etc/inputrc File
ADD resources/inputrc /etc/inputrc

# 9.9. Creating the /etc/shells File
RUN echo "/bin/sh" >> /etc/shells && \
    echo "/bin/bash" >> /etc/shells

# Skipping 10.2. Creating the /etc/fstab File

# 10.3. Linux-5.16.9
ADD resources/kernel_config /tmp/kernel_config
RUN tar -xf linux-5.16.9.tar.xz && \
    pushd linux-5.16.9 && \
    make mrproper && \
    make defconfig && \
    # Edit certain flags specified in resources/kernel_config
    scripts/kconfig/merge_config.sh .config /tmp/kernel_config && \
    make && \
    make modules_install && \
    cp -iv arch/x86/boot/bzImage /boot/vmlinuz-5.16.9 && \
    cp -iv System.map /boot/System.map-5.16.9 && \
    cp -iv .config /boot/config-5.16.9 && \
    # Install documentation
    install -d /usr/share/doc/linux-5.16.9 && \
    cp -r Documentation/* /usr/share/doc/linux-5.16.9 && \
    # 10.3.2. Configuring Linux Module Load Order
    install -v -m755 -d /etc/modprobe.d && \
    echo 'install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true' >> /etc/modprobe.d/usb.conf && \
    echo 'install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true' >> /etc/modprobe.d/usb.conf && \
    popd && \
    rm -rv linux-5.16.9

# Clean up source code
WORKDIR /
RUN rm -rv /sources

# Update shell prompt
ENV PS1='\u@\h:\w\$ '
