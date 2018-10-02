#!/bin/bash
# To run: bash run_user_script.sh
# Note: The total number of workers deployed will be the number of workers per node * number of nodes

# Update the following variables to reflect your configuration
# The workspace directory should contain both data and code

PATH_TO_WORKSPACE="/root/"
PATH_TO_SCRIPT="/root/topologies/distributed_unet/Horovod/hvd_train.py"
PATH_TO_DATA="/root/data"
PATH_TO_SINGULARITY="/root/singularity/bin/singularity"
PATH_TO_SIMG="/root/tf-hvd.simg"

# Copy updated script to all nodes listed in hosts.txt
pssh -h hosts.txt  mkdir -p `pwd`
prsync -h hosts.txt ${PATH_TO_SCRIPT} `pwd`

TF_LOGDIR=_multiworker
HOSTFILE=hosts.txt
NUM_WORKERS_PER_NODE=2
NUM_INTER_THREADS=2

# Calculate MPI execution parameters given workers/node, number of nodes, and core counts on each node

export physical_cores=`lscpu | grep "Core(s) per socket" | cut -d':' -f2 | sed "s/ //g"` # Total number of physical cores per socket
export num_nodes=`awk -F, '{print NF}' ${HOSTFILE} | head -1 `
export hostnames=$( cat ${HOSTFILE} )
export num_sockets=`lscpu | grep "Socket(s)" | cut -d':' -f2 | sed "s/ //g"`   # Number of sockets per node
export num_processes=$(( $num_nodes * $NUM_WORKERS_PER_NODE )) # Total number of workers across all nodes
export ppr=$(( $NUM_WORKERS_PER_NODE / $num_sockets ))  # Processes per resource
export pe=$(( $physical_cores / $ppr ))  # Cores per process
export num_threads=$(( ${ppr} * $physical_cores ))  # Total number of physical cores on this machine

# Execute script
echo "Running ${num_processes} processes across ${num_nodes} node(s)..."

mpirun --allow-run-as-root -np ${num_processes} --map-by ppr:${ppr}:socket:pe=${pe} -H ${hostnames} \
--report-bindings --oversubscribe -x LD_LIBRARY_PATH -x OMP_NUM_THREADS=${OMP_NUM_THREADS} sudo ${PATH_TO_SINGULARITY} \
exec -B ${PATH_TO_WORKSPACE} ${PATH_TO_SIMG} python ${PATH_TO_SCRIPT} --datadir=${PATH_TO_DATA} \
--logdir="tensorboard${TF_LOGDIR}" --num_inter_threads=${NUM_INTER_THREADS} --num_threads=$num_threads

