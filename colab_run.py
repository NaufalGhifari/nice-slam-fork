import argparse
import random
import numpy as np
import torch
import torch.multiprocessing as mp

# 1. Force Colab-safe multiprocessing
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
    # 🚨 COLAB SURVIVAL OVERRIDES (MANDATORY) 🚨
    # ==========================================
    # 1. Kill the RAM-spiking background workers
    if 'cam' in cfg:
        cfg['cam']['num_workers'] = 0
    if 'dataset' in cfg:
        cfg['dataset']['num_workers'] = 0
        
    # 2. Force the logs to prove it's iterating
    if 'mapping' in cfg:
        cfg['mapping']['no_log_on_first_frame'] = False
        cfg['mapping']['iters_first'] = 50 
        
    if 'tracking' in cfg:
        cfg['tracking']['no_log_on_first_frame'] = False
        
    cfg['verbose'] = True
    # ==========================================

    print("✅ Colab Survival Overrides Injected successfully!")

    slam = NICE_SLAM(cfg, args)
    slam.run()

if __name__ == '__main__':
    main()