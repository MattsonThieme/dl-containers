# Intel Optimized Singularity Containers

This repository contains code and instructions for running custom scripts within Singularity containers optimized for execution on Intel Architecture. OpenMPI and Horovod libraries facilitate multi-node and multi-worker training. 

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

## Run TF CNN Benchmarks with Intel Optimized Containers

With MPI configured, clone https://github.com/tensorflow/benchmarks.git into the root directory, then update the following variables in `run_tf_cnn_benchmark.sh`:

```
# Update the following variables to reflect your configuration
# By default, we run tf_cnn_benchmarks.py using synthetic data

PATH_TO_WORKSPACE="/root/"
PATH_TO_SCRIPT="/root/benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py"
PATH_TO_SINGULARITY="/root/singularity/bin/singularity"
PATH_TO_SIMG="/root/tf-hvd.simg"
HOSTFILE=hosts.txt
NUM_WORKERS_PER_NODE=2
NUM_INTER_THREADS=2
```
Additionally, the arguments passed to `tf_cnn_benchmarks.py` can be edited in `run_tf_cnn_benchmark.sh` via:

```
# TF CNN Benchmark arguments
args=" \
--batch_size=64 \
--model=resnet50 \
--num_intra_threads $num_threads \
--num_inter_threads $NUM_INTER_THREADS \
--display_every 5 \
--data_format NHWC \
--optimizer momentum \
--forward_only False \  # Switch to True for inference
--device cpu"
```

Once these are updated, run `bash run_tf_cnn_benchmark.sh` to initiate training.

## Run custom scripts with Intel Optimized Containers

As with `tf_cnn_benchmark.sh`, to run a custom script within the container, edit the run script `run_user_script.sh`:

```
# Update the following variables to reflect your configuration
# The workspace directory should contain both data and code

PATH_TO_WORKSPACE="/root/"
PATH_TO_SCRIPT="/root/topologies/distributed_unet/Horovod/hvd_train.py"
PATH_TO_DATA="/root/data"
PATH_TO_SINGULARITY="/root/singularity/bin/singularity"
PATH_TO_SIMG="/root/tf-hvd.simg"

TF_LOGDIR=_multiworker
HOSTFILE=hosts.txt
NUM_WORKERS_PER_NODE=2
NUM_INTER_THREADS=2
```
Data and the run script must be kept in identical locations on each node. 

Once `run_user_script.sh` has been updated and all the data and scripts are in identical locations on each node, execute with `bash run_user_script.sh`. 

## Building custom containers

To build a custom container, begin by editing `template.singularity`. In this file, are sections which define the container to be built.   

```
%post

  # Commands in the %post section are executed within the container after the base OS has been
  # installed at build time. This section will contain the majority of the setup, including 
  # installing software and libraries.

%setup

  # Commands in the %setup section are executed on the host system outside of the container after
  # the base OS has been installed.

%environment

  # Add environment variables in the %environment section. Note that these environment variables 
  # are sourced at runtime and not at build time, meaning that if the same variables are needed 
  # during build time (i.e. proxies), these should also be defined in the %post section.
```

Once template.singularity has been edited to include all the desired packages, environment settings, and runscript instructions, build a new container `custom_container.simg` with the following command:

```
sudo singularity build custom_container.simg template.singularity
```

Note that this will create a read only container. If writable containers are desired, the `--writable` or `--sandbox` flags may be passed to the build command:

```
sudo singularity build --writable custom_container.simg template.singularity
```

Please refer to the [Singularity documentation](https://www.sylabs.io/guides/2.6/user-guide/container_recipes.html) for any additional questions.
