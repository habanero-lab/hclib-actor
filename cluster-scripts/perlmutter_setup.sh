#!/bin/bash

# Setup HClib and its modules
echo "-----------------------------------------------------"
echo "Setting up HClib and its modules"
echo "-----------------------------------------------------"

# Load modules
module load cray-openshmemx
module load cray-pmi

# Export environment variables
export PLATFORM=ex
export CC=cc
export CXX=CC
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cray/pe/perftools/23.02.0/lib64

# Setup Bale
if [ ! -d bale ]; then
    git clone https://github.com/jdevinney/bale.git bale
    cd bale
    wget https://raw.githubusercontent.com/habanero-lab/hclib-actor/refs/heads/master/cluster-scripts/perlmutter.patch
    patch -p1 < perlmutter.patch
    cd ..
    cd bale/src/bale_classic
    export BALE_INSTALL=$PWD/build_${PLATFORM}
    ./bootstrap.sh
    python3 ./make_bale -s
    cd ../../../
fi

# Setup HCLib
if [ ! -d hclib ]; then
    git clone https://github.com/srirajpaul/hclib
    cd hclib
    git fetch && git checkout bale3_actor
    ./install.sh --enable-production
    source hclib-install/bin/hclib_setup_env.sh
    cd modules/bale_actor && make
    cd benchmarks
    unzip ../inc/boost.zip -d ../inc/
    cd ../../../../
fi

export BALE_INSTALL=$PWD/bale/src/bale_classic/build_${PLATFORM}
export HCLIB_ROOT=$PWD/hclib/hclib-install
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$BALE_INSTALL/lib:$HCLIB_ROOT/lib:$HCLIB_ROOT/../modules/bale_actor/lib
export HCLIB_WORKERS=1

# All setups are complete
echo "-----------------------------------------------------"
echo "               HClib setup complete!                 "
echo "-----------------------------------------------------"

