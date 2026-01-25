#!/bin/bash
set -e  # Exit on error

# Configuration
REPO_DIR="/home/jovyan/LLMs4OL"
OPENAI_KEY_CHECK=${OPENAI_API_KEY:-"NOT_SET"}

echo "========================================================"
echo "Starting Setup Pipeline"
echo "========================================================"

# Check for API Key
# if [ "$OPENAI_KEY_CHECK" == "NOT_SET" ]; then
#     echo "ERROR: OPENAI_API_KEY is not set!"
#     echo "Please pass it when running docker: -e OPENAI_API_KEY='sk-...'"
#     exit 1
# fi

# Go to the Repo Directory
if [ ! -d "$REPO_DIR" ]; then
    echo "ERROR: Repository not found at $REPO_DIR."
    echo "Make sure you are running the correct Docker image."
    exit 1
fi
cd "$REPO_DIR"

# Prepare Task A Dataset - WN18RR
echo ">> Setting up Task A Dataset..."
# Ensure directory exists relative to REPO_DIR
mkdir -p datasets/TaskA/WN18RR/raw
cd datasets/TaskA/WN18RR/raw

if [ ! -f "WN18RR.tar.gz" ]; then
    echo "Downloading WN18RR..."
    wget -q -O WN18RR.tar.gz https://github.com/TimDettmers/ConvE/raw/master/WN18RR.tar.gz
    tar -xzf WN18RR.tar.gz
fi

# Return to root for python script
cd "$REPO_DIR"

echo ">> Converting dataset to JSON..."
python3 - <<'EOF'
import json
from pathlib import Path

# Paths relative to REPO_DIR
root = Path("datasets/TaskA/WN18RR")
raw = root / "raw"
if not raw.exists():
    raw = root / "raw_data"

out = root / "wn18rr_entities.json"
entities = set()

for split in ["train.txt", "valid.txt", "test.txt"]:
    p = raw / split
    if p.exists():
        with p.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line: continue
                parts = line.split("\t")
                if len(parts) < 3: parts = line.split()
                if len(parts) >= 3:
                    entities.add(parts[0])
                    entities.add(parts[2])

entities = sorted(entities)
with out.open("w", encoding="utf-8") as f:
    json.dump(
        {"test":[{"label":"NN","entity":e,"sentence":f"{e} is a concept in WordNet."} for e in entities]},
        f, indent=2
    )
print(f"OK: wrote {out} with {len(entities)} entities")
EOF

# Download BERT Model
TARGET_MODEL_DIR="assets/LLMs/bert-large-uncased"
if [ ! -f "$TARGET_MODEL_DIR/config.json" ]; then
    echo ">> Downloading BERT-large model..."
    mkdir -p "$TARGET_MODEL_DIR"
    
    python3 -W ignore - <<'EOF'
import os, warnings
from transformers import AutoTokenizer, AutoModelForMaskedLM, logging

warnings.filterwarnings("ignore")
logging.set_verbosity_error()

name = "bert-large-uncased"
out = "assets/LLMs/bert-large-uncased"

print(f"Downloading {name} to {out}...")
tok = AutoTokenizer.from_pretrained(name)
mdl = AutoModelForMaskedLM.from_pretrained(name)
tok.save_pretrained(out)
mdl.save_pretrained(out)
print("Download complete.")
EOF
else
    echo ">> BERT model already exists. Skipping download."
fi
