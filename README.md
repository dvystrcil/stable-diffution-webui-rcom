# Stable Diffusion WebUI Docker Application

This repository contains a containerized version of [AUTOMATIC1111's Stable Diffusion WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) designed to run on Kubernetes with ROCm support.

## Overview

- **Base Image**: `rocm/pytorch:rocm7.0.2_ubuntu24.04_py3.12_pytorch_release_2.8.0`
- **Default Tag**: `v1.10.1`
- **Exposed Port**: `7860`
- **Runtime**: Kubernetes deployment with GitHub Actions CI/CD

## Architecture

This application uses a multi-stage Docker build:

1. **Source Stage**: Clones the Stable Diffusion WebUI repository using a specified git tag
2. **Application Stage**: Sets up the runtime environment with ROCm support and required dependencies

## Quick Start

### Prerequisites

- Kubernetes cluster
- Docker registry access (GitHub Container Registry by default)
- kubectl configured for your cluster

### 1. Build and Deploy

#### Option A: Using GitHub Actions (Recommended)

1. Fork this repository
2. Update the image reference in `k8s/deployment.yaml`:
   ```yaml
   image: ghcr.io/YOUR-USERNAME/stable-diffution-rcom:latest
   ```
3. Push to main branch - GitHub Actions will automatically build and push the image

#### Option B: Manual Build

```bash
# Build the Docker image
docker build -t stable-diffusion-webui:latest .

# Build with a specific Stable Diffusion tag
docker build --build-arg STABLE_DIFFUSION_TAG=v1.10.1 -t stable-diffusion-webui:v1.10.1 .

# Tag and push to your registry
docker tag stable-diffusion-webui:latest your-registry/stable-diffusion-webui:latest
docker push your-registry/stable-diffusion-webui:latest
```

### 2. Deploy to Kubernetes

```bash
# Update the image reference in k8s/deployment.yaml first
kubectl apply -f k8s/deployment.yaml
```

### 3. Access the Application

#### Port Forward (for testing):
```bash
kubectl port-forward service/stable-diffusion-webui-service 7860:80
```
Then access http://localhost:7860

#### Ingress (for production):
Update the host in `k8s/deployment.yaml` and ensure you have an ingress controller installed.

## Configuration

### Environment Variables

- `COMMANDLINE_ARGS`: Arguments passed to webui.sh (default: "--listen --port 7860")
- `STABLE_DIFFUSION_TAG`: Git tag to clone (build-time argument, default: "v1.10.1")

### Resource Requirements

The default Kubernetes deployment requests:
- **CPU**: 1 core (limit: 2 cores)
- **Memory**: 4Gi (limit: 8Gi)

Adjust these in `k8s/deployment.yaml` based on your needs.

## Development

### Local Testing

```bash
# Run locally for testing
docker run -p 7860:7860 stable-diffusion-webui:latest

# Run with custom arguments
docker run -p 7860:7860 -e COMMANDLINE_ARGS="--listen --port 7860 --api" stable-diffusion-webui:latest
```

### Building with Different Tags

```bash
# Build with a different Stable Diffusion version
docker build --build-arg STABLE_DIFFUSION_TAG=v1.9.0 -t stable-diffusion-webui:v1.9.0 .
```

## GitHub Actions Workflow

The included workflow (`.github/workflows/docker-build.yml`) automatically:

1. Builds the Docker image on push to main/develop or PR
2. Pushes to GitHub Container Registry
3. Creates tags based on git refs and semantic versioning
4. Caches layers for faster builds

### Required Secrets

No additional secrets required - uses `GITHUB_TOKEN` automatically.

## Kubernetes Deployment Details

The deployment includes:

- **Deployment**: Single replica with health checks
- **Service**: ClusterIP service exposing port 80
- **Ingress**: Optional ingress for external access
- **Health Checks**: Readiness and liveness probes

### Scaling

To scale the deployment:

```bash
kubectl scale deployment stable-diffusion-webui --replicas=3
```

## Troubleshooting

### Common Issues

1. **Pod not starting**: Check logs with `kubectl logs deployment/stable-diffusion-webui`
2. **Out of memory**: Increase memory limits in deployment.yaml
3. **Slow startup**: Increase readiness probe initial delay

### Monitoring

```bash
# Check pod status
kubectl get pods -l app=stable-diffusion-webui

# View logs
kubectl logs -f deployment/stable-diffusion-webui

# Check resource usage
kubectl top pods -l app=stable-diffusion-webui
```

## Security Considerations

- The application runs as root by default (inherited from base image)
- Consider running with a non-root user in production
- Implement network policies to restrict access
- Use resource quotas to prevent resource exhaustion

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the provided Docker build
5. Submit a pull request

## License

This project follows the same license as the upstream Stable Diffusion WebUI project.

## Support

For issues related to:
- **Stable Diffusion WebUI**: See [AUTOMATIC1111/stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
- **This containerization**: Open an issue in this repository
- **ROCm support**: See [ROCm documentation](https://docs.amd.com/en/latest/)