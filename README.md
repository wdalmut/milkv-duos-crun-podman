# NodeRED on MilkV Duo S (RISC-V) with Podman and Crun

The RISC-V architecture is naturally interesting and with this project we want
to build a container based platform also considering the limited amount of 
resources that we had on the Milk-V Duo S board.

Thanks to the containerization is simplier to build a final container with 
`docker buildx` and use the docker registry to run an application on the board
adding packages leveraging the `Alpine` base image.

In this project we will run `NodeRED` as main application, just check the folder
`nodered-app`.

## Start build container (PC)

```sh
docker run -u 1000:1000 -itd --name duodocker \
  -v "$(pwd)":/home/work milkvtech/milkv-duo:latest /bin/bash
```

And then create the `.cache` folder

```sh
docker exec -it -uroot duodocker mkdir -p /.cache
docker exec -it -uroot duodocker chown -R 1000:1000 /.cache
```

## Enter in the container (PC)

```sh
docker exec -it duodocker /bin/bash
```

the working directory is in the `/home/work` folder but compiling is in the `duo-buildroot-sd-v2`

## Working in the container

```sh
09:02 $ docker exec -it duodocker bash
groups: cannot find name for group ID 1000
I have no name!@9db9201faefe:/$ id
uid=1000 gid=1000 groups=1000
I have no name!@9db9201faefe:/$ 
```

## Create the first build (in the container)

Before cross-compiling `podman` we have to create the first build

```sh
I have no name!@9db9201faefe:/home/work/duo-buildroot-sdk-v2$ ./build.sh milkv-duos-musl-riscv64-sd
Target Top Config: /home/work/duo-buildroot-sdk-v2/build/boards/cv181x/sg2000_milkv_duos_musl_riscv64_sd/sg2000_milkv_duos_musl_riscv64_sd_defconfig
Target Board: milkv-duos-musl-riscv64-sd
Target Board Storage: sd
Target Board Config: /home/work/duo-buildroot-sdk-v2/device/target/boardconfig.sh
Target Board Type: duos
Target Image Config: /home/work/duo-buildroot-sdk-v2/device/target/genimage.cfg
Build tdl-sdk: 1
Output dir: /home/work/duo-buildroot-sdk-v2/install/soc_sg2000_milkv_duos_musl_riscv64_sd

... keep going for the long run

INFO: ext4(rootfs.ext4): cmd: "e2fsck -pvfD '/home/work/duo-buildroot-sdk-v2/install/soc_sg2000_milkv_duos_musl_riscv64_sd/rootfs.ext4'" (stderr):
INFO: hdimage(milkv-duos-musl-riscv64-sd.img): adding primary partition 'boot' (in MBR) from 'boot.vfat' ...
INFO: hdimage(milkv-duos-musl-riscv64-sd.img): adding primary partition 'logo' (in MBR) from 'logo.jpg' ...
INFO: hdimage(milkv-duos-musl-riscv64-sd.img): adding primary partition 'rootfs' (in MBR) from 'rootfs.ext4' ...
INFO: hdimage(milkv-duos-musl-riscv64-sd.img): adding primary partition '[MBR]' ...
INFO: hdimage(milkv-duos-musl-riscv64-sd.img): writing MBR
INFO: cmd: "rm -rf "/home/work/duo-buildroot-sdk-v2/install/soc_sg2000_milkv_duos_musl_riscv64_sd/tmp/"" (stderr):
gnimage for milkv-duos-musl-riscv64-sd success!
/home/work/duo-buildroot-sdk-v2/build
/home/work/duo-buildroot-sdk-v2
Create SD image successful: out/milkv-duos-musl-riscv64-sd_2026-0809-1628.img
```

This is the first stable build that we can use to test out the board with original sourcecode and
also create the `riscv64-unknown-linux-musl-gcc` compiler that is mandatory to build `podman` for
the RISC-V architecture.

Just flash the sdcard from your PC

**PAY ATTENTION ON THOSE COMMANDS THAT DESTROY THE CONTENTS AND PARTITIONS OPF THE DISK
SO IDENTIFY THE /dev/sdaX OF THE SDCARD!**

```sh
sudo umount /dev/sdaX
sudo dd if=out/milkv-duos-musl-riscv64-sd_2026-0809-1628.img of=/dev/sda bs=4M status=progress conv=fsync
sudo eject /dev/sda
```

Now plug the sdcard in the Milk-V Duo S and check that everything works fine and then move on with the
containerized setup.


## Working the CRUN and Podman

in order to build `podman` we need extra packages like `libseccomp` so we have to select packages and
rebuild the project with extra dependencies

## Prepare the working dir (in the container)

Override the buildroot configuration

```sh
cd /home/work
cp -rp ./buildroot/* duo-buildroot-sdk-v2
```

## Rebuild everything (in the container)

```sh
I have no name!@9db9201faefe:/home/work/duo-buildroot-sdk-v2$ ./build.sh milkv-duos-musl-riscv64-sd
```
This build will take less time than the previous one but it will go for 15 or more minutes and
in the final steps of the build you will se the `libseccomp` and `crun` infos

```sh
...
/home/work/duo-buildroot-sdk-v2/buildroot/utils/brmake -j8 -C /home/work/duo-buildroot-sdk-v2/buildroot
2026-08-09T16:46:15 >>> argp-standalone 1.4.1 Downloading
2026-08-09T16:46:15 >>> host-gperf 3.1 Downloading
2026-08-09T16:46:15 >>> libseccomp 2.5.5 Downloading
2026-08-09T16:46:15 Resolving ftpmirror.gnu.org (ftpmirror.gnu.org)... >>> less 661 Downloading
2026-08-09T16:46:15 >>> vim 9.1.0145 Downloading
2026-08-09T16:46:15 >>> conmon 2.1.8 Downloading
2026-08-09T16:46:15 >>> yajl 2.1.0 Downloading
2026-08-09T16:46:15 >>> crun 1.18.2 Downloading
2026-08-09T16:46:16 >>> nano 8.2 Downloading
2026-08-09T16:46:16 50K .......... ..........>>> argp-standalone 1.4.1 Extracting
2026-08-09T16:46:16 ..... ..Connecting to www.nano-editor.org (www.nano-editor.org)|172.236.11.40|:443... ........>>> libseccomp 2.5.5 Extracting
2026-08-09T16:46:16 ...... ............>>> yajl 2.1.0 Extracting
2026-08-09T16:46:16 150K .......... ........>>> argp-standalone 1.4.1 Patching
2026-08-09T16:46:16 250K ..>>> argp-standalone 1.4.1 Updating config.sub and config.guess
2026-08-09T16:46:17 >>> conmon 2.1.8 Extracting
2026-08-09T16:46:17 ... .......>>> argp-standalone 1.4.1 Configuring
2026-08-09T16:46:17 >>> libseccomp 2.5.5 Patching
2026-08-09T16:46:17 ........ ........>>> libseccomp 2.5.5 Updating config.sub and config.guess
2026-08-09T16:46:17 >>> libseccomp 2.5.5 Patching libtool
2026-08-09T16:46:17 >>> yajl 2.1.0 Patching
2026-08-09T16:46:17 >>> conmon 2.1.8 Patching
2026-08-09T16:46:17 >>> yajl 2.1.0 Configuring
2026-08-09T16:46:17 300K .......... ..>>> less 661 Extracting
2026-08-09T16:46:17 950K ..>>> less 661 Patching
2026-08-09T16:46:17 ........>>> less 661 Updating config.sub and config.guess
2026-08-09T16:46:17 .......... ......>>> less 661 Patching libtool
2026-08-09T16:46:17 >>> argp-standalone 1.4.1 Autoreconfiguring
2026-08-09T16:46:17 >>> less 661 Configuring
2026-08-09T16:46:18 .. .......... ......>>> nano 8.2 Extracting
2026-08-09T16:46:18 ...... .>>> yajl 2.1.0 Building
2026-08-09T16:46:18 900K .......... .......... .......... ...>>> crun 1.18.2 Extracting
2026-08-09T16:46:18 >>> nano 8.2 Patching
2026-08-09T16:46:18 >>> crun 1.18.2 Patching
2026-08-09T16:46:18 >>> nano 8.2 Updating config.sub and config.guess
2026-08-09T16:46:18 1450K .......... .......... .......... .......... ......>>> nano 8.2 Patching libtool
2026-08-09T16:46:18 >>> crun 1.18.2 Updating config.sub and config.guess
2026-08-09T16:46:19 1700K .......... .......... .......... ..>>> nano 8.2 Configuring
2026-08-09T16:46:19 3750K .......... ..........>>> yajl 2.1.0 Installing to staging directory
2026-08-09T16:46:19 .. .......... ..>>> yajl 2.1.0 Fixing libtool files
2026-08-09T16:46:19 4100K .......... .......... .........>>> yajl 2.1.0 Installing to target
2026-08-09T16:46:21 8050K .......... .......... ....>>> argp-standalone 1.4.1 Patching libtool
2026-08-09T16:46:22 checking for malloc.h... checking whether the compiler supports GNU C... (cached) >>> vim 9.1.0145 Extracting
2026-08-09T16:46:23 checking for fsync... >>> vim 9.1.0145 Patching
2026-08-09T16:46:23 checking for mbsinit... >>> vim 9.1.0145 Updating config.sub and config.guess
2026-08-09T16:46:23 checking for strndup... >>> vim 9.1.0145 Patching libtool
2026-08-09T16:46:23 checking for nanosleep... >>> vim 9.1.0145 Configuring
2026-08-09T16:46:25 checking for usleep... >>> argp-standalone 1.4.1 Building
2026-08-09T16:46:26 >>> argp-standalone 1.4.1 Installing to staging directory
2026-08-09T16:46:26 >>> argp-standalone 1.4.1 Fixing libtool files
2026-08-09T16:46:26 >>> argp-standalone 1.4.1 Installing to target
2026-08-09T16:46:26 checking for vasnprintf... >>> host-gperf 3.1 Extracting
2026-08-09T16:46:27 >>> host-gperf 3.1 Patching
2026-08-09T16:46:27 >>> host-gperf 3.1 Updating config.sub and config.guess
2026-08-09T16:46:27 >>> host-gperf 3.1 Patching libtool
2026-08-09T16:46:27 checking for wcwidth... >>> host-gperf 3.1 Configuring
2026-08-09T16:46:27 >>> less 661 Building
2026-08-09T16:46:29 checking whether we are using the GNU C compiler... >>> less 661 Installing to target
2026-08-09T16:46:31 >>> host-gperf 3.1 Building
2026-08-09T16:46:32 >>> host-gperf 3.1 Installing to host directory
2026-08-09T16:46:32 checking whether long double and double are the same... >>> libseccomp 2.5.5 Configuring
2026-08-09T16:46:36 checking for struct sched_param... >>> libseccomp 2.5.5 Building
2026-08-09T16:46:38 >>> libseccomp 2.5.5 Installing to staging directory
2026-08-09T16:46:38 >>> libseccomp 2.5.5 Fixing libtool files
2026-08-09T16:46:38 checking for vsnprintf... >>> libseccomp 2.5.5 Installing to target
2026-08-09T16:46:38 >>> conmon 2.1.8 Configuring
2026-08-09T16:46:38 >>> crun 1.18.2 Configuring
2026-08-09T16:46:40 checking whether float.h conforms to ISO C23... >>> crun 1.18.2 Autoreconfiguring
2026-08-09T16:46:40 checking for sysconf... >>> conmon 2.1.8 Building
2026-08-09T16:46:42 checking whether isnan(float) can be used without linking with libm... >>> conmon 2.1.8 Installing to target
2026-08-09T16:46:43 checking for PTHREAD_MUTEX_ROBUST... >>> vim 9.1.0145 Building
2026-08-09T16:46:55 >>> nano 8.2 Building
2026-08-09T16:47:08 >>> crun 1.18.2 Patching libtool
2026-08-09T16:47:17 checking for criu >= 3.15... >>> nano 8.2 Installing to target
2026-08-09T16:47:18 >>> vim 9.1.0145 Installing to target
2026-08-09T16:47:25 >>> crun 1.18.2 Building
2026-08-09T16:47:40 >>> crun 1.18.2 Installing to target
2026-08-09T16:47:40 >>>   Finalizing host directory
2026-08-09T16:47:47 >>>   Finalizing target directory
2026-08-09T16:47:51 >>>   Sanitizing RPATH in target tree
2026-08-09T16:47:52 >>>   Copying overlay board/milkv/milkv-duos-musl-riscv64-sd/overlay
2026-08-09T16:47:53 >>>   Copying overlay /home/work/br2-containers/overlay
2026-08-09T16:47:53 >>>   Generating root filesystems common tables
2026-08-09T16:47:53 >>>   Generating filesystem image rootfs.ext2
2026-08-09T16:47:53 >>>   Generating filesystem image rootfs.tar
...
```

Now we can move on with the build of the `podman` executable 

download Golang

```sh
sh scripts/download-go.sh
```

### Build `podman` executable (in the container)

```sh
I have no name!@9db9201faefe:/$ cd /home/work/
I have no name!@9db9201faefe:/home/work$ bash scripts/podman-env.sh 
```

The build process should end with

```sh
podman: ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-riscv64.so.1, BuildID[sha1]=59c7ff852ffa4d4395b32a4dde8600f2f8d391a9, stripped
```

but we can check that the `podman` executable is there

```sh
I have no name!@9db9201faefe:/home/work$ ls -las podman-src/podman
41072 -rwxr-xr-x 1 1000 1000 42056424 Aug  9 16:53 podman-src/podman
I have no name!@9db9201faefe:/home/work$ file podman-src/podman
podman-src/podman: ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-riscv64.so.1, BuildID[sha1]=59c7ff852ffa4d4395b32a4dde8600f2f8d391a9, stripped
```

## Prepare the final complete build (in the container)

Now with the script `board-env.sh` we will prepare the final filesystem and 
we will copy the binary from `podman` in the right folder on the target.

```sh
I have no name!@9db9201faefe:/$ cd /home/work/
I have no name!@9db9201faefe:/home/work$ bash scripts/board-env.sh 
cp: cannot stat 'containers-backup/*': No such file or directory
/home/work/br2-containers/overlay/etc/containers/containers.conf
/home/work/br2-containers/overlay/etc/containers/policy.json
/home/work/br2-containers/overlay/etc/containers/storage.conf
/home/work/br2-containers/overlay/etc/containers/registries.conf
/home/work/br2-containers/overlay/etc/init.d/S40containers
/home/work/br2-containers/overlay/usr/local/bin/.gitentry
/home/work/br2-containers/overlay/usr/local/bin/podman
```

## Rebuild the final image (in the container)

If you want you can skip a final rebuild and create the folder's structure that you find in 
the `br2-containers` and coping the binary from `podman` in the `/usr/bin` folder in the
target. 

Otherwise just build the final image with all dependencies and finally create your latest
sdcard and test everything out directly in a simplier way.

```sh
I have no name!@9db9201faefe:/$ cd /home/work/duo-buildroot-sdk-v2/
I have no name!@9db9201faefe:/home/work/duo-buildroot-sdk-v2$ ./build.sh milkv-duos-musl-riscv64-sd
```

The command will keep running for several minutes again but at the end you will have a 
target image with containerization working.

## Test out a simple Alpine container (on the milk-v board)

Just spin up a container

```sh
podman run --rm --network=host docker.io/riscv64/alpine echo ok
```

## Start NodeRED (on the milk-v board)

Just start it up

```sh
podman run -d --network=host wdalmut/nodered
```

The process will take a minute to startup so check the container's logs and then
with your browser go directly on `http://192.168.42.1:1880`.

## Build your own images and copying in the Milk-v (on the host)

If you want to build your own containers and copying directly on the board
without passing through the register you can build RISC-V images.

Only the first time start the buildx toolchain

```sh
docker run --privileged --rm tonistiigi/binfmt --install riscv64
docker buildx create --name rvbuilder --use   # driver docker-container
```

then just build your images leveraging your own `Dockerfile`

```sh
docker buildx build --platform linux/riscv64 \
  -t nodered-rv:1.0 \
  --output type=oci,dest=nodered-rv.tar .
```

Now you can copy the tar file on the Milk-V board (or push previusly to the Docker register)

```sh
scp -O nodered-rv.tar root@192.168.42.2:/mnt/sd/
```

Then on the Milk-V 

```sh
podman load -i /mnt/sd/nodered-rv.tar
```

Then check your images


```sh
podman images
```

You should see your brand new image and then you can use it!

```sh
podman run -it --rm  <your-image-name> 
```

## Adding extra packages (in the container)

```sh
cd buildroot/output/milkv-duos-musl-riscv64-sd/
make menuconfig          # '/' per cercare (es. "package_vim")
make savedefconfig       # scrive nel defconfig sorgente
```
