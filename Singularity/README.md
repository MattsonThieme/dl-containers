# Intel Optimized Singularity Containers

This repo contains instructions for running custom scripts within Singularity containers optimized for execution on Intel Architecture. OpenMPI and Horovod facilitate multi-node and multi-worker training. 

## Cluster Requirements

Before use, Singularity must be installed on all nodes and its path added to the PATH variable in .bashrc. To install Singularity, run:

```
bash install_singularity.sh
```

OpenMPI must also be installed:

```
sudo yum install openmpi openmpi-devel
```

Once OpenMPI is installed and hosts.txt is updated, run `bash mpitest.sh` to verify connectivity.

The script to be run, as well as any data, must be stored in the same location on all nodes. 

## Run existi scripts within Intel Optimized Containers

When Singularity and OpenMPI have been installed, the run script must be edited to further customize the execution parameters.


## Run TF CNN Benchmarks with Intel Optimized Containers

Clone https://github.com/tensorflow/benchmarks.git into root directory
Update workspace in run_benchmark.sh

## Building custom containers
