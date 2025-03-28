# Sandbox RootFS

This is a fork of [lyrio-dev/sandbox-rootfs](https://github.com/lyrio-dev/sandbox-rootfs).

Thanks to [lyrio-dev](https://github.com/lyrio-dev) and [Menci](https://github.com/menci).

## Description

This is the sandbox's rootfs used by [lyrio-judge](https://github.com/lyrio-dev/judge). It's based on Ubuntu 24.04 and contains compilers (and interpreters) below:

* GCC 14
* Clang 19 (from [LLVM](https://apt.llvm.org/))
* OpenJDK 21
* Kotlin (from [SDKMAN!](https://kotlinlang.org/docs/tutorials/command-line.html))
* Python 3.13 (from [PPA](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa))
* Rust (from [Rustup](https://rustup.rs/))
* Go 1.23 (from [PPA](https://launchpad.net/~longsleep/+archive/ubuntu/golang-backports))

Each compiler (or interpreter) is available in `$PATH`. It also contains [`testlib.h`](https://github.com/MikeMirzayanov/testlib) in `/usr/include`.

You can download it from [release](https://github.com/tywzoj/sandbox-rootfs/releases) or bootstrap by yourself.

## Bootstrapping
You'll need:

* A Linux box with root privilege
* `arch-chroot` (usually in the package `arch-install-scripts`)
* `debootstrap` (some old version of Debian's `debootstrap` couldn't bootstrap Ubuntu 24.04)

First, clone this repo:

```bash
git clone https://github.com/tywzoj/sandbox-rootfs.git
cd sandbox-rootfs
```

Set the path to bootstrap rootfs. If there're anything inside it, it'll be `rm -rf`-ed. If the path doesn't exist, it'll be `mkdir -p`-ed.

```bash
export ROOTFS_PATH=/rootfs
```

If you're root, just run the `bootstrap.sh` script:

```bash
./bootstrap.sh
```

Or if you use `sudo`, remember to preserve the `ROOTFS_PATH` environment variable with `-E` option:

```bash
sudo -E ./bootstrap.sh
```
