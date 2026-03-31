#!/bin/bash
#SBATCH --job-name=nice_slam_demo
#SBATCH --output=nice-out-%j.txt
#SBATCH --error=nice-err-%j.txt
#SBATCH --ntasks=1
#SBATCH --qos=1gpu
#SBATCH --partition=dgx1 
#SBATCH --gpus=1
#SBATCH --mail-user muhammad.naufal529@ui.ac.id 
#SBATCH --mail-type ALL

# Start GPU monitoring in background
nvidia-smi --query-gpu=timestamp,name,pci.bus_id,driver_version,pstate,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.used,memory.free,power.draw,power.limit --format=csv -l 5 > gpu_usage_${SLURM_JOB_ID}.csv &
GPU_MONITOR_PID=$!

singularity exec --nv /srv/images/nvhpc_25.1-devel-cuda_multi-ubuntu24.04.sif bash -c "
        source /home/cluster-dgx1/naufalal/miniforge/etc/profile.d/conda.sh
        conda activate nice-slam-dgx
        cd /home/cluster-dgx1/naufalal/GitHub/nice-slam-fork

        # Run
        time python -u -W ignore run.py configs/TUM_RGBD/freiburg1_desk.yaml
"

# Kill GPU monitoring process when main job finishes
kill $GPU_MONITOR_PID