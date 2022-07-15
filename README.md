# lfs-docker

Build LFS using Docker. Based on [LFS 11.1-systemd](https://www.linuxfromscratch.org/lfs/view/11.1-systemd).

# Usage

First, install Docker on your system. Then cd into this repo.

## With Docker >= 18.09
```
DOCKER_BUILDKIT=1 docker build -o . .
```
An ISO image `lfs.iso` will be produced in the current directory

## With Docker < 18.09
```
docker build -t lfs .
```

The final Docker image `lfs` contains a single bootable ISO image `/lfs.iso`.
You can extract it by running the image in a container and using `docker cp`.

On a laptop with 8th-gen low-power Intel CPUs and 16 GB of memory,
the entire build took 124 min to finish and used 13.3 GB of disk space.

# Related work

- https://github.com/reinterpretcat/lfs
- https://github.com/0rland/lfs-docker
- https://github.com/pbret/lfs-docker
