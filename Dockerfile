FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HOME=/tmp/hf \
    PORT=8000

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 python3-pip wget ca-certificates curl \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN python3 -m pip install --upgrade pip

RUN pip install --index-url https://download.pytorch.org/whl/cu121 \
    torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1

RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI
WORKDIR /app/ComfyUI
RUN pip install -r requirements.txt
RUN pip install accelerate safetensors huggingface-hub pillow einops

# Patch Qwen nodes
RUN wget -O /app/ComfyUI/comfy_extras/nodes_qwen.py \
  "https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/fixed-textencode-node/nodes_qwen.v2.py"

WORKDIR /app/ComfyUI/custom_nodes
RUN git clone https://github.com/rgthree/rgthree-comfy.git
RUN pip install -r /app/ComfyUI/custom_nodes/rgthree-comfy/requirements.txt || true

WORKDIR /app/ComfyUI
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8000
CMD ["/app/start.sh"]
