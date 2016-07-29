#!/usr/bin/env sh
set -eux

JAVA_VERSION=8.13.0.5-jdk8.0.72-linux_x64
JAVA_MD5SUM=50b95832b1d072afc178d820e5680687

BASE=$PWD
SRC=$PWD/src
OUT=$PWD/java-build
ROOTFS=$PWD/rootfs

mkdir -p $BASE/java
cd $BASE/java
curl -O \
     -e http://www.azul.com/downloads/zulu/zulu-linux/ \
     -L http://cdn.azul.com/zulu/bin/zulu$JAVA_VERSION.tar.gz

echo "$JAVA_MD5SUM  zulu$JAVA_VERSION.tar.gz" | md5sum -c

mkdir -p $ROOTFS/opt
tar xf zulu$JAVA_VERSION.tar.gz
mv zulu$JAVA_VERSION/jre $ROOTFS/opt/
rm -rf $ROOTFS/opt/jre/bin/{jjs,keytool,orbd,pack200,policytool,rmid,rmiregistry,servertool,tnameserv,unpack200} \
   $ROOTFS/opt/jre/lib/ext/nashorn.jar

echo 'networkaddress.cache.ttl=10' >> $ROOTFS/opt/jre/lib/security/java.security
cp /etc/pki/ca-trust/extracted/java/cacerts $ROOTFS/opt/jre/lib/security/cacerts

mkdir -p $ROOTFS/lib64
cp \
    $BASE/glibc-build/libc.so.* \
    $BASE/glibc-build/dlfcn/libdl.so.* \
    $BASE/glibc-build/nptl/libpthread.so.* \
    $BASE/glibc-build/elf/ld-linux-x86-64.so.* \
    $BASE/glibc-build/math/libm.so* \
    $BASE/glibc-build/nss/libnss_files.so.* \
    $BASE/glibc-build/resolv/libnss_dns.so.* \
    $ROOTFS/lib64

ln -s /lib64 $ROOTFS/lib 

mkdir -p $ROOTFS/etc
echo 'hosts: files mdns4_minimal dns [NOTFOUND=return] mdns4' >> $ROOTFS/etc/nsswitch.conf

cat <<EOF > $ROOTFS/etc/passwd
root:x:0:0:root:/:/dev/null
nobody:x:65534:65534:nogroup:/:/dev/null
EOF

cat <<EOF > $ROOTFS/etc/group
root:x:0:
nogroup:x:65534:
EOF

mkdir -p $OUT

cd $ROOTFS
tar -cf $OUT/rootfs.tar .

cat <<EOF > $OUT/Dockerfile
FROM scratch

ADD rootfs.tar /

ENV \
  LANG=C.UTF-8 \
  LD_LIBRARY_PATH=/lib \
  JAVA_HOME=/opt/jre \
  PATH=/opt/jre/bin

ENTRYPOINT [ "/opt/jre/bin/java" ]

EOF
