## Prerequisites

* a cluster/supercomputer with OpenSHMEM installed.

As discussed in the [background section](../background/bale.md), `hclib-actor` depends on Bale, which depends on OpenSHMEM. Here we mainly explain steps to load OpenSHMEM, build bale, and build `hclib-actor` on three platforms: Perlmutter@NERSC, Frontier@ORNL, and PACE (Phoenix)@ GT.

## Installation/initialization Scripts  

=== "Perlmutter@NERSC"

     [perlmutter_setup.sh](https://github.com/habanero-lab/hclib-actor/blob/master/cluster-scripts/perlmutter_setup.sh)

=== "Frontier@ORNL"

    [frontier_setup.sh](https://github.com/habanero-lab/hclib-actor/blob/master/cluster-scripts/frontier_setup.sh)

=== "PACE@GATech"

    [oshmem-slurm.sh](https://github.com/habanero-lab/hclib-actor/blob/master/cluster-scripts/oshmem-slurm.sh)


!!! tip

     In order to run a job successfully every time after you log in to a cluster/supercomputer, please make sure to

     - Go to the directory where you initially ran the respective script for the platform using the above scripts.
     - `source` the script again to set all environment variables.


## Run

Modern HPC platforms, including Perlmutter, Frontier, and PACE, support Slurm. Users typically run applications through batch jobs by creating a job script and submitting it with sbatch, although interactive jobs are also commonly supported.

Example Slurm script (`example.slurm`) that runs 256 PEs on 2 nodes of Perlmutter:
     
``` title="example.slurm"
#!/bin/bash
#SBATCH -q regular
#SBATCH -N 2
#SBATCH -C cpu
#SBATCH -t 0:05:00

srun -n 256 ./histo_selector
```

Submit a job:
```
sbatch example.slurm
```

Example output:
```
Running histo on 256 threads
buf_cnt (number of buffer pkgs)      (-b)= 1024
Number updates / thread              (-n)= 1000000
Table size / thread                  (-T)= 1000
models_mask                          (-M)= 0
     0.140 seconds
```
    
!!! tip

     Site-specific options (e.g., account, queue/partition, node type, and wall-clock limits) vary across systems such as Perlmutter (NERSC), Frontier (ORNL), and PACE (Georgia Tech). Please consult your local system documentation for the appropriate Slurm options. For example:

     - [Perlmutter](https://docs.nersc.gov/jobs/)
     - [Frontier](https://docs.olcf.ornl.gov/systems/frontier_user_guide.html#running-jobs)
     - [PACE (Needs GT login)](https://gatech.service-now.com/technology?id=kb_article_view&sysparm_article=KB0041998)

!!! tip

    For best performance, we recommend launching one task, process, or PE per physical core. On current systems, this corresponds to 128 tasks/processes/PEs per node on Perlmutter, 64 on Frontier, and 24 on PACE.
     

## Manual installation instructions

This part can be done using the [Installation/initialization Scripts](https://hclib-actor.com/getting_started/clusters/#installation-scripts), but you can also install everything manually using the guide below.

### Load OpenSHMEM  

The instructions below assume that OpenSHMEM is already available on your system, such as Cray OpenSHMEMX on Perlmutter and Frontier or Open MPI with OpenSHMEM support on PACE. Building an OpenSHMEM backend from source is outside the scope of this guide.

=== "Cray OpenSHMEMX"

     Use Cray OpenSHMEMX
     ```
     module load cray-openshmemx
     module load cray-pmi
     export PLATFORM=ex
     export CC=cc
     export CXX=CC
     ```

=== "Open MPI (with OpenSHMEM enabled)"

    Use OpenMPI's SHMEM (OSHMEM)
    ```
     module load gcc
     module load python
     module load openmpi/4.1.5
     export CC=oshcc
     export CXX=oshc++
    ```

!!! note

    You need to re-run the above commands every time you login to a cluster/supercomputer. You can use the corresponding platform script from the above pre-prepared scripts (`source ./{PLATFORM}_setup.sh` or `source ./oshmem-{PLATFORM}.sh`).

!!! note

    


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

    On systems with Cray OpenSHMEMX (e.g., Perlmutter and Frontier), Bale may fail to build because its configuration process detects the obsolete `shmemx_team_*` extension, which is no longer part of modern OpenSHMEM implementations and is not used by Bale. To work around this issue, run `patch -p1 < path/to/perlmutter.patch` in the `bale` directory after `git clone`. The patch can be found [here](https://github.com/habanero-lab/hclib-actor/blob/master/cluster-scripts/perlmutter.patch). Alternatively, build Bale using: `python3 ./make_bale -s --config_opts "CC=cc ac_cv_search_shmemx_team_alltoallv=no"`.


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
