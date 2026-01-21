#!/usr/bin/env bash
set -euo pipefail

: "${PORT:=8000}"
: "${HF_HOME:=/tmp/hf}"

# -------------------
# Paths
# -------------------
CKPT_DIR="/app/ComfyUI/models/checkpoints"
IPAD_DIR="/app/ComfyUI/models/ipadapter"
CLIPV_DIR="/app/ComfyUI/models/clip_vision"

mkdir -p "${CKPT_DIR}" "${IPAD_DIR}" "${CLIPV_DIR}" "${HF_HOME}"

# -------------------
# Qwen Rapid AIO v7.1
# -------------------
QWEN_URL="https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/v7/Qwen-Rapid-AIO-NSFW-v7.1.safetensors?download=true"
QWEN_FILE="Qwen-Rapid-AIO-NSFW-v7.1.safetensors"
QWEN_PATH="${CKPT_DIR}/${QWEN_FILE}"
QWEN_TMP="${QWEN_PATH}.part"

# -------------------
# IP-Adapter FaceID
# (place in models/ipadapter)
# -------------------
# NOTE: choose ONE FaceID weight to start. This one is commonly used:
FACEID_URL="https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl.bin?download=true"
FACEID_FILE="ip-adapter-faceid-plusv2_sdxl.bin"
FACEID_PATH="${IPAD_DIR}/${FACEID_FILE}"
FACEID_TMP="${FACEID_PATH}.part"

# -------------------
# CLIP Vision
# (place in models/clip_vision)
# -------------------
CLIPV_URL="https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors?download=true"
CLIPV_FILE="CLIP-ViT-H-14.safetensors"
CLIPV_PATH="${CLIPV_DIR}/${CLIPV_FILE}"
CLIPV_TMP="${CLIPV_PATH}.part"

download_one () {
  local URL="$1"
  local OUT="$2"
  local TMP="$3"

  if [ -f "${OUT}" ]; then
    echo "Already present: ${OUT}"
    return 0
  fi

  echo "Downloading: ${OUT}"
  rm -f "${TMP}"
  wget -c --tries=50 --timeout=30 --waitretry=5 -O "${TMP}" "${URL}"
  mv "${TMP}" "${OUT}"
  echo "Done: ${OUT}"
}

download_models () {
  download_one "${QWEN_URL}"  "${QWEN_PATH}"  "${QWEN_TMP}"
  download_one "${FACEID_URL}" "${FACEID_PATH}" "${FACEID_TMP}"
  download_one "${CLIPV_URL}" "${CLIPV_PATH}" "${CLIPV_TMP}"

  echo "----- Model folders -----"
  ls -lh "${CKPT_DIR}" || true
  ls -lh "${IPAD_DIR}" || true
  ls -lh "${CLIPV_DIR}" || true
  echo "-------------------------"
  echo "If models finished downloading, refresh ComfyUI (or restart service) to see them in node dropdowns."
}

# Start ComfyUI immediately
cd /app/ComfyUI
echo "Starting ComfyUI on 0.0.0.0:${PORT}"
python3 main.py --listen 0.0.0.0 --port "${PORT}" &
COMFY_PID=$!

# Download in background
download_models &

wait "${COMFY_PID}"
