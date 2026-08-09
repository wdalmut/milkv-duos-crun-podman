#!/bin/sh

DIR="$(cd "$(dirname "$0")" && pwd)"

wget -O /tmp/golang.tar.gz https://go.dev/dl/go1.25.0.linux-amd64.tar.gz
tar -C $DIR -xpf /tmp/golang.tar.gz