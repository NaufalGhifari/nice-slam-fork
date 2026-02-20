import sys

dependencies = [
    "torch", "numpy", "matplotlib", "PIL", "mathutils", 
    "open3d", "cv2", "trimesh", "tqdm", "yaml", "addict"
]

missing = []
for dep in dependencies:
    try:
        __import__(dep if dep != "cv2" else "cv2")
        print(f"✅ {dep} is installed.")
    except ImportError:
        print(f"❌ {dep} is MISSING!")
        missing.append(dep)

if missing:
    print(f"\nInstall the missing pieces: pip install {' '.join(missing)}")
    sys.exit(1)
else:
    print("\n🚀 All core dependencies are present. Ready to run NICE-SLAM.")