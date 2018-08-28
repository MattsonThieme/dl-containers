#!/bin/bash
# To test MPI connectivity, run: bash mpitest.sh
# This test places one worker on each socket which prints the local hostname

hostnames=$( cat hosts.txt )
num_nodes=`awk -F, '{print NF}' hosts.txt | head -1 `
num_sockets=`lscpu | grep "Socket(s)" | cut -d':' -f2 | sed "s/ //g"`
num_phys_cores=`lscpu | grep "Core(s) per socket" | cut -d':' -f2 | sed "s/ //g"`
num_processes=$(( $num_nodes * $num_sockets ))
proc_per_resource=1
num_cores_per_proc=$(( $num_phys_cores / $proc_per_resource ))

echo "Running $num_processes processes across $num_nodes nodes..."

mpirun --allow-run-as-root -np ${num_processes} --map-by ppr:${proc_per_resource}:socket:pe=${num_cores_per_proc} -H ${hostnames} \
--oversubscribe -x LD_LIBRARY_PATH hostname

