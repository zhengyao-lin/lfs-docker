# lfs-docker

Build [Linux From Scratch 11.1-systemd](https://www.linuxfromscratch.org/lfs/view/11.1-systemd) using Docker.

## Usage

First, [install Docker](https://docs.docker.com/get-docker/) on your system.
A Docker version >= 18.09 is required since some BuildKit features are used in this Dockerfile.

Now change the working directory to this repo, and then simply run
```
DOCKER_BUILDKIT=1 docker build -o . .
```
If the build succeeds, an ISO image `lfs.iso` will be produced in the current directory

On a laptop with a 4-core (8-thread) low-power Intel CPU and 16 GB of memory,
the entire build took roughly 2 hours and used about 15 GB of disk space.

## How does the Dockerfile work

This Dockerfile is self-contained and does not use any files from the context.

One crucial feature used in this Dockerfile is the [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/), which essentially allows one
to sequentially specify multiple images in a Dockerfile, with each image potentially referencing files
from previous images.

Using multi-stage build, our Dockerfile is splitted into the following stages,
each corresponding to a different part of the LFS manual:
```
# Stage 1: prepare the host
# Sections 2 - 7.3 are done in this stage
FROM alpine AS host
...

# Stage 2: chroot into the toolchain and build more packages
# Sections 7.4 - 7.14 are done in this stage
FROM scratch AS toolchain
COPY --from=host ${LFS} /
...

# Stage 3: build the packages in the final system
# Sections 8 - 10 are done in this stage
FROM toolchain AS system
...

# Stage 4: produce a bootable ISO image
FROM alpine:3.16 AS iso-builder
...
```

Notably, the stage 2 delegates the job of chroot (used in LFS manual section 7.4) to Docker,
so we do not need any `--privileged` flag to perform this action.

## More details on making a bootable ISO image

For booting the ISO image, I decided to use GRUB 2 with the
goal to support booting in both legacy BIOS and UEFI modes.

The final file structure of the ISO image looks like this:
```
boot/
  - grub/
      - i386-pc/
          - eltorito.img # for BIOS booting
      - x86_64-efi/
          - efi.img      # for UEFI booting
      - grub.cfg         # GRUB configuration
  - vmlinuz              # Linux kernel
  - initramfs.cpio.gz    # initramfs
system.squashfs          # The actual LFS system packaged using squashfs
```

The boot process of the ISO image works in the following way.

When booting in BIOS mode, `eltorito.img` will be used;
when booting in UEFI mode, `efi.img` will be used (as the EFI System Partition or ESP).
Both boot images are produced using `grub-mkimage` and a few different commands (see `Dockerfile` for details),
and they both contain a copy of the GRUB bootloader and will try to load the GRUB configuration `boot/grub/grub.cfg`.

The GRUB configuration `boot/grub/grub.cfg` specifies how the kernel should be booted with an initial,
mini root file system `initramfs.cpio.gz`.
The `/init` script in this mini file system will then try to find the actual root image `system.squashfs`
and switch the root to it (using `switch_root`).

Finally, after `switch_root`, the actual systemd init script will be executed and the LFS system will start loading.

Some useful resources:
- UEFI support in kernel: https://www.linuxfromscratch.org/blfs/view/11.1-systemd/postlfs/grub-setup.html#uefi-kernel
- Making initramfs: https://lyngvaer.no/log/create-linux-initramfs
- Making a UEFI bootable ISO image using GRUB: https://github.com/syzdek/efibootiso
- Making a UEFI + BIOS bootable ISO image using GRUB: https://opendev.org/airship/images/src/commit/5e55597fbcebc9e16006e06b7514b21b9882dc8d/debian-isogen/files/functions.sh
- GRUB modules: https://www.linux.org/threads/understanding-the-various-grub-modules.11142/
- Syslinux/isolinux usage: https://wiki.syslinux.org/wiki/index.php?title=ISOLINUX
- Making a "hybrid" image for syslinux: https://wiki.syslinux.org/wiki/index.php?title=Isohybrid#UEFI

## Related work

- https://github.com/reinterpretcat/lfs
- https://github.com/0rland/lfs-docker
- https://github.com/pbret/lfs-docker
- https://github.com/EvilFreelancer/docker-lfs-build
