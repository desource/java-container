#!/usr/bin/env bash
#
# Download and build java container
set -euo pipefail

out=$PWD/out
rootfs=$PWD/rootfs
glibc=$PWD/glibc

# _download "version" "md5"
_download() {  
  curl -O \
       -e http://www.azul.com/downloads/zulu/zulu-linux/ \
       -L http://cdn.azul.com/zulu/bin/zulu${1}.tar.gz
  echo "${2}  zulu${1}.tar.gz" | md5sum -c

  tar xf zulu${1}.tar.gz

  mkdir -p ${rootfs}/usr

  mv zulu${1}/jre ${rootfs}/usr/
}

_build() {
  mkdir -p ${rootfs}/etc ${rootfs}/lib64
    
  rm -rf ${rootfs}/usr/jre/bin/{jjs,keytool,orbd,pack200,policytool,rmid,rmiregistry,servertool,tnameserv,unpack200} \
     ${rootfs}/usr/jre/lib/ext/nashorn.jar
  
  cp \
      ${glibc}/libc.so.* \
      ${glibc}/dlfcn/libdl.so.* \
      ${glibc}/nptl/libpthread.so.* \
      ${glibc}/elf/ld-linux-x86-64.so.* \
      ${glibc}/math/libm.so* \
      ${glibc}/nss/libnss_files.so.* \
      ${glibc}/resolv/libnss_dns.so.* \
      ${rootfs}/lib64
  
  ln -s /lib64 ${rootfs}/lib 

  echo 'hosts: files mdns4_minimal dns [NOTFOUND=return] mdns4' >> ${rootfs}/etc/nsswitch.conf

  cat <<EOF > ${rootfs}/etc/passwd
root:x:0:0:root:/:/dev/null
nobody:x:65534:65534:nogroup:/:/dev/null
EOF

  cat <<EOF > ${rootfs}/etc/group
root:x:0:
nogroup:x:65534:
EOF

  echo 'networkaddress.cache.ttl=10' >> ${rootfs}/usr/jre/lib/security/java.security
  cp /etc/pki/ca-trust/extracted/java/cacerts ${rootfs}/usr/jre/lib/security/cacerts

  tar -cf ${out}/rootfs.tar -C ${rootfs} .
}

_dockerfile() {
  cat <<EOF > ${out}/version
${1}
EOF
  
  cat <<EOF > ${out}/Dockerfile
FROM scratch

ADD rootfs.tar /

ENV \
  LANG=C.UTF-8 \
  LD_LIBRARY_PATH=/lib \
  JAVA_HOME=/usr/jre \
  PATH=/usr/jre/bin

ENTRYPOINT [ "/usr/jre/bin/java" ]

EOF
}

_download 8.17.0.3-jdk8.0.102-linux_x64 abd8b70fa1a743f74c43d21f0a9bea43
_build
_dockerfile  8u102
