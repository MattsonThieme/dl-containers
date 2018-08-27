#!/bin/bash
# To run: bash run_user_script.sh <hostfile> <workers per node> <inter op threads>
# Note: The total number of workers deployed will be the number of workers per node * number of nodes

if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` [<logdir>] [<hostfile>] [<workers per node>] [<inter op threads>]"
  echo "   where "
  echo "   [<hostfile>]  = File name for the node IP list (comma separated list)"
  echo "   [<workers per node>] = Number of workers per node"
  echo "   [<inter op threads>] = Number of inter-op-parallelism threads for TensorFlow"
  echo " "
  exit 0
fi

# Optional arguments (see help above)

logdir=${1:-_multiworker}     # Default suffix is _multiworker
node_ips=${2:-hosts.txt}      # Default is the hosts.txt file
num_workers_per_node=${3:-2}  # Default 2 workers per node
num_inter_threads=${4:-2}     # Default to 2 inter_op threads

# Update the following variables to reflect your configuration
# The workspace directory should contain both data and code
# By default, we run tf_cnn_benchmarks.py using synthetic data

PATH_TO_WORKSPACE="/root/"
PATH_TO_SCRIPT="/root/benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py"
PATH_TO_DATA="/root/data"
PATH_TO_SINGULARITY="/root/singularity/bin/singularity"
PATH_TO_SIMG="/root/tf-hvd.simg"

# Calculate MPI execution parameters given workers/node, number of nodes, and core counts on each node

export physical_cores=`lscpu | grep "Core(s) per socket" | cut -d':' -f2 | sed "s/ //g"` # Total number of physical cores per socket
export num_nodes=`awk -F, '{print NF}' ${node_ips} | head -1 `                # Number of nodes (addresses in hosts.txt must be comma separated on a single line)
export hostnames=$( cat ${node_ips} )                                         # Hostnames from node_ips
export num_sockets=`lscpu | grep "Socket(s)" | cut -d':' -f2 | sed "s/ //g"`  # Number of sockets per node
export num_processes=$(( $num_nodes * $num_workers_per_node ))                # Total number of workers across all nodes
export ppr=$(( $num_workers_per_node / $num_sockets ))                        # Processes per resource
export pe=$(( $physical_cores / $ppr ))                                       # Cores per process
export num_threads=$(( ${ppr} * $physical_cores ))                            # Total number of physical cores on this machine

# TF CNN Benchmark arguments
args=" \
--batch_size=64 \
--model=resnet50 \
--num_intra_threads $num_threads \
--num_inter_threads 2 \
--display_every 5 \
--data_format NCHW \
--optimizer momentum \
--device cpu"

# Execute script
echo "TensorFlow CNN Benchmarks..."
echo "Running ${num_processes} processes across ${num_nodes} node(s)..."

mpirun --allow-run-as-root -np ${num_processes} --map-by ppr:${ppr}:socket:pe=${pe} -H ${hostnames} \
--report-bindings --oversubscribe -x LD_LIBRARY_PATH -x OMP_NUM_THREADS=${OMP_NUM_THREADS} sudo ${PATH_TO_SINGULARITY} \
exec -B ${PATH_TO_WORKSPACE} ${PATH_TO_SIMG} python ${PATH_TO_SCRIPT} $args \

