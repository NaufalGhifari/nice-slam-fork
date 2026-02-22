import os
# 🚨 1. KILL CPU THREAD HOARDING & FRAGMENTATION 🚨
os.environ['OMP_NUM_THREADS'] = "1"
os.environ['MKL_NUM_THREADS'] = "1"
os.environ['OPENBLAS_NUM_THREADS'] = "1"
os.environ['MALLOC_ARENA_MAX'] = "2" # Forces Linux to aggressively free RAM

import argparse
import random
import numpy as np
import torch
import torch.multiprocessing as mp

torch.set_num_threads(1)

try:
    mp.set_start_method('spawn', force=True)
except RuntimeError:
    pass

from src import config
from src.NICE_SLAM import NICE_SLAM

def setup_seed(seed):
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    np.random.seed(seed)
    random.seed(seed)
    torch.backends.cudnn.deterministic = True

def main():
    parser = argparse.ArgumentParser(description='Arguments for running the NICE-SLAM/iMAP*.')
    parser.add_argument('config', type=str, help='Path to config file.')
    parser.add_argument('--input_folder', type=str, help='input folder')
    parser.add_argument('--output', type=str, help='output folder')
    nice_parser = parser.add_mutually_exclusive_group(required=False)
    nice_parser.add_argument('--nice', dest='nice', action='store_true')
    nice_parser.add_argument('--imap', dest='nice', action='store_false')
    parser.set_defaults(nice=True)
    args = parser.parse_args()

    cfg = config.load_config(
        args.config, 'configs/nice_slam.yaml' if args.nice else 'configs/imap.yaml')

    # ==========================================
    # 🚨 BULLETPROOF OVERRIDES (NO MORE SILENT SKIPS) 🚨
    # ==========================================
    try:
        cfg['cam']['num_workers'] = 0
    except: pass

    try:
        cfg['dataset']['num_workers'] = 0
    except: pass
        
    try:
        cfg['mapping']['no_log_on_first_frame'] = False
        cfg['mapping']['iters_first'] = 500
        cfg['mapping']['pixels'] = 1000
        
        # 🧠 The Amnesia Protocol: Stop the memory staircase!
        cfg['mapping']['mapping_window_size'] = 2 
        cfg['mapping']['keyframe_every'] = 50   # ONLY cache memory every 50 frames
        cfg['mapping']['every_frame'] = 50      # ONLY run heavy mapping every 50 frames
        cfg['mapping']['BA'] = False            # Kill Bundle Adjustment RAM hoarding
    except Exception as e:
        print(f"⚠️ Mapping override failed: {e}")

    try:
        cfg['tracking']['no_log_on_first_frame'] = False
        cfg['tracking']['pixels'] = 1000
    except: pass
        
    cfg['verbose'] = True
    cfg['low_gpu_mem'] = False 
    # ==========================================

    print("✅ Bulletproof Anti-Hoarding Protocol Injected!")

    slam = NICE_SLAM(cfg, args)
    slam.run()

if __name__ == '__main__':
    main()