# Use Nvidia CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install ComfyUI dependencies
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --no-cache-dir xformers==0.0.21 \
    && pip3 install -r requirements.txt

# Install runpod
RUN pip3 install runpod requests

#ARG SKIP_DEFAULT_MODELS
# Download checkpoints/vae/LoRA to include in image.
#RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/checkpoints/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors; fi
#RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/vae/sdxl_vae.safetensors https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors; fi
#RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/vae/sdxl-vae-fp16-fix.safetensors https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors; fi
#RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/loras/xl_more_art-full_v1.safetensors https://civitai.com/api/download/models/152309; fi

# Download additional custom nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git ./custom_nodes/ComfyUI-Impact-Pack
RUN git clone https://github.com/jags111/efficiency-nodes-comfyui.git ./custom_nodes/efficiency-nodes-comfyui
RUN git clone https://github.com/omar92/ComfyUI-QualityOfLifeSuit_Omar92.git ./custom_nodes/ComfyUI-QualityOfLifeSuit_Omar92
RUN git clone https://github.com/TinyTerra/ComfyUI_tinyterraNodes.git ./custom_nodes/ComfyUI_tinyterraNodes
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git ./custom_nodes/ComfyUI_Comfyroll_CustomNodes
RUN git clone https://github.com/wolfden/ComfyUi_PromptStylers.git ./custom_nodes/ComfyUi_PromptStylers
RUN git clone https://github.com/thedyze/save-image-extended-comfyui.git ./custom_nodes/save-image-extended-comfyui
RUN git clone https://github.com/palant/extended-saveimage-comfyui.git ./custom_nodes/extended-saveimage-comfyui
RUN git clone https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git ./custom_nodes/ComfyUI_JPS-Nodes

# Support for the network volume
ADD src/extra_model_paths.yaml ./

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
