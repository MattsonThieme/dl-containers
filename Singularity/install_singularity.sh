#!/bin/bash
VERSION=2.6.0
yes 'y' | sudo yum install libarchive-devel
yes 'y' | sudo yum install squashfs-tools
wget https://github.com/singularityware/singularity/releases/download/$VERSION/singularity-$VERSION.tar.gz /singularity-$VERSION.tar.gz

tar xvf singularity-$VERSION.tar.gz
cd singularity-$VERSION
./configure --prefix=/root/singularity
make
sudo make install
