#!/bin/bash

PATH_TO_SINGULARITY="/root/singularity/bin/singularity"
PATH_TO_SIMG="/root/tf-hvd.simg"
SING_EXEC_CMD="sudo ${PATH_TO_SINGULARITY} exec ${PATH_TO_SIMG}" 
PATH_TO_SCRIPT="/root/topologies/distributed_unet/Horovod/hvd_train.py"
PATH_TO_DATA="/root/data"
OMP_NUM_THREADS=22
HOSTNAMES="10.228.197.143,10.228.197.144,10.228.197.145,10.228.197.146"

logdir=${1:-_multiworker}     # Default suffix is _multiworker
node_ips=${2:-hosts.txt}      # Default is the hosts.txt file

export num_workers_per_node=${3:-2}  # Default 2 workers per node
export num_inter_threads=${4:-2} # Default to 2 inter_op threads

export physical_cores=`lscpu | grep "Core(s) per socket" | cut -d':' -f2 | sed "s/ //g"` # Total number of physical cores per socket
export num_nodes=`awk -F, '{print NF}' ${node_ips} | head -1 ` # Hosts.txt should contain IP addresses separated by commas
export num_sockets=`lscpu | grep "Socket(s)" | cut -d':' -f2 | sed "s/ //g"`   # Number of sockets per node
export logical_cores=`nproc`

export num_processes=$(( $num_nodes * $num_workers_per_node )) # Total number of workers across all nodes
export ppr=$(( $num_workers_per_node / $num_sockets ))
export pe=$(( $physical_cores / $ppr ))

export physical_cores=`lscpu | grep "Core(s) per socket" | cut -d':' -f2 | sed "s/ //g"` # Total number of physical cores per socket
export num_threads=$(( ${ppr} * $physical_cores )) # Total number of physical cores on this machine

echo "Executing training.."
echo "Running ${num_processes} processes with ${ppr} ppr"

mpirun --allow-run-as-root -np 4 --map-by ppr:${ppr}:socket:pe=${OMP_NUM_THREADS} -H ${HOSTNAMES} \
--report-bindings --oversubscribe -x LD_LIBRARY_PATH -x OMP_NUM_THREADS=${OMP_NUM_THREADS} sudo ${PATH_TO_SINGULARITY} \
exec -B ${PATH_TO_DATA} ${PATH_TO_SIMG} python ${PATH_TO_SCRIPT} --datadir=${PATH_TO_DATA} \
--logdir="tensorboard${1}" --num_inter_threads=${num_inter_threads} --num_threads=$num_threads

