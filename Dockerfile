FROM runpod/worker-comfyui:5.8.6-base

# Pin ComfyUI to v0.30.1 (native MiniMax H3 nodes land in 0.30.0; verified in comfy_extras/nodes_minimax_h3.py)
RUN cd /comfyui && git fetch --depth 1 origin refs/tags/v0.30.1 && git checkout FETCH_HEAD && \
    /comfyui/.venv/bin/pip install --no-cache-dir -r requirements.txt

# base image lacks curl -> install aria2 (fast parallel downloader)
RUN apt-get update && apt-get install -y --no-install-recommends aria2 ca-certificates && rm -rf /var/lib/apt/lists/*

# Bake MiniMax H3 pruned-int8 weights (the ComfyUI-recommended 42.5GB set) — one RUN per file (separate layers).
# fl2va covers text-to-video AND first/last-frame image-to-video; ref2va (another 21GB) is deliberately left out.
RUN mkdir -p /comfyui/models/diffusion_models /comfyui/models/text_encoders /comfyui/models/vae && \
    aria2c -x16 -s16 -k1M --dir=/comfyui/models/diffusion_models -o minimax_h3_fl2va_pruned_int8_convrot.safetensors \
      https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors
RUN aria2c -x16 -s16 -k1M --dir=/comfyui/models/text_encoders -o qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors \
      https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors
RUN aria2c -x16 -s16 -k1M --dir=/comfyui/models/vae -o minimax_h3_video_vae_fp16.safetensors \
      https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_fp16.safetensors
RUN aria2c -x16 -s16 -k1M --dir=/comfyui/models/vae -o minimax_h3_audio_vae_fp32.safetensors \
      https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors
