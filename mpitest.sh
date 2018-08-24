#!/bin/bash

HOSTNAMES="10.228.197.143,10.228.197.144,10.228.197.145,10.228.197.146"

mpirun --allow-run-as-root -np 8 --map-by ppr:1:socket:pe=6 -H ${HOSTNAMES} \
--oversubscribe -x LD_LIBRARY_PATH -x OMP_NUM_THREADS=6 echo "Hello from $(hostname)!"
