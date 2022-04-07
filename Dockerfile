FROM ubuntu:18.04 AS build_image

RUN apt-get update
RUN apt-get install -y \
        curl \
        gzip \
        xz-utils

RUN curl --location https://github.com/Kitware/CMake/releases/download/v3.23.0/cmake-3.23.0-linux-x86_64.tar.gz \
        | tar --gzip --extract --strip-components=1 --file - --directory=/usr/local

RUN mkdir -p /var/sysroot
RUN curl --location https://commondatastorage.googleapis.com/chrome-linux-sysroot/toolchain/2202c161310ffde63729f29d27fe7bb24a0bc540/debian_stretch_amd64_sysroot.tar.xz \
        | tar --xz --extract --strip-components=1 --file - --directory=/var/sysroot

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
RUN curl --location https://www.zlib.net/zlib-1.2.12.tar.gz \
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
        -DCMAKE_INSTALL_PREFIX=/build/llvm-project/build/clang+llvm-14.0.0-x86_64-linux-gnu \
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
RUN tar --create --file - clang+llvm-14.0.0-x86_64-linux-gnu/ | XZ_DEFAULTS="--threads $(nproc)" xz -9e > clang+llvm-14.0.0-x86_64-linux-gnu.tar.xz
