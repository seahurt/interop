#!/usr/bin/env bash
########################################################################################################################
# This script packages the InterOp library using Docker
#
# Requires two command line arguments:
# 1. source file directory
# 2. artifact directory
#
# Pull the Image
#
# $ docker pull ezralanglois/interop
#
# Run the Image
#
# $ docker run --rm -w /tmp --user `id -u`:`id -g` -v `pwd`:/src:ro -v `pwd`/dist:/dist:rw ezralanglois/interop sh /src/tools/package.sh /src /dist travis OFF Release
# $ docker run --rm -w /tmp --user `id -u`:`id -g` -v `pwd`:/src:ro -v `pwd`/dist:/dist:rw ezralanglois/interop sh /src/tools/package.sh /src /dist teamcity OFF Release
#
# Debug the Image Interactively
#
# $ docker run --rm -i -t -v `pwd`:/io ezralanglois/interop sh /io/tools/package_linux.sh /io /io/dist
#
#
########################################################################################################################
set -e
INTEROP_C89=OFF
BUILD_TYPE=Release

# When inside docker and not using root, but using the root home. So, change it to working directory
# Without this, nuget fails when trying to read Nuget.config
whoami 1>/dev/null 2>&1 || export HOME=$PWD

# Get value from environment for low memory vms
if [ -z $THREAD_COUNT ] ; then
    THREAD_COUNT=4
fi

if [ ! -z $1 ] ; then
    SOURCE_PATH=$1
fi
BUILD_PATH=build

if [ ! -z $2 ] ; then
    ARTIFACT_PATH=$2
elif [ ! -z $SOURCE_PATH ]; then
    ARTIFACT_PATH=$SOURCE_PATH/dist
fi

# ARTIFACT_PATH="$(echo $(cd $(dirname "$ARTIFACT_PATH") && pwd -P)/$(basename "$ARTIFACT_PATH"))"

if hash greadlink  2> /dev/null; then
    readlink="greadlink"
else
    readlink="readlink"
fi
#ARTIFACT_PATH=`$readlink -f $ARTIFACT_PATH`

if [ ! -z $3 ] ; then
    BUILD_SERVER="$3"
    DISABLE_SUBDIR=OFF
    if [[ "$BUILD_SERVER" == "travis" ]]; then
        DISABLE_SUBDIR=ON
    fi
else
    DISABLE_SUBDIR=OFF
    OFF=
fi

if [ ! -z $4 ] ; then
    INTEROP_C89="$4"
fi

if [ ! -z $5 ] ; then
    BUILD_TYPE="$5"
fi

if [ ! -z $6 ] ; then
    PYTHON_VERSION="$6"
else 
    PYTHON_VERSION="cp310-cp310"
fi

if [ ! -z $7 ] ; then
    BUILD_NUMBER="$7"
fi

if [ ! -z "$8" ] ; then
    MORE_FLAGS="$8"
fi

echo "------------------------------------------------------------"
echo "package.sh Configuration"
echo "Source path: ${SOURCE_PATH}"
echo "Artifact path: ${ARTIFACT_PATH}"
echo "Build server: ${BUILD_SERVER}"
echo "C89 Support: ${INTEROP_C89}"
echo "Build Type: ${BUILD_TYPE}"
echo "Python Version: ${PYTHON_VERSION}"
echo "Build Number: ${ARTFACT_BUILD_NUMBER}"
echo "Additional Flags: ${MORE_FLAGS}"
echo "------------------------------------------------------------"

git config --global --add safe.directory ${SOURCE_PATH}

CMAKE_EXTRA_FLAGS="-DDISABLE_PACKAGE_SUBDIR=${DISABLE_SUBDIR} -DENABLE_PORTABLE=ON -DENABLE_BACKWARDS_COMPATIBILITY=$INTEROP_C89 -DCMAKE_BUILD_TYPE=$BUILD_TYPE $MORE_FLAGS"


if [ "$PYTHON_VERSION" == "Disable" ] ; then
    CMAKE_EXTRA_FLAGS="-DENABLE_SWIG=OFF $CMAKE_EXTRA_FLAGS"
fi

if [ ! -z $BUILD_NUMBER ] ; then
  CMAKE_EXTRA_FLAGS="-DBUILD_NUMBER=$BUILD_NUMBER  $CMAKE_EXTRA_FLAGS"
fi


if [ ! -z $ARTIFACT_PATH ] ; then
  CMAKE_EXTRA_FLAGS="-DPACKAGE_OUTPUT_FILE_PREFIX=${ARTIFACT_PATH} -DDOCS_OUTPUT_PATH=${ARTIFACT_PATH} $CMAKE_EXTRA_FLAGS"
fi

source `dirname $0`/prereqs/utility.sh

if [ -z $SOURCE_PATH ] ; then
    exit 0
fi

if [ -e $BUILD_PATH ] ; then
    rm -fr $BUILD_PATH
fi
mkdir $BUILD_PATH

if [ ! -e $ARTIFACT_PATH ] ; then
    mkdir $ARTIFACT_PATH
fi



/opt/python/$PYTHON_VERSION/bin/python -m pip install numpy==2.0.0 pandas setuptools
/opt/python/cp310-cp310/bin/python -m pip install swig==4.0.2 --prefix=/tmp/usr

echo "Build with specific Python Version: ${PYTHON_VERSION}"
PYTHON_BIN=/opt/python/${PYTHON_VERSION}/bin
rm -fr ${BUILD_PATH}/src/ext/python/*
run "Configure ${PYTHON_VERSION}" cmake $SOURCE_PATH -B${BUILD_PATH} -DPython_EXECUTABLE=${PYTHON_BIN}/python ${CMAKE_EXTRA_FLAGS} -DSKIP_PACKAGE_ALL_WHEEL=ON -DPYTHON_WHEEL_PREFIX=${ARTIFACT_PATH}/tmp -DENABLE_CSHARP=OFF -DSWIG_EXECUTABLE=/tmp/usr/lib/python3.10/site-packages/swig/data/bin/swig  -DSWIG_DIR=/tmp/usr/lib/python3.10/site-packages/swig/data/share/swig/4.0.2/

# run "Test ${PYTHON_VERSION}" cmake --build $BUILD_PATH --target check -- -j${THREAD_COUNT}
run "Build ${PYTHON_VERSION}" cmake --build $BUILD_PATH --target package_wheel -- -j${THREAD_COUNT}
auditwheel show ${ARTIFACT_PATH}/tmp/interop*${PYTHON_VERSION}*linux_*.whl
auditwheel repair ${ARTIFACT_PATH}/tmp/interop*${PYTHON_VERSION}*linux_*.whl -w ${ARTIFACT_PATH}
rm -fr ${ARTIFACT_PATH}/tmp


setuser $SOURCE_PATH $ARTIFACT_PATH || true

