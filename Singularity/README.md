# Intel Optimized Singularity Containers

This repository contains code and instructions for running custom scripts within Singularity containers optimized for execution on Intel Architecture. OpenMPI and Horovod libraries facilitate multi-node and multi-worker training. 

Note: __All scripts are built for CentOS 7 and may require modifications (i.e. using apt in place of yum on Ubuntu) for other operating systems.__ 

## Configuring the environment

Single and multi-node environments must be configured slightly differently. Here, we describe the steps to setup such environments. If your environment is already configured, please see the [Execution](https://github.com/MattsonThieme/dl-containers/tree/master/Singularity#execution) section.

### Multi-Node

In addition to the libraries inside the Singularity container, multi-node execution requires communication libraries to be installed globally on each node. This section details the install such dependencies across the entire cluster.

1. Clone this repo on the head node by running:
   ```
   $ git clone https://github.com/MattsonThieme/dl-containers.git
   ``` 
2. Change directories into ~/dl-containers/Singularity/ :
   ```
   $ cd ~/dl-containers/Singularity
   ```
3. Modify hosts.txt to include all hosts in your cluster. List each IP on its own line:
   ```
   <node1_ip>
   <node2_ip>
   <node3_ip>
   <node4_ip>
   ...
   ...
   ```
4. Ensure that [passwordless ssh](https://www.tecmint.com/ssh-passwordless-login-using-ssh-keygen-in-5-easy-steps/) is enabled between all nodes and in all directions (i.e. node1 -> node2 _and_ node2 -> node1).
5. Configure all the servers with `setup_envs.sh`. This will install all necessary packages and configure each node identically.
   ```
   $ bash setup_envs.sh
   ```
   The `setup_envs.sh` script runs `config_env.sh` on each node. If your configuration requires additional packages to those described in `config_env.sh`, simply add them there and rerun `setup_envs.sh`.
6. **One time only, to verify connectivity between the nodes**, run `mpitest.sh`::
   ```
   $ bash mpitest.sh
   ```
   If MPI can communicate between all the nodes, the test will succeed and the script will print the hostnames of all the nodes in the network to stdout.

7. Build the default Singularity container with the following command (this will take a few minutes):
   ```
   $ sudo singularity build tensorflow.simg template.simg
   ```
   If you would like to build custom containers, please refer to the [Building custom containers](https://github.com/MattsonThieme/dl-containers/tree/master/Singularity#building-custom-containers) section below.

8. Copy the Singularity image to the same location on all nodes with pssh.
   ```
   $ pscp.pssh -h hosts.txt ~/dl-containers/Singularity/tensorflow.simg ~/dl-containers/Singularity/
   ```
   This will need to be performed each time a new container is built.

### Single-Node

1. Clone this repo on the head node by running
   ```
   $ git clone https://github.com/MattsonThieme/dl-containers.git
   ```
2. Configure local environment and install Singularity with `setup_envs.sh`.
   ```
   $ bash setup_envs.sh
   ```

--- IN PROGRESS ---

## Execution

Execution in single and multi-node environments also requires slightly different run commands. Namely, we initiate training in a multi-node setting with an `mpirun` call, whereas single node runs may be initiated by calling `sudo singularity exec ...` directly. This section details execution instructions for each case.

### Multi-Node

To run TensorFlow benchmarks:

1. Clone the [benchmarks repo](https://github.com/tensorflow/benchmarks.git) into the root directory, then update the following variables in `run_tf_cnn_benchmarks.sh`:

   ```
   ...
   # Update the following variables to reflect your configuration
   # The workspace directory should contain both data and code
   PATH_TO_WORKSPACE="/full/path/to/workspace/dir/"            # Usually set to /root/
   PATH_TO_SCRIPT="/full/path/to/tf_cnn_benchmarks.py"
   PATH_TO_SINGULARITY="/full/path/to/singularity/executable"  # Usually ~/singularity/bin/singularity
   PATH_TO_SIMG="/full/path/to/<your_image>.simg"
   HOSTFILE=hosts.txt
   NUM_WORKERS_PER_NODE=2                                      # Edit to increase or decrease # workers/node
   ...
   ```

   Optionally, the arguments passed to `tf_cnn_benchmarks.py` may be also be edited:

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

2. Execute the script with:

   ```
   $ bash run_tf_cnn_benchmark.sh
   ```

To run a custom script:

1. Edit `run_user_script.sh` to reflect the location of your script and data:

   ```
   ...
   # Update the following variables to reflect your configuration
   # The workspace directory should contain both data and code
   PATH_TO_WORKSPACE="/full/path/to/workspace/dir/"            # Contains any required data/code
   PATH_TO_SCRIPT="/full/path/to/script.py"
   PATH_TO_DATA="/full/path/to/data"
   PATH_TO_SINGULARITY="/full/path/to/singularity/executable"  # Usually ~/singularity/bin/singularity
   PATH_TO_SIMG="/full/path/to/<your_image>.simg"
   
   
   TF_LOGDIR=_multiworker
   HOSTFILE=hosts.txt
   NUM_WORKERS_PER_NODE=2
   ...
   ```

   Note: __Both data and the custom script must be in identical locations on each node__

2. Execute the script with:

   ```
   $ bash run_user_script.sh
   ```

### Single node

1. FIRST STEPS

   The `-B` flag specifies which directories to bind to the container during execution. Bind the workspace directory having all necessary data and code. 

   This will run the tf_cnn_benchmarks.py script on all nodes listed in hosts.txt.

2. To run custom scripts, edit the following variables in `run_user_script.sh` to reflect the locations of your script/data:
   ```
   ...
   # Update the following variables to reflect your configuration
   # The workspace directory should contain both data and code
   PATH_TO_WORKSPACE="/full/path/to/workspace/dir/"
   PATH_TO_SCRIPT="/full/path/to/script.py"
   PATH_TO_DATA="/full/path/to/data"
   PATH_TO_SINGULARITY="/full/path/to/singularity/executable"  # Usually ~/singularity/bin/singularity
   PATH_TO_SIMG="/full/path/to/<your_image>.simg"
   ...
   ```
   Then run:
   ```
   $ sudo singularity exec -B /req/directories/ <your_image>.simg bash run_user_script.sh
   ```

--- IN PROGRESS ---

## Building custom containers

To build a custom container, begin by editing `template.singularity`. This file contains sections which define the container to be built:   

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

%runscript

  # Any code here will be executed at runtime. When the %runscript is executed, all options are 
  # passed along to the executing script at runtime

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
