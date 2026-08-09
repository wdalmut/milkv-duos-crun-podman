#!/bin/sh

set -ex

export WORK=/home/work
export SDK=$WORK/duo-buildroot-sdk-v2
export BR_OUT=$SDK/buildroot/output/milkv-duos-musl-riscv64-sd
export PATH=$WORK/go/bin:$BR_OUT/host/bin:$PATH
export GOPATH=$WORK/podman-src
export GOROOT=$WORK/go
export CC=$(basename $(ls $BR_OUT/host/bin/*-gcc | head -1))
export PKG_CONFIG_LIBDIR=$BR_OUT/staging/usr/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=$BR_OUT/staging
export GOOS=linux GOARCH=riscv64 CGO_ENABLED=1 GOTOOLCHAIN=local

which $CC && ls $PKG_CONFIG_LIBDIR/libseccomp.pc && go version

cd $WORK/podman-src
go build -tags "containers_image_openpgp exclude_graphdriver_btrfs exclude_graphdriver_devicemapper seccomp cni" \
  -ldflags "-s -w" -o podman ./cmd/podman && file podman
