#!/bin/bash
# Install Singularity

# Required to build Singularity
sudo yum -y groupinstall "Development Tools"
sudo yum -y install libarchive-devel
sudo yum -y install squashfs-tools
sudo yum -y install git
sudo yum -y install pssh

# Download and build Singularity from the GitHub master branch
cd /tmp/
git clone -b vault/release-2.6 https://github.com/singularityware/singularity.git
cd singularity
./autogen.sh
./configure
make dist
rpmbuild -ta singularity-*.tar.gz

# Install newly built Singularity RPM package
sudo yum -y install $HOME/rpmbuild/RPMS/x86_64/singularity-*.x86_64.rpm

# Install additional dependencies
sudo yum -y install epel-release
sudo yum -y install debootstrap

# Install openmpi
sudo yum install openmpi openmpi-devel
