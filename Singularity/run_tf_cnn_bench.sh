#!/bin/bash

PATH_TO_SINGULARITY="/root/singularity/bin/singularity"
PATH_TO_SIMG="/root/tf-unet.simg"
SING_EXEC_CMD="${PATH_TO_SINGULARITY} exec ${PATH_TO_SIMG}" 
PATH_TO_SIMG_TF_BENCH="/opt/benchmarks"
OMP_NUM_THREADS=6
HOSTNAMES="10.228.197.143,10.228.197.144,10.228.197.145,10.228.197.146"

args=" \
--batch_size=64 \
--model=resnet50 \
--num_intra_threads $OMP_NUM_THREADS \
--num_inter_threads 2 \
--display_every 5 \
--data_format NCHW \
--optimizer momentum \
--device cpu"

mpirun --allow-run-as-root -np 16 --map-by ppr:2:socket:pe=${OMP_NUM_THREADS} -H ${HOSTNAMES} \
--report-bindings --oversubscribe -x LD_LIBRARY_PATH -x OMP_NUM_THREADS=${OMP_NUM_THREADS} ${SING_EXEC_CMD} \
python ${PATH_TO_SIMG_TF_BENCH}/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py $args \
--mkl=true --variable_update horovod --horovod_device cpu --local_parameter_device cpu --kmp_blocktime=1
