FROM ubuntu:18.04 AS build_image

RUN apt-get update
RUN apt-get install -y \
        curl \
        gzip \
        xz-utils
        # wget \
        # tar \
        # build-essential \
        # gawk \
        # bison \
        # python3

RUN curl --location https://github.com/Kitware/CMake/releases/download/v3.23.0/cmake-3.23.0-linux-aarch64.tar.gz \
        | tar --gzip --extract --strip-components=1 --file - --directory=/usr/local

RUN mkdir -p /var/sysroot
# Sourced from https://chromium.googlesource.com/chromium/src/+/66.0.3359.158/build/linux/sysroot_scripts/sysroots.json
RUN curl --location https://commondatastorage.googleapis.com/chrome-linux-sysroot/toolchain/3c248ba4290a5ad07085b7af07e6785bf1ae5b66/debian_stretch_arm64_sysroot.tar.xz \
        | tar --xz --extract --strip-components=1 --file - --directory=/var/sysroot

# RUN curl --location https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz \
#         | tar --xz --extract --strip-components=1 --file - --directory=/var/sysroot

# RUN ls -al /lib/libc*

# RUN apt-get install -y libc6
# RUN mkdir -p /tmp/glibc/build
# RUN mkdir -p /tmp/glibc/glibc-2.33-install
# WORKDIR /tmp/glibc
# RUN wget http://ftp.gnu.org/gnu/libc/glibc-2.33.tar.gz
# RUN tar -xzf glibc-2.33.tar.gz
        
# WORKDIR /tmp/glibc/build
# RUN /tmp/glibc/glibc-2.33/configure --prefix=/tmp/glibc/glibc-2.33-install
# RUN make -s
# RUN make -s install

# RUN echo "maybe1: $(ldd --version)"
# RUN ls -la /tmp/glibc/glibc-2.33/
# RUN /tmp/glibc/glibc-2.33-install/bin/ldd --version

# ENV PATH=/tmp/glibc/glibc-2.33-install/bin:$PATH
# RUN ls -la /tmp/glibc/glibc-2.33-install/lib/
# RUN ls -la /tmp/glibc/glibc-2.33-install/bin/
# RUN ls -la /tmp/glibc/glibc-2.33-install/
# # ENV LD_LIBRARY_PATH=/tmp/glibc/glibc-2.33-install/lib:$LD_LIBRARY_PATH
# ENV LIBRARY_PATH=/tmp/glibc/glibc-2.33-install/lib:$LIBRARY_PATH

# RUN echo "maybe2: $(ldd --version)"
RUN apt-get install -y \
        clang-10 \
        git \
        make \
        python3 \
        python3-distutils \
        tar

ENV CC="clang-10"
ENV CXX="clang++-10"

FROM build_image AS zlib_builder
WORKDIR /build/zlib
RUN curl --location https://www.zlib.net/fossils/zlib-1.2.12.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
RUN ./configure --prefix=/var/buildlibs/zlib --static
RUN make CFLAGS="-fPIC" --jobs $(nproc)
RUN make install

FROM build_image

WORKDIR /build/llvm-project
RUN curl --location https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.0/llvm-project-14.0.0.src.tar.xz \
        | tar --xz --extract --strip-components=1 --file -

COPY --from=zlib_builder /var/buildlibs/zlib /usr

WORKDIR /build/llvm-project/build
RUN cmake /build/llvm-project/llvm \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 \
        -DCMAKE_INSTALL_PREFIX=/build/llvm-project/build/clang+llvm-14.0.0-aarch_64-linux-gnu \
        -DCMAKE_SYSROOT=/var/sysroot \
        -DCOMPILER_RT_DEFAULT_TARGET_ONLY=1 \
        -DLLVM_ENABLE_LIBCXX=ON \
        -DLLVM_ENABLE_LIBXML2=OFF \
        -DLLVM_ENABLE_PIC=ON \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;cross-project-tests;libclc;lld;lldb;polly;pstl" \
        -DLLVM_ENABLE_RUNTIMES="compiler-rt;libc;libcxx;libcxxabi;libunwind;openmp" \
        -DLLVM_ENABLE_TERMINFO=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
        -DZLIB_LIBRARY_RELEASE=/usr/lib/libz.a
RUN make --jobs $(nproc)
RUN make install
RUN tar --create --file - clang+llvm-14.0.0-aarch_64-linux-gnu/ | XZ_DEFAULTS="--threads $(nproc)" xz -9e > clang+llvm-14.0.0-aarch_64-linux-gnu.tar.xz
