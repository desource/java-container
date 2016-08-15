#!/usr/bin/env sh
set -eux

JAVA_VERSION=8.13.0.5-jdk8.0.72-linux_x64
JAVA_MD5SUM=50b95832b1d072afc178d820e5680687

SRC=$PWD/src
OUT=$PWD/out
ROOTFS=$PWD/rootfs
GLIBC=$PWD/glibc

mkdir -p $ROOTFS/etc $ROOTFS/usr $ROOTFS/lib64 $OUT

curl -O \
     -e http://www.azul.com/downloads/zulu/zulu-linux/ \
     -L http://cdn.azul.com/zulu/bin/zulu$JAVA_VERSION.tar.gz
echo "$JAVA_MD5SUM  zulu$JAVA_VERSION.tar.gz" | md5sum -c

tar xf zulu$JAVA_VERSION.tar.gz
mv zulu$JAVA_VERSION/jre $ROOTFS/usr/
rm -rf $ROOTFS/usr/jre/bin/{jjs,keytool,orbd,pack200,policytool,rmid,rmiregistry,servertool,tnameserv,unpack200} \
   $ROOTFS/usr/jre/lib/ext/nashorn.jar

cp \
    $GLIBC/libc.so.* \
    $GLIBC/dlfcn/libdl.so.* \
    $GLIBC/nptl/libpthread.so.* \
    $GLIBC/elf/ld-linux-x86-64.so.* \
    $GLIBC/math/libm.so* \
    $GLIBC/nss/libnss_files.so.* \
    $GLIBC/resolv/libnss_dns.so.* \
    $ROOTFS/lib64

ln -s /lib64 $ROOTFS/lib 

echo 'hosts: files mdns4_minimal dns [NOTFOUND=return] mdns4' >> $ROOTFS/etc/nsswitch.conf

cat <<EOF > $ROOTFS/etc/passwd
root:x:0:0:root:/:/dev/null
nobody:x:65534:65534:nogroup:/:/dev/null
EOF

cat <<EOF > $ROOTFS/etc/group
root:x:0:
nogroup:x:65534:
EOF

echo 'networkaddress.cache.ttl=10' >> $ROOTFS/usr/jre/lib/security/java.security
cp /etc/pki/ca-trust/extracted/java/cacerts $ROOTFS/usr/jre/lib/security/cacerts

cd $ROOTFS
tar -cf $OUT/rootfs.tar .

cat <<EOF > $OUT/Dockerfile
FROM scratch

ADD rootfs.tar /

ENV \
  LANG=C.UTF-8 \
  LD_LIBRARY_PATH=/lib \
  JAVA_HOME=/usr/jre \
  PATH=/usr/jre/bin

ENTRYPOINT [ "/usr/jre/bin/java" ]

EOF
