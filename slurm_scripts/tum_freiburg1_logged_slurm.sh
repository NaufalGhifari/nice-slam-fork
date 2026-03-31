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

# Log GPU metrics every 5 minutes
nvidia-smi --query-gpu=timestamp,utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu --format=csv -l 300 > gpu_usage_${SLURM_JOB_ID}.csv &
GPU_MONITOR_PID=$!

# Also log a summary at start and end
echo "=== JOB START: $(date) ===" > gpu_summary_${SLURM_JOB_ID}.txt
nvidia-smi >> gpu_summary_${SLURM_JOB_ID}.txt

# Run the main application
singularity exec --nv /srv/images/nvhpc_25.1-devel-cuda_multi-ubuntu24.04.sif bash -c "
        source /home/cluster-dgx1/naufalal/miniforge/etc/profile.d/conda.sh
        conda activate nice-slam-dgx
        cd /home/cluster-dgx1/naufalal/GitHub/nice-slam-fork

        time python -u -W ignore run.py configs/TUM_RGBD/freiburg1_desk.yaml
"

# Log final GPU state
echo "=== JOB END: $(date) ===" >> gpu_summary_${SLURM_JOB_ID}.txt
nvidia-smi >> gpu_summary_${SLURM_JOB_ID}.txt

# Kill monitoring
kill $GPU_MONITOR_PID
