#!/bin/bash
#SBATCH --job-name=nice_slam_tum_desk
#SBATCH --output=job_%j/out.txt
#SBATCH --error=job_%j/err.txt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8        # was 4; doubled to give DataLoader workers breathing room
#SBATCH --qos=1gpu
#SBATCH --partition=dgx1
#SBATCH --gpus=1
#SBATCH --mail-user=muhammad.naufal529@ui.ac.id
#SBATCH --mail-type=ALL

# Create per-job output directory
mkdir -p job_${SLURM_JOB_ID}

# ── GPU monitoring ────────────────────────────────────────────────────────────
nvidia-smi \
    --query-gpu=timestamp,utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu \
    --format=csv \
    -l 300 > job_${SLURM_JOB_ID}/gpu_usage.csv &
GPU_MONITOR_PID=$!

# ── Job start snapshot ────────────────────────────────────────────────────────
{
    echo "=== JOB START: $(date) ==="
    echo "Job ID : ${SLURM_JOB_ID}"
    echo "Node   : ${SLURM_NODELIST}"
    echo "CPUs   : ${SLURM_CPUS_PER_TASK}"
    nvidia-smi
} > job_${SLURM_JOB_ID}/gpu_summary.txt

# ── Main application ──────────────────────────────────────────────────────────
singularity exec --nv /srv/images/nvhpc_25.1-devel-cuda_multi-ubuntu24.04.sif bash -c "
    source /home/cluster-dgx1/naufalal/miniforge/etc/profile.d/conda.sh
    conda activate nice-slam-dgx
    cd /home/cluster-dgx1/naufalal/GitHub/nice-slam-fork

    time python -u -W ignore run.py configs/TUM_RGBD/freiburg1_desk.yaml
"
EXIT_CODE=$?

# ── Job end snapshot ──────────────────────────────────────────────────────────
{
    echo ""
    echo "=== JOB END: $(date) ==="
    echo "Exit code: ${EXIT_CODE}"
    nvidia-smi
} >> job_${SLURM_JOB_ID}/gpu_summary.txt

# Stop GPU monitor
kill $GPU_MONITOR_PID 2>/dev/null
wait $GPU_MONITOR_PID 2>/dev/null

# ── Slurm stats (collected after job steps are fully flushed) ─────────────────
# sacct needs a brief wait for the DB to register the final step
sleep 10

{
    echo "=== SLURM ACCOUNTING: $(date) ==="
    echo ""

    echo "--- seff ---"
    seff ${SLURM_JOB_ID}
    echo ""

    echo "--- sacct (timing + memory) ---"
    sacct -j ${SLURM_JOB_ID} \
        --format=JobID,JobName,Partition,AllocCPUS,State,ExitCode,Elapsed,ReqMem,MaxRSS,NodeList \
        --units=G
    echo ""

    echo "--- sacct (CPU + memory detail) ---"
    sacct -j ${SLURM_JOB_ID} \
        --format=JobID,CPUTime,CPUTimeRAW,AveCPU,AveRSS,MaxRSS,ElapsedRaw \
        --units=G

} > job_${SLURM_JOB_ID}/slurm_stats.txt

echo "All logs saved to: job_${SLURM_JOB_ID}/"
