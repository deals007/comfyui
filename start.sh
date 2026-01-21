#!/usr/bin/env bash
set -euo pipefail

: "${PORT:=8000}"
: "${HF_HOME:=/tmp/hf}"

MODEL_DIR="/app/ComfyUI/models/checkpoints"
mkdir -p "${MODEL_DIR}" "${HF_HOME}"

MODEL_URL="https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/v7/Qwen-Rapid-AIO-NSFW-v7.1.safetensors?download=true"
MODEL_FILE="Qwen-Rapid-AIO-NSFW-v7.1.safetensors"
MODEL_PATH="${MODEL_DIR}/${MODEL_FILE}"
PART_PATH="${MODEL_PATH}.part"
LOCK_PATH="${MODEL_PATH}.lock"

download_model () {
  # If final model exists, do nothing
  if [ -s "${MODEL_PATH}" ]; then
    echo "Model already present: ${MODEL_PATH}"
    return 0
  fi

  # Prevent multiple parallel downloads on restarts
  if [ -f "${LOCK_PATH}" ]; then
    echo "Download lock exists (${LOCK_PATH}). Assuming download is/was in progress."
    # If .part exists, we try to resume it
  else
    date > "${LOCK_PATH}"
  fi

  echo "Downloading/resuming model..."
  echo "URL:  ${MODEL_URL}"
  echo "PART: ${PART_PATH}"

  # Resume download into .part (works if it already exists)
  wget -c --tries=50 --timeout=30 --waitretry=5 -O "${PART_PATH}" "${MODEL_URL}"

  # Only move into place if we actually got a non-empty file
  if [ -s "${PART_PATH}" ]; then
    mv -f "${PART_PATH}" "${MODEL_PATH}"
    rm -f "${LOCK_PATH}"
    echo "Download complete: ${MODEL_PATH}"
    ls -lh "${MODEL_DIR}"
  else
    echo "ERROR: Download produced empty part file. Leaving lock for debugging."
    exit 1
  fi
}

# Start ComfyUI immediately so health checks pass
cd /app/ComfyUI
echo "Starting ComfyUI on 0.0.0.0:${PORT}"
python3 main.py --listen 0.0.0.0 --port "${PORT}" &
COMFY_PID=$!

# Download in background
download_model &

wait "${COMFY_PID}"
