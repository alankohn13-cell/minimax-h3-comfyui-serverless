FROM runpod/worker-comfyui:5.8.6-base

# Pin ComfyUI to v0.30.1 (native MiniMax H3 nodes land in 0.30.0; verified in comfy_extras/nodes_minimax_h3.py)
RUN cd /comfyui && git fetch --depth 1 origin refs/tags/v0.30.1 && git checkout FETCH_HEAD && \
    /comfyui/.venv/bin/pip install --no-cache-dir -r requirements.txt

# Weights are NOT baked here: 42.5GB of layers makes buildkit's export step need
# 2x that on disk, which no GHA runner survives. The workflow instead builds this
# slim "code" image, then streams each weight file onto it as an image layer with
# `crane append` (single-copy disk usage). See .github/workflows/build.yml.
RUN mkdir -p /comfyui/models/diffusion_models /comfyui/models/text_encoders /comfyui/models/vae
