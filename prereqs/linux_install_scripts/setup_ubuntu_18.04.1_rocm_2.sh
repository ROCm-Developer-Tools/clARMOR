#!/bin/bash
# Copyright (c) 2016-2017 Advanced Micro Devices, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# The following script will help set up a fresh Ubuntu 18.04.1 LTS installation
# with the ROCm software stack

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
INSTALLER_DIR=${BASE_DIR}/../install_files/
REAL_USER=`logname 2>/dev/null || echo ${SUDO_USER:-${USER}}`

INIT_FILE="rocm_setup"
sudo rm -f /etc/xdg/autostart/${INIT_FILE}.desktop
sudo rm -f /etc/init.d/${INIT_FILE}


#Install general utilities
#===============================================================================
# Other common build things
sudo apt-get -y install gfortran fort77 mesa-common-dev binutils-dev libcpufreq-dev autoconf automake cmake cmake-curses-gui libtool libtool-bin automake1.11 autotools-dev numactl cpufreqd flex bison libxml2-dev aptitude valgrind dos2unix cppcheck libx11-6:i386 libc6:i386 gcc-multilib g++-multilib libncurses5:i386 libstdc++6:i386 lib32z1 lib32ncurses5 libbz2-1.0 lib32stdc++6 libelf-dev libboost-dev libboost-system-dev libboost-filesystem-dev libboost-thread-dev libboost-all-dev libswitch-perl qt5-default qttools5-dev-tools libstdc++-4.8-dev libdwarf-dev libtinfo-dev libc6-dev-i386 llvm llvm-dev llvm-runtime libc++1 libc++-dev libc++abi1 libc++abi-dev libncurses5-dev parallel screen htop libssl-dev libnuma-dev libgtest-dev super
sudo apt-get -y install clang-3.9 clang-3.9-doc libclang-common-3.9-dev libclang-3.9-dev libclang1-3.9 libclang1-3.9-dbg libllvm3.9 llvm-3.9 llvm-3.9-dev llvm-3.9-doc llvm-3.9-examples llvm-3.9-runtime clang-format-3.9 python-clang-3.9
sudo apt-get -y install clang-4.0 clang-4.0-doc libclang-common-4.0-dev libclang-4.0-dev libclang1-4.0 libclang1-4.0-dbg libllvm4.0 llvm-4.0 llvm-4.0-dev llvm-4.0-doc llvm-4.0-examples llvm-4.0-runtime clang-format-4.0 
sudo apt-get -y install clang-5.0 clang-5.0-doc libclang-common-5.0-dev libclang-5.0-dev libclang1-5.0 libclang1-5.0-dbg libllvm5.0 llvm-5.0 llvm-5.0-dev llvm-5.0-doc llvm-5.0-examples llvm-5.0-runtime clang-format-5.0 python-clang-5.0
sudo apt-get -y install clang-tools
sudo ln -s -f /usr/bin/scan-build-6.0 /usr/bin/scan-build
sudo sh -c "echo msr >> /etc/modules"
sudo ln -s /usr/include/x86_64-linux-gnu/openssl/opensslconf.h /usr/include/openssl/opensslconf.h
sudo apt-get -y install linux-tools-`uname -r` linux-tools-common
sudo apt-get install rocblas hipblas miopengemm miopen-hip

#Fortran 4.8 for Mantevo
sudo apt-get -y install gfortran-4.8

# Need libglew etc. for some Phoronix benchmarks which use the GUI
sudo apt-get -y install freeglut3 freeglut3-dev libglew-dev

#Install general Python
#===============================================================================
sudo apt-get -y install python-numpy python-scipy python-matplotlib ipython ipython-notebook python-pandas python-sympy python-nose python-setuptools python-dev python-sklearn python-argparse pylint
sudo easy_install pip
sudo pip install -U pyyaml Cython vulture

#Enable PerfMon access
#===============================================================================
sudo sh -c "echo kernel.perf_event_paranoid = -1 >> /etc/sysctl.conf"
sudo sh -c "echo kernel.pid_max = 4194304 >> /etc/sysctl.conf"
sudo sh -c "echo kernel.nmi_watchdog = 0 >> /etc/sysctl.conf"

#Disable ASLR
#=================================================
sudo sh -c "echo kernel.randomize_va_space = 0 >> /etc/sysctl.conf"
sudo sh -c "echo kernel.kptr_restrict = 0 >> /etc/sysctl.conf"
sudo sh -c "echo kernel.panic = 10 >> /etc/sysctl.conf"
sudo sh -c "echo kernel.panic_on_io_nmi = 1 >> /etc/sysctl.conf"
sudo sh -c "echo kernel.panic_on_oops = 1 >> /etc/sysctl.conf"
sudo sh -c "echo kernel.panic_on_unrecovered_nmi = 1 >> /etc/sysctl.conf"

#Install OpenMPI -- Used for some benchmarks
#===============================================================================
sudo apt-get -y install openmpi-bin openmpi-doc libopenmpi-dev

#Install ROCm-SMI so it works with SETUID
#=================================================
mkdir -p ~/Downloads/software/temp_rocm_smi
cd ~/Downloads/software/temp_rocm_smi
git clone -b roc-1.8.x https://github.com/RadeonOpenCompute/ROC-smi.git
mv ./ROC-smi/rocm-smi ./ROC-smi/real_rocm-smi
sudo chown -R root:root ./ROC-smi/
sudo mkdir -p /opt/AMD/
sudo mv ./ROC-smi /opt/AMD/
cp -R $BASE_DIR/../support_files/rocm-smi ~/Downloads/software/temp_rocm_smi
sudo chown root:root ./rocm-smi
sudo chmod a+x ./rocm-smi
sudo mv ./rocm-smi /opt/rocm/bin/
sudo sh -c "echo rocm-smi /opt/AMD/ROC-smi/real_rocm-smi :video uid=0 >> /etc/super.tab"

#Install ROCm CMake Modules
#=================================================
temp_dir=`mktemp -d`
pushd ${temp_dir}
git clone https://github.com/RadeonOpenCompute/rocm-cmake.git
cd rocm-cmake
mkdir build
cd build
cmake ..
sudo cmake --build . --target install
popd

# Prepare all the shared libraries
#=================================================
sudo ldconfig -v

#Reboot at this point
#==============================================================================
sudo reboot
#==============================================================================
