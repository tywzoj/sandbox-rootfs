#!/bin/bash -e

GCC_VERSION="14"
LLVM_VERSION="19"
OPENJDK_VERSION="21"
PYTHON_VERSION="3.13"
GOLANG_VERSION="1.23"

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
echo "Installing dependencies..."
apt update
apt dist-upgrade -y
apt install -y gnupg ca-certificates curl wget locales unzip zip git software-properties-common
echo "Dependencies installed."

echo "Adding repositories..."
# LLVM
wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc
echo "Types: deb
Architectures: amd64 arm64
Signed-By: /etc/apt/trusted.gpg.d/apt.llvm.org.asc
URIs: https://apt.llvm.org/$UBUNTU_CODENAME/
Suites: llvm-toolchain-$UBUNTU_CODENAME-$LLVM_VERSION
Components: main" > /etc/apt/sources.list.d/llvm.sources
# Python3
add-apt-repository ppa:deadsnakes/ppa
# Golang
add-apt-repository ppa:longsleep/golang-backports
apt update
echo "Repositories added."

# Install some language support via APT
echo "Installing GCC, LLVM, OpenJDK, Python, and Go..."
apt install -y g++-$GCC_VERSION-multilib \
               gcc-$GCC_VERSION-multilib \
               clang-$LLVM_VERSION \
               libc++-$LLVM_VERSION-dev \
               libc++abi-$LLVM_VERSION-dev \
               openjdk-$OPENJDK_VERSION-jdk \
               python$PYTHON_VERSION \
               golang-$GOLANG_VERSION-go
echo "GCC, LLVM, OpenJDK, Python, and Go installed."

# Install Rust via Rustup
echo "Installing Rust..."
su sandbox -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
echo "Rust installed."

# Install Kotlin via SDKMAN!
echo "Installing Kotlin..."
su sandbox -c "curl -s https://get.sdkman.io | bash"
su sandbox -s /bin/bash -c "source ~/.sdkman/bin/sdkman-init.sh && sdk install kotlin"
echo "Kotlin installed."

# Create symlinks for compilers and interpreters with non-common names and locations
echo "Creating symlinks..."
ln -s /usr/bin/g++-$GCC_VERSION /usr/local/bin/g++
ln -s /usr/bin/gcc-$GCC_VERSION /usr/local/bin/gcc
ln -s /usr/bin/clang-$LLVM_VERSION /usr/local/bin/clang
ln -s /usr/bin/clang++-$LLVM_VERSION /usr/local/bin/clang++
ln -s /usr/lib/go-$GOLANG_VERSION/bin/go /usr/local/bin/go
ln -s /usr/lib/go-$GOLANG_VERSION/bin/gofmt /usr/local/bin/gofmt
ln -s /sandbox/.cargo/bin/rustc /usr/local/bin/rustc
ln -s /sandbox/.sdkman/candidates/kotlin/current/bin/kotlin /usr/local/bin/kotlin
ln -s /sandbox/.sdkman/candidates/kotlin/current/bin/kotlinc /usr/local/bin/kotlinc
echo "Symlinks created."

# Install testlib
echo "Installing testlib..."
git clone https://github.com/tywzoj/testlib.git /tmp/testlib
cp /tmp/testlib/testlib.h /usr/include/
echo "Testlib installed."

# Clean the APT cache
apt clean