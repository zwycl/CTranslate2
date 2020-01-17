#! /bin/bash

set -e
set -x

ROOT_DIR=$PWD
PYBIND11_VERSION=${PYBIND11_VERSION:-2.4.3}
MKL_VERSION=${MKL_VERSION:-2020.0-088}
MKLDNN_VERSION=${MKLDNN_VERSION:-0.21}
PATH=/opt/python/cp37-cp37m/bin:$PATH

yum install -y yum-utils
yum-config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo
rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
yum install -y intel-mkl-64bit-${MKL_VERSION}

pip install "cmake==3.13.*"

curl -fsSL -O https://github.com/intel/mkl-dnn/archive/v$MKLDNN_VERSION.tar.gz
tar xf v$MKLDNN_VERSION.tar.gz
rm v$MKLDNN_VERSION.tar.gz
cd mkl-dnn-*
mkdir build && cd build
cmake -DARCH_OPT_FLAGS="" \
      -DMKLROOT=/opt/intel/mkl -DMKLDNN_USE_MKL=FULL:STATIC -DMKLDNN_THREADING=OMP:INTEL \
      -DWITH_TEST=OFF -DWITH_EXAMPLE=OFF ..
make -j2 install
cd ../..
rm -r mkl-dnn-*

mkdir build-release && cd build-release
cmake -DCMAKE_BUILD_TYPE=Release -DLIB_ONLY=ON -DWITH_MKLDNN=ON ..
make -j2 install
cd ..
rm -r build-release

cd python
for PYTHON_ROOT in /opt/python/*
do
    $PYTHON_ROOT/bin/pip install pybind11==${PYBIND11_VERSION}
    $PYTHON_ROOT/bin/python setup.py bdist_wheel
    rm -rf build
done

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/intel/lib/intel64/
for wheel in dist/*
do
    auditwheel show $wheel
    auditwheel repair $wheel
done
