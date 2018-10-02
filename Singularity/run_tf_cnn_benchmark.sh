#!/bin/bash
# To run: bash run_user_script.sh <hostfile> <workers per node> <inter op threads>
# Note: The total number of workers deployed will be the number of workers per node * number of nodes

# Update the following variables to reflect your configuration
# By default, we run tf_cnn_benchmarks.py using synthetic data

PATH_TO_WORKSPACE="/root/"
PATH_TO_SCRIPT="/root/benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py"
PATH_TO_SINGULARITY="/root/singularity/bin/singularity"
PATH_TO_SIMG="/root/tf-hvd.simg"
HOSTFILE=hosts.txt
NUM_WORKERS_PER_NODE=2
NUM_INTER_THREADS=2

# Copy tf_cnn_benchmarks.py script to all nodes listed in hosts.txt
pssh -h hosts.txt  mkdir -p `pwd`
prsync -h hosts.txt ${PATH_TO_SCRIPT} `pwd`

# Calculate MPI execution parameters given workers/node, number of nodes, and core counts on each node

export physical_cores=`lscpu | grep "Core(s) per socket" | cut -d':' -f2 | xargs` # Total number of physical cores per socket
export num_nodes=`awk -F, '{print NF}' ${HOSTFILE} | head -1 `                # Number of nodes (addresses in hosts.txt must be comma separated on a single line)
export hostnames=$( cat ${HOSTFILE} )                                         # Hostnames from node_ips
export num_sockets=`lscpu | grep "Socket(s)" | cut -d':' -f2 | xargs`  # Number of sockets per node
export num_processes=$(( $num_nodes * $NUM_WORKERS_PER_NODE ))                # Total number of workers across all nodes
export ppr=$(( $NUM_WORKERS_PER_NODE / $num_sockets ))                        # Processes per resource
export pe=$(( $physical_cores / $ppr ))                                       # Cores per process
export num_threads=$(( ${ppr} * $physical_cores ))                            # Total number of physical cores on this machine

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

# Execute script
echo "TensorFlow CNN Benchmarks..."
echo "Running ${num_processes} processes across ${num_nodes} node(s)..."

mpirun --allow-run-as-root -np ${num_processes} --map-by ppr:${ppr}:socket:pe=${pe} -H ${hostnames} \
--report-bindings --oversubscribe -x LD_LIBRARY_PATH -x OMP_NUM_THREADS=${OMP_NUM_THREADS} sudo ${PATH_TO_SINGULARITY} \
exec -B ${PATH_TO_WORKSPACE} ${PATH_TO_SIMG} python ${PATH_TO_SCRIPT} $args \

