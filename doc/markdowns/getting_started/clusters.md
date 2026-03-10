## Prerequisites

* a cluster/supercomputer with OpenSHMEM or UPC installed.

As discussed in the [background section](../background/bale.md), `hclib-actor` depends on Bale, which depends on either UPC or OpenSHMEM. Here we mainly explain steps to load OpenSHMEM, build bale, and build `hclib-actor` on three platforms: Perlmutter@NERSC, Cori@NERSC, Summit@ORNL, and PACE (Phoenix)@ GT.

## Installation/initialization Scripts  

=== "Perlmutter@NERSC"

     [perlmutter_setup.sh](https://github.com/habanero-lab/hclib-actor/blob/master/cluster-scripts/perlmutter_setup.sh)

=== "Cori@NERSC"

     [cori_setup.sh]()

=== "Summit@ORNL"

    [summit_setup.sh]()

=== "PACE@GATech"

    [oshmem-slurm.sh](https://github.com/habanero-lab/hclib-actor/blob/master/cluster-scripts/oshmem-slurm.sh)


!!! tip

     In order to run a job successfully every time after you login to a cluster/supercomputer, please make sure to

     - Redirect to the directory where you initizally run the respective script for the platform using the above scripts.
     - `source` the script again to set all environment variables.


## Run

=== "Perlmutter@NERSC"

     Example Slurm script (`example.slurm`)
     ``` title="example.slurm"
     #!/bin/bash
     #SBATCH -q regular
     #SBATCH -N 2
     #SBATCH -C cpu
     #SBATCH -t 0:05:00

     srun -n 256 ./histo_selector
     ```
    Submit a job
    ```
    sbatch example.slurm
    ```

=== "Cori@NERSC"

     Example Slurm script (`example.slurm`)
     ``` title="example.slurm"
     #!/bin/bash
     #SBATCH -q regular               # job is submitted to regular queue
     #SBATCH -N 2                     # resources allocated, 2 nodes
     #SBATCH -C haswell               # use haswell nodes
     #SBATCH -t 00:30:00              # job will run at most 30min
     
     srun -n 64 ./histo_selector
     ```
    Submit a job
    ```
    sbatch example.slurm
    ```

=== "Summit@ORNL"
   
    Example LSF script (`example.lsf`)
    ``` title="example.lsf"
    #!/bin/bash
    #BSUB -P XXXXX                     # project to which job is charged
    #BSUB -W 0:30                      # job will run at most 30 min
    #BSUB -nnodes 2                    # resources allocated, 2 nodes
    #BSUB -alloc_flags smt1            # one logical thread per physical core
    #BSUB -J histo                     # name of job
    #BSUB -o histo.%J                  # stdout file
    #BSUB -e histo.%J                  # stderror file

    jsrun -n 84 ./histo_selector
    ```
    Submit a job
    ```
    bsub example.lsf
    ```

=== "PACE@GATech"

    Example Slurm script(`example.sbatch`):
    ``` title="example.sbatch"
    #!/bin/bash
    #SBATCH -Joshmem                    # name of job
    #SBATCH --account=GT-XXXXXXX        # account to which job is charged
    #SBATCH -N 2                        # 2 nodes
    #SBATCH -n 48                       # resources allocated, 48 cores
    #SBATCH -t15                        # job will run at most 15mins
    #SBATCH -qinferno                   # job is submitted to inferno queue
    #SBATCH -ooshmem.out                # output file is named oshmem.out      

    echo "Started on `/bin/hostname`"   # prints name of compute node job was started on
    cd $SLURM_SUBMIT_DIR                # changes into directory where script was submitted from

    source ./oshmem-slurm.sh

    cd ./hclib/modules/bale_actor/test
    srun -n 48 ./histo_selector
    ```
    Submit a job:
    ```
    sbatch example.sbatch
    ```

Example output:
    ```
    Running histo on 48 threads
    buf_cnt (number of buffer pkgs)      (-b)= 1024
    Number updates / thread              (-n)= 1000000
    Table size / thread                  (-T)= 1000
    models_mask                          (-M)= 0
       0.106 seconds
    ```
    


## Manual installation instructions

This part can be done with the [Installation/initialization Scripts](https://hclib-actor.com/getting_started/clusters/#installation-scripts), but you can also manually install everything with the guide below.

### Load OpenSHMEM  

=== "Perlmutter@NERSC"

     Use Cray OpenSHMEMX
     ```
     module load cray-openshmemx
     module load cray-pmi
     export PLATFORM=ex
     export CC=cc
     export CXX=CC
     ```

=== "Cori@NERSC"

     Use Cray SHMEM
     ```
     module swap PrgEnv-intel PrgEnv-gnu
     module load cray-shmem 
     module load python3
     export PLATFORM=xc30
     export CC=cc
     export CXX=CC
     ```

=== "Summit@ORNL"

    Use OpenMPI's SHMEM (OSHMEM)
    ```
    module load python
    export PLATFORM=oshmem
    export CC=oshcc
    export CXX=oshc++
    ```

=== "PACE@GATech"

    Use OpenMPI's SHMEM (OSHMEM)
    ```
     module load gcc
     module load python
     module load openmpi/4.1.4
     export CC=oshcc
     export CXX=oshc++
    ```

!!! note

    You need to re-run the above commands every time you login to a cluster/supercomputer. You can use the respective script for the platform using the above pre-prepared scripts (`source ./{PLATFORM}_setup.sh` or `source ./oshmem-{PLATFORM}.sh`).


### Build Bale and HClib

#### Bale

```
git clone https://github.com/jdevinney/bale.git bale
cd bale/src/bale_classic
export BALE_INSTALL=$PWD/build_${PLATFORM}
./bootstrap.sh
python3 ./make_bale -s
cd ../../../
```

!!! note

    On Perlmutter, do `patch -p1 < path/to/perlmutter.patch` in `bale` directory after `git clone`. You can find `perlmutter.patch` [here](https://github.com/habanero-lab/hclib-actor/blob/master/cluster-scripts/perlmutter.patch).


!!! note
  
    Bale will be installed in `bale/src/bale_classic/build_${PLATFORM}`
    

#### HClib

```
git clone https://github.com/srirajpaul/hclib
cd hclib
git fetch && git checkout bale3_actor
./install.sh
source hclib-install/bin/hclib_setup_env.sh
cd modules/bale_actor && make
cd test
unzip ../inc/boost.zip -d ../inc/
make
cd ../../../../
```

#### Setting environment variables
```
export BALE_INSTALL=$PWD/bale/src/bale_classic/build_${PLATFORM}
export HCLIB_ROOT=$PWD/hclib/hclib-install
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$BALE_INSTALL/lib:$HCLIB_ROOT/lib:$HCLIB_ROOT/../modules/bale_actor/lib
export HCLIB_WORKERS=1
```
