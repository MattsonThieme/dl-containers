#!/bin/bash
# To run: sudo singularity exec -B /home/,/usr/ openvino.simg bash run_openvino_demo.sh 

cd /home/bduser/intel/computer_vision_sdk_2018.3.343/deployment_tools/demo/
bash demo_resnet50_download_convert_run.sh
