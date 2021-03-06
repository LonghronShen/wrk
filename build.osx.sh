#!/bin/bash

cd libs/libressl-portable
./autogen.sh
cd ../../

mkdir -p build

cd build

cmake -DOPENSSL_ROOT_DIR=/usr/local/opt/openssl/ -DOPENSSL_LIBRARIES=/usr/local/opt/openssl/lib ..

make -j4
