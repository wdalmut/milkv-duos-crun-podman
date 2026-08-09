O=/home/work/br2-containers/overlay
mkdir -p $O/etc/containers $O/etc/init.d $O/usr/local/bin
cp containers-backup/* $O/etc/containers/
cp /home/work/podman-src/podman $O/usr/local/bin/ && chmod 755 $O/usr/local/bin/podman

cat > $O/etc/init.d/S40containers << 'EOF'
#!/bin/sh
case "$1" in
  start)
    mount -t cgroup2 none /sys/fs/cgroup 2>/dev/null
    mkdir -p /var/lib/containers/storage /run/containers/storage
    ;;
esac
EOF
chmod 755 $O/etc/init.d/S40containers

find $O -type f
