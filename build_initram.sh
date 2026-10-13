#!/bin/sh
set -e
rm -rf ~/initramfs ~/initramfs.cpio.gz
mkdir -p ~/initramfs/bin && cd ~/initramfs
cp /bin/busybox bin/
for c in sh mount ls cat; do ln -s busybox bin/$c; done
printf '#!/bin/sh\nmount -t proc proc /proc\nmount -t sysfs sys /sys\nexec /bin/sh\n' > init
chmod +x init && mkdir proc sys
find . | cpio -o -H newc | gzip > ../initramfs.cpio.gz
