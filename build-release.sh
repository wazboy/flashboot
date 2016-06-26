#!/bin/sh

CWD=`pwd`
WORKDIR=sandbox

MAKECONF=${CWD}/mk-mini.conf
BSDSRCDIR=${CWD}/${WORKDIR}/src
BSDOBJDIR=${CWD}/${WORKDIR}/obj
DESTDIR=${WORKDIR}/destdir
RELEASEDIR=${WORKDIR}/releasedir

export MAKECONF BSDSRCDIR BSDOBJDIR

# Update for each new release
SHORTREL="59"
LONGREL="5.9"

# No need to change anything below this line for new OS releases!

# Change if ftp.su.se is not the best place to get your files from!
URLBASE="http://ftp.su.se/pub/OpenBSD/${LONGREL}"
PATCHURL="ftp://ftp.openbsd.org/pub/OpenBSD/patches/${LONGREL}/common/*"

echo "Cleaning up previous build.."
rm -rf ${WORKDIR}

echo "Creating sandbox and diststuff.."
mkdir -p ${BSDSRCDIR} ${BSDOBJDIR}
test -d ${DESTDIR} && mv ${DESTDIR} ${DESTDIR}- && \
    rm -rf ${DESTDIR}-
mkdir -p ${DESTDIR} ${RELEASEDIR}
mkdir -p diststuff

echo "Getting current patches.."
mkdir -p ${WORKDIR}/patches
cd ${WORKDIR}/patches
ftp ${PATCHURL}
cd ${CWD}

srcfiles="src.tar.gz
sys.tar.gz"

cd diststuff

echo "Downloading OpenBSD-${LONGREL} source.."
for file in ${srcfiles}; do
  if [ ! -f ${file} ] ; then 
    echo "Needed ${file}, didn't find it in current dir so downloading.."
    ftp ${URLBASE}/${file}
  fi
done

for file in ${srcfiles}; do
  echo "checking ${file} file integrity"
  gunzip -t ${file}
  if [ $? != 0 ] ; then
   echo "${file} is corrupt! Exiting"
   exit
  fi
  echo "file integrity OK, extracting ${file} to ${WORKDIR}"
  tar zxpf ${file} -C ../${WORKDIR}/src
done

cd ${CWD}/${WORKDIR}

echo "Patching src.."
for file in patches/*.patch.sig; do
  signify -Vep /etc/signify/openbsd-59-base.pub -x ${file} -m - | \
      (cd ${BSDSRCDIR} && patch -p0)
done

# rebuild obj dirs
cd ${BSDSRCDIR} && make obj

# build this thing
cd ${BSDSRCDIR} && make build

cd ${BSDSRCDIR}/etc && doas env MAKECONF=${MAKECONF} \
    DESTDIR=${DESTDIR} \
    RELEASEDIR=${RELEASEDIR} \
    BSDSRCDIR=${BSDSRCDIR} \
    BSDOBJDIR=${BSDOBJDIR} \
    make release

echo "DONE! Now build kernel."

exit
