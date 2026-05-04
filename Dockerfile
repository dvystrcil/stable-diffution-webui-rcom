ARG STABLE_DIFFUSION_TAG=v1.10.1
ARG ORAS_VERSION=1.2.2
ARG BASE_IMAGE=harbor-core.harbor.svc.cluster.local/dockerhub-proxy/rocm/pytorch:rocm7.0.2_ubuntu24.04_py3.12_pytorch_release_2.8.0

# ── Stage 1: source ──────────────────────────────────────────────────────────
FROM harbor-core.harbor.svc.cluster.local/dockerhub-proxy/alpine/git:latest AS source
ARG STABLE_DIFFUSION_TAG
WORKDIR /app
RUN git clone --depth 1 --branch ${STABLE_DIFFUSION_TAG} \
    https://github.com/AUTOMATIC1111/stable-diffusion-webui.git .

# ── Stage 2: wheel-builder (Rust available; output cached in Harbor) ─────────
# Builds only the packages that require Rust compilation. The full pip install
# still happens at runtime via webui.sh, but finds these wheels pre-built so
# no Rust compiler is needed in the final image or the init container.
FROM ${BASE_IMAGE} AS wheel-builder

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/* && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain stable --no-modify-path && \
    chmod -R a+rx /usr/local/rustup /usr/local/cargo

# Build tokenizers==0.13.4 wheel for Python 3.12.
# transformers==4.30.2 requires tokenizers<0.14; PyPI has no cp312 wheel
# for 0.13.4 (released before Python 3.12). --no-deps: only this wheel.
RUN pip wheel --no-deps "tokenizers==0.13.4" -w /wheels/

# ── Stage 3: final runtime (no Rust) ─────────────────────────────────────────
FROM ${BASE_IMAGE}
ARG ORAS_VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libgl1 wget git curl libtcmalloc-minimal4 python3.12-venv bc \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sL "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz" \
       | tar -xz -C /usr/local/bin oras

RUN git config --system --add safe.directory /app

WORKDIR /app

RUN chown 1000:1000 /app && chmod 755 /app

COPY --from=source --chown=1000:1000 /app .
COPY --from=wheel-builder /wheels /app/wheels

RUN chmod +x ./webui.sh

ENV PYTHONUNBUFFERED=1
ENV COMMANDLINE_ARGS="--listen --port 7860"
ENV LD_PRELOAD=/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4

EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:7860 || exit 1

USER 1000
CMD ["./webui.sh"]
