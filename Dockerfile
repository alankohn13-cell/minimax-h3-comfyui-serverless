FROM runpod/worker-comfyui:5.8.6-base

# Pin ComfyUI to v0.30.1 (native MiniMax H3 nodes land in 0.30.0; verified in comfy_extras/nodes_minimax_h3.py)
# CRITICAL: the runtime venv is /opt/venv (see PATH in the base image env) — NOT /comfyui/.venv,
# which also exists but is dead weight. Installing requirements into the wrong venv leaves the
# runtime on the base image's June-era comfy-kitchen, whose tensor module lacks the INT8/ConvRot
# layout classes → quant_ops silently falls back → "'NoneType' object has no attribute 'Params'".
RUN cd /comfyui && git fetch --depth 1 origin refs/tags/v0.30.1 && git checkout FETCH_HEAD && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Stay on the base image's cu126 torch: RunPod's H100/H200 fleet runs driver 570.x
# (CUDA 12.8) and cu130 torch cannot even initialize there (verified on a live H200:
# "The NVIDIA driver on your system is too old"). comfy-kitchen's CUDA backend stays
# unavailable under cu126 (ComfyUI disables it for < 13.0) — inference runs on the
# eager backend, which implements all int8_convrot / nvfp4 ops needed by H3.

# Weights are NOT baked here: 42.5GB of layers makes buildkit's export step need
# 2x that on disk, which no GHA runner survives. The workflow instead builds this
# slim "code" image, then streams each weight file onto it as an image layer with
# `crane append` (single-copy disk usage). See .github/workflows/build.yml.
RUN mkdir -p /comfyui/models/diffusion_models /comfyui/models/text_encoders /comfyui/models/vae
