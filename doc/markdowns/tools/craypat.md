## Introduction

CrayPat (Cray Performance Measurement and Analysis toolset) is Cray’s performance analysis tool offered by Cray. Since CrayPat is only available on Cray systems, let us give a brief step-by-step guidance on how to use it on **Perlmutter**.

## Step-by-Step Guide
Here we will take Triangle Counting selector as an example:

### Step 0: Load compilers
It is important to load compiler modules before Step 1. In our case, `source` [perlmutter_setup.sh](https://github.com/habanero-lab/hclib-actor/blob/master/cluster-scripts/perlmutter_setup.sh):
```
source ./perlmutter_setup.sh
```

### Step 1: Unload/Load required modules
```
module unload darshan
module load perftools-base perftools
```
### Step 2: Build the application as normal but **keep `.o` files**
Go to the `test` directory to separately create an object file and executable for the triangle counting code:
```
cd $HCLIB_ROOT/../modules/bale_actor/test/
```
Create a tringle counting object file (.o file):
```
CC -g -O3 -std=c++11 -DUSE_SHMEM=1 -I$HCLIB_ROOT/include -I$BALE_INSTALL/include -I$HCLIB_ROOT/../modules/bale_actor/inc -L$HCLIB_ROOT/lib -L$BALE_INSTALL/lib -L$HCLIB_ROOT/../modules/bale_actor/lib -c -o triangle_selector.o triangle_selector.cpp -lhclib -lrt -ldl -lspmat -lconvey -lexstack -llibgetput -lhclib_bale_actor -lm
```
Build a triangle counting executable file:
```
CC -g -O3 -std=c++11 -DUSE_SHMEM=1 -I$HCLIB_ROOT/include -I$BALE_INSTALL/include -I$HCLIB_ROOT/../modules/bale_actor/inc -L$HCLIB_ROOT/lib -L$BALE_INSTALL/lib -L$HCLIB_ROOT/../modules/bale_actor/lib -o triangle_selector  triangle_selector.o -lhclib -lrt -ldl -lspmat -lconvey -lexstack -llibgetput -lhclib_bale_actor -lm
```
!!! tip

    It is recommended to do `make triangle_selector` first to see the full compilation command.
    
    - First, copy and paste the full command and change `-o triangle_selector triangle_selector.cpp` to `-c triangle_selector triangle_selector.cpp` to create an object file (.o file). 
    - Second, copy and paste the command again and change `-o triangle_selector triangle_selector.cpp` to `-o triangle_selector triangle_selector.o` to create an executable.

### Step 3: Instrument the application using `pat_build`
Generate a CrayPat instrumented executable using `pat_build`:
```
pat_build -w -g shmem triangle_selector
```

!!! note

    By default, `triangle_selector+pat` is generated.

!!! note

    `pat_build` has different option that can trace a specific function(s)
    
     - `-g`: trace Cray-provided library function group such as MPI and OpenSHMEM
     - `-u`: trace all user functions routine by routine
     - `-w`: flag that enables tracing
     - `-T -w`: trace user-defined functions
        - e.g, `pat_build -w -T selector_function`

### Step 4: Run the instrumented executable to get performance data

#### Option 1: Run the executable with an interactive batch job
Allocating resources:
```
salloc --nodes 1 --qos interactive --time 00:05:00 --constraint cpu --account=mxxx
```
Run the excutable to generate a directory (e.g., `triangle_selector+pat+174621-8716327t`) containing performance data files with the`.xf` suffix:
```
srun  -n 128 --cpu-bind=cores ./triangle_selector+pat
```

#### Option 2: Run the executable with sbatch script
```
#!/bin/bash
#SBATCH -q regular
#SBATCH -N 1
#SBATCH -C cpu
#SBATCH -t 0:05:00
#SBATCH -ooshmem_%j_tri_cout.out

source ./oshmem-perlmutter.sh

module unload darshan
module load perftools-base perftools
export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

cd $HOME/hclib/modules/bale_actor/test
echo "--------------------------------------------"
srun  -n 128 --cpu-bind=cores ./triangle_selector+pat
echo "--------------------------------------------"
```

### Step 5: Generate human-readable content with `pat_report`
Run `pat_report` with the generated directory name, which will output a text report on the terminal and creates files with different suffices, `.ap2` and `.apa` inside the directory:
```
pat_report ./triangle_selector+pat+174621-8716327t
```

#### Exemplar text report
```
CrayPat/X:  Version 23.03.0 Revision 46f710008  02/13/23 20:24:04
Number of PEs (MPI ranks):   128
Numbers of PEs per Node:     128
Numbers of Threads per PE:     1
Number of Cores per Socket:   64
Execution start time:  Fri Apr 14 13:44:36 2023
System name and speed:  nid004675  2.671 GHz (nominal)
AMD   Milan                CPU  Family: 25  Model:  1  Stepping:  1
Core Performance Boost:  All 128 PEs have CPB capability
Current path to data file:
  /Users/joseph/triangle_selector+pat+197953-8716330t   (RTS, 128 data files)
Notes for table 1:
  This table shows functions that have significant exclusive time,
    averaged across ranks.
  For further explanation, see the "General table notes" below, or 
    use:  pat_report -v -O profile ...
Table 1:  Profile by Function Group and Function
  Time% |     Time |     Imb. |  Imb. | Calls | Group
        |          |     Time | Time% |       |  Function
        |          |          |       |       |   PE=HIDE
 100.0% | 6.079316 |       -- |    -- | 404.0 | Total
|-------------------------------------------------------------------
|  95.2% | 5.789928 |       -- |    -- |   2.0 | USER
||------------------------------------------------------------------
||  47.7% | 2.901679 | 0.292158 |  9.2% |   1.0 | main
||  47.5% | 2.888249 | 0.000057 |  0.0% |   1.0 | #1.selector_function
||==================================================================
|   4.8% | 0.289263 | 0.100863 | 26.1% |   2.0 | DL
||------------------------------------------------------------------
||   4.8% | 0.289263 | 0.100863 | 26.1% |   2.0 | dlopen
|===================================================================
Notes for table 2:
  This table shows functions that have the most significant exclusive
    time, taking the maximum time across ranks and threads.
  For further explanation, see the "General table notes" below, or 
    use:  pat_report -v -O profile_max ...
Table 2:  Profile of maximum function times
  Time% |     Time |     Imb. |  Imb. | Function
        |          |     Time | Time% |  PE=[max,min]
|-----------------------------------------------------------
| 100.0% | 3.193838 | 0.292158 |  9.2% | main
...
```

!!! note

    `.ap2` is used to view performance data graphically with the Cray Apprentice2 tool.  
    `.apa` is for suggested `pat_build` options for more detailed tracing experiments.

## Using Apprentice2 for analyzing results

Cray Apprentice2 is a GUI-based analysis tool that can be used to visualize performance data instrumented with the CrayPat tool. Cray offers a desktop version of the Cray Apprentice2 visualizer so you can do your analysis locally.

To install a desktop version, you can find the installer on Perlmutter as below:
`$CRAYPAT_ROOT/share/desktop_installers`

`scp` an appropriate installer to your local machine and install it. After that, you will be able to open `.ap2` file with Apprentice2.

!!! tips

    If you encounter this error: `/some/path/./a.out: error while loading shared libraries: pat.so: cannot open shared object file: No such file or directory`  
    
    Try this: `export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH`


## Specifying profiling region
CrayPat performance API can be use to identify the region of interest (ROG) for analysis.

- `PAT_record(int state)`
  - Setting the recording state to **PAT_STATE_ON** or **PAT_STATE_OFF**
  - Needs to be inserted before the ROG
- `PAT_region_begin(int id, char *label)`
  - Defines the boundaries of a region
  - Needs to be inserted at the start the ROG
- `PAT_region_end(int id);`
  - regions must be either separate or nested
  - Needs to be inserted at the end of ROG

### Example
```
#include <pat_api.h>
...
PAT_record(PAT_STATE_ON);
PAT_region_begin(1,"selector_function");
triangle_selector();
PAT_region_end(1);
...
```
After generating the instrumented excutable with `pat_build` and run it, CrayPat will generate a trace of ROG in the performance data which can be found in the `pat_report`

Exemplar output
```
Table 1:  Profile by Function Group and Function

  Time% |     Time |     Imb. |  Imb. | Calls | Group
...
||  47.5% | 2.888249 | 0.000057 |  0.0% |   1.0 | #1.selector_function
||==================================================================
...
```

!!! note

    Please be cautious that `lgp_barrier()` will affect the load blance result when analysing with CrayPat region API. Therefore, it is recommended to insert the region before the `lgp_barrier()` function.

## Collecting hardware performance counters (HWPC)

The Performance Application Programming Interface (PAPI) allows you to programmatically collect hardware performance counters (HWPC) in your code. While the user is supposed to manually insert PAPI routines to specify what HWPCs are measured and when to start/stop measuing them, CrayPat dramatically facilitate that process. Specifically, all the user has to do is to just specify HWPC name(s) in an environment variable. Here are the steps to collect HWPCs with CrayPat:

### Step 1: Find available hardware counters
Available hardware counters can be find with `papi_avail`.

Available hardware counters on **Perlmutter** 
```
PAPI_L1_DCM     Level 1 data cache misses
PAPI_L2_DCM     Level 2 data cache misses
PAPI_L2_ICM     Level 2 instruction cache misses
PAPI_TLB_DM     Data translation lookaside buffer misses
PAPI_TLB_IM     Instruction translation lookaside buffer misses
PAPI_BR_MSP     Conditional branch instructions mispredicted
PAPI_TOT_INS      Instructions completed
PAPI_FP_INS     Floating point instructions
PAPI_BR_INS     Branch instructions
PAPI_VEC_INS      Vector/SIMD instructions (could include integer)
PAPI_TOT_CYC      Total cycles
PAPI_L2_DCH     Level 2 data cache hits
PAPI_L1_DCA     Level 1 data cache accesses
PAPI_L2_DCR     Level 2 data cache reads
PAPI_L2_ICH     Level 2 instruction cache hits
PAPI_L2_ICA     Level 2 instruction cache accesses
PAPI_L2_ICR     Level 2 instruction cache reads
PAPI_FML_INS      Floating point multiply instructions
PAPI_FAD_INS      Floating point add instructions
PAPI_FDV_INS      Floating point divide instructions
PAPI_FSQ_INS      Floating point square root instructions
PAPI_FP_OPS     Floating point operations
```

### Step 2: Selecting the hardware counters
Setting the environment variable `PAT_RT_PERFCTR` to specific events/group:

 - Predefined Counter Groups, e.g., `export PAT_RT_PERFCTR=0`.
 - Specify individual events (maximum of 4 event at a time), e.g. `export PAT_RT_PERFCTR="PAPI_L2_DCM,PAPI_L2_ICM,PAPI_L2_DCH,PAPI_L2_DCR"`.

!!! note

    Predefined Counter Groups can be found on slides 38 of [NERSC PerformanceTools](https://www.nersc.gov/assets/Uploads/PerformanceTools.pdf)

### Step 3:  Run the instrumented excutable with CrayPat
After exporting the hardware counter variable we just need to run the instrumented excutable and generate human-readable content with `pat_report`. A summary for the trace of ROG can be found in the text output of `pat_report`

Exemplar output
```
...
Table 3:  Profile by Function Group and Function
Group / Function / PE=HIDE
==============================================================================
  Total
------------------------------------------------------------------------------
  Time%                                  100.0% 
  Time                                 6.079316 secs
  Imb. Time                                  -- secs
  Imb. Time%                                 -- 
  Calls                  66.455 /sec      404.0 calls
  PAPI_L2_DCM             0.062M/sec    378,368 misses
  PAPI_L2_ICM             0.051M/sec    310,119 misses
  PAPI_L2_DCH             0.001G/sec  6,453,273 hits
  PAPI_L2_DCR             0.001G/sec  6,929,521 ops
  Average Time per Call                0.015048 secs
  CrayPat Overhead : Time  0.0%
  ...
```

## Further Readings

- [NESRC CrayPat documentation](https://docs.nersc.gov/tools/performance/craypat/)
- [NERSC prepared detailed tutorial on Cray's perftools](https://www.nersc.gov/assets/Uploads/05-craypat-reveal-20170609.pdf)
- [Cray XC Series Application Programming and Optimization](https://www.nersc.gov/assets/Uploads/TR-CPO-NERSC-20190211-2.pdf)
- [NERSC PerformanceTools](https://www.nersc.gov/assets/Uploads/PerformanceTools.pdf)
