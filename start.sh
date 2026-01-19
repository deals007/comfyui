#!/usr/bin/env bash
set -euo pipefail

: "${PORT:=8000}"
: "${HF_HOME:=/tmp/hf}"

MODEL_DIR="/app/ComfyUI/models/checkpoints"
mkdir -p "${MODEL_DIR}" "${HF_HOME}"

MODEL_URL="https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/v7/Qwen-Rapid-AIO-NSFW-v7.1.safetensors?download=true"
MODEL_FILE="Qwen-Rapid-AIO-NSFW-v7.1.safetensors"
MODEL_PATH="${MODEL_DIR}/${MODEL_FILE}"
TMP_PATH="${MODEL_PATH}.part"

download_model () {
  if [ -f "${MODEL_PATH}" ]; then
    echo "Model already present: ${MODEL_PATH}"
    return 0
  fi

  echo "Downloading model in background..."
  echo "URL: ${MODEL_URL}"
  echo "TMP: ${TMP_PATH}"

  # resume download into .part
  wget -c --tries=50 --timeout=30 --waitretry=5 -O "${TMP_PATH}" "${MODEL_URL}"

  mv "${TMP_PATH}" "${MODEL_PATH}"
  echo "Download complete: ${MODEL_PATH}"
  ls -lh "${MODEL_DIR}"
  echo "NOTE: Refresh ComfyUI page (or restart service) to see the new checkpoint in dropdown."
}

# Start ComfyUI immediately so health checks pass
cd /app/ComfyUI
echo "Starting ComfyUI on 0.0.0.0:${PORT}"
python3 main.py --listen 0.0.0.0 --port "${PORT}" &
COMFY_PID=$!

# Download in background
download_model &

# Keep container running
wait "${COMFY_PID}"
