# Multi-stage Dockerfile for Stable Diffusion WebUI
ARG STABLE_DIFFUSION_TAG=v1.10.1

# Stage 1: Fetch source code (lightweight build)
FROM alpine/git:latest AS source
ARG STABLE_DIFFUSION_TAG
WORKDIR /app
RUN git clone --depth 1 --branch ${STABLE_DIFFUSION_TAG} https://github.com/AUTOMATIC1111/stable-diffusion-webui.git .

# Stage 2: Production image with ROCm/PyTorch
FROM rocm/pytorch:rocm7.0.2_ubuntu24.04_py3.12_pytorch_release_2.8.0

# Install system dependencies in a single layer, skip recommends to save space
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libgl1 \
    wget \
    git \
    curl \
    libtcmalloc-minimal4 \
    python3.12-venv \
    bc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy source code and set ownership in a single step
COPY --from=source --chown=1000:1000 /app .
RUN git config --global --add safe.directory /app
RUN chmod +x ./webui.sh

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV COMMANDLINE_ARGS="--listen --port 7860"

EXPOSE 7860

# Healthcheck for container orchestration (K8s/ArgoCD)
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:7860 || exit 1

USER 1000
CMD ["./webui.sh"]
