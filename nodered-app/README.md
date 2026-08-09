# Build NodeRED container for RISCV

## Create buildx structure in Docker (PC) - once

```sh
docker run --privileged --rm tonistiigi/binfmt --install riscv64
docker buildx create --name rvbuilder --use   # driver docker-container
```

## Build the image (PC)

```sh
docker buildx build --platform linux/riscv64   -t wdalmut/nodered --push  --output type=docker,dest=node-rv.tar .
```

## Copy the app image on the board (PC)

```sh
scp -O ../node-rv.tar root@192.168.42.1:/root/
```

## Load the image (Baord)

```sh
podman load -i nodered-rv.tar
```