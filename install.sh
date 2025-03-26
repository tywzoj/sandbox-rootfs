#!/bin/bash -e

GCC_VERSION="14"
LLVM_VERSION="20"
OPENJDK_VERSION="21"
PYTHON_VERSION="3.13"
GOLANG_VERSION="1.23"
KOTLIN_VERSION="2.1.20"

UBUNTU_CODENAME="$(source /etc/os-release && echo "$UBUNTU_CODENAME")"
UBUNTU_VERSION="$(source /etc/os-release && echo "$VERSION_ID")"

# Fix PATH environment variable
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Set Locale
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
export LC_ALL=en_US.UTF-8
echo 'LC_ALL=en_US.UTF-8' > /etc/default/locale

# Create sandbox user and directories
useradd -r sandbox -d /sandbox -m
mkdir -p /sandbox/{binary,source,working}

# Add ubuntu-updates source
ORIGINAL_SOURCE=$(head -n 1 /etc/apt/sources.list)
sed "s/$UBUNTU_CODENAME/$UBUNTU_CODENAME-updates/" <<< "$ORIGINAL_SOURCE" >> /etc/apt/sources.list

# Install dependencies
apt-get update
apt-get dist-upgrade -y
apt-get install -y gnupg ca-certificates curl wget locales unzip zip git

# Key: LLVM repo
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
# Key: Python3 repo
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys F23C5A6CF475977595C89F51BA6932366A755776
# Key: Go repo
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 876B22BA887CA91614B5323FC631127F87FA12D1

# Add sources
echo "deb https://apt.llvm.org/$UBUNTU_CODENAME/ llvm-toolchain-$UBUNTU_CODENAME-$LLVM_VERSION main" > /etc/apt/sources.list.d/llvm.list
echo "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu $UBUNTU_CODENAME main" > /etc/apt/sources.list.d/python.list
echo "deb https://ppa.launchpadcontent.net/longsleep/golang-backports/ubuntu $UBUNTU_CODENAME main" >  /etc/apt/sources.list.d/go.list

# Install some language support via APT
apt-get update
apt-get install -y g++-$GCC_VERSION-multilib \
                   gcc-$GCC_VERSION-multilib \
                   clang-$LLVM_VERSION \
                   libc++-$LLVM_VERSION-dev \
                   libc++abi-$LLVM_VERSION-dev \
                   openjdk-$OPENJDK_VERSION-jdk \
                   python$PYTHON_VERSION \
                   golang-$GOLANG_VERSION 

# Install Rust via Rustup
su sandbox -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"

# Install Kotlin
KOTLIN_URL="https://github.com/JetBrains/kotlin/releases/download/v$KOTLIN_VERSION/kotlin-compiler-$KOTLIN_VERSION.zip"
wget -O - "$KOTLIN_URL" | unzip -d /opt -
mv /opt/kotlin* /opt/kotlin

# Install Swift
SWIFT_URL_QUOTED="$(curl https://www.swift.org/download/ --compressed | grep -P "\"([^\"]+ubuntu$UBUNTU_VERSION.tar.gz)\"" -o | head -n 1)"
SWIFT_URL="$(eval "echo $SWIFT_URL_QUOTED")"
wget -O - "$SWIFT_URL" | tar -xzf - -C /opt
mv /opt/swift* /opt/swift

# Create symlinks for compilers and interpreters with non-common names and locations
ln -s /usr/bin/g++-$GCC_VERSION /usr/local/bin/g++
ln -s /usr/bin/gcc-$GCC_VERSION /usr/local/bin/gcc
ln -s /usr/bin/clang-$LLVM_VERSION /usr/local/bin/clang
ln -s /usr/bin/clang++-$LLVM_VERSION /usr/local/bin/clang++
ln -s /sandbox/.cargo/bin/rustc /usr/local/bin/rustc
ln -s /opt/kotlin/bin/kotlin /usr/local/bin/kotlin
ln -s /opt/kotlin/bin/kotlinc /usr/local/bin/kotlinc
ln -s /opt/swift/usr/bin/swiftc /usr/local/bin/swiftc

# Clean the APT cache
apt-get clean

# Install testlib
git clone https://github.com/tywzoj/testlib.git /tmp/testlib
cp /tmp/testlib/testlib.h /usr/include/
