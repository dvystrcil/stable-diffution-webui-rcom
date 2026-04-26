# Multi-stage Dockerfile for Stable Diffusion WebUI
ARG STABLE_DIFFUSION_TAG=v1.10.1

# Stage 1: Source code stage
FROM alpine/git:latest AS source
ARG STABLE_DIFFUSION_TAG
WORKDIR /app
# Clone specific tag from repository (--branch works for tags too)
RUN git clone --depth 1 --branch ${STABLE_DIFFUSION_TAG} https://github.com/AUTOMATIC1111/stable-diffusion-webui.git . && \
    git describe --tags

# Stage 2: Final application stage
FROM rocm/pytorch:rocm7.0.2_ubuntu24.04_py3.12_pytorch_release_2.8.0

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    libgl1 \
    wget \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy source code from previous stage
COPY --from=source /app .

# Make webui.sh executable
RUN chmod +x ./webui.sh

# Expose port 7860
EXPOSE 7860

# Set environment variables for stable diffusion
ENV PYTHONUNBUFFERED=1
ENV COMMANDLINE_ARGS="--listen --port 7860"

RUN chown -R 1000:1000 /app 
USER 1000

# Run the application
CMD ["./webui.sh"]
