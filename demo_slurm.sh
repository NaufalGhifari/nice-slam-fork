#!/bin/bash
#SBATCH --job-name=nice_slam_demo
#SBATCH --output=nice-out-%j.txt
#SBATCH --error=nice-err-%j.txt
#SBATCH --ntasks=1
#SBATCH --qos=1gpu
#SBATCH --partition=dgx1 
#SBATCH --gpus=1

singularity exec --nv /srv/images/nvhpc_25.1-devel-cuda_multi-ubuntu24.04.sif bash -c "
        source /home/cluster-dgx1/naufalal/miniforge/etc/profile.d/conda.sh
        conda activate nice-slam-dgx
        cd /home/cluster-dgx1/naufalal/GitHub/nice-slam-fork

        # Run the demo
        python -W ignore run.py configs/Demo/demo.yaml
"
