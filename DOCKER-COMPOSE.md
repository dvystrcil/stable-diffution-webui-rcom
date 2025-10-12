# Docker Compose Development Environment

This Docker Compose setup allows you to quickly build and run the Stable Diffusion WebUI application locally for development and testing.

## Quick Start

### 1. Build and Run

```bash
# Build and start the application
docker-compose up --build

# Or run in detached mode
docker-compose up --build -d
```

### 2. Access the Application

Once running, access the web interface at: http://localhost:7860

### 3. Stop the Application

```bash
# Stop the application
docker-compose down

# Stop and remove volumes (clears persistent data)
docker-compose down -v
```

## Configuration

### Environment Variables

You can customize the application by modifying the `environment` section in `docker-compose.yml`:

```yaml
environment:
  - COMMANDLINE_ARGS=--listen --port 7860 --api --cors-allow-origins=*
```

Common options:
- `--api`: Enable API access
- `--cors-allow-origins=*`: Allow CORS from any origin
- `--share`: Create a public link (not recommended for development)
- `--xformers`: Use xformers for better performance
- `--no-half`: Disable half precision (if you encounter issues)

### Build Arguments

To use a different Stable Diffusion WebUI version, modify the build args:

```yaml
build:
  context: .
  dockerfile: Dockerfile
  args:
    STABLE_DIFFUSION_TAG: v1.9.0  # Change to desired version
```

### Persistent Storage

The compose file includes volume mounts for persistence:

- `./models`: Stores downloaded models
- `./outputs`: Stores generated images
- `./config`: Stores configuration files

These directories will be created automatically when you first run the application.

### GPU Support

#### For NVIDIA GPUs:

Uncomment the GPU section in docker-compose.yml:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

**Prerequisites:**
- NVIDIA Docker runtime installed
- nvidia-container-toolkit configured

#### For AMD GPUs (ROCm):

The base image already includes ROCm support. You may need to add device access:

```yaml
devices:
  - /dev/dri:/dev/dri
  - /dev/kfd:/dev/kfd
```

## Development Workflow

### 1. Make Changes to Dockerfile

After modifying the Dockerfile, rebuild:

```bash
docker-compose build --no-cache
docker-compose up
```

### 2. View Logs

```bash
# View logs in real-time
docker-compose logs -f

# View specific service logs
docker-compose logs -f stable-diffusion-webui
```

### 3. Execute Commands in Container

```bash
# Open a shell in the running container
docker-compose exec stable-diffusion-webui bash

# Run a one-off command
docker-compose exec stable-diffusion-webui ls -la /app
```

### 4. Debug Issues

```bash
# Check container status
docker-compose ps

# View detailed service information
docker-compose config

# Restart a specific service
docker-compose restart stable-diffusion-webui
```

## Useful Commands

### Build Only

```bash
docker-compose build
```

### Run Without Building

```bash
docker-compose up
```

### Pull Latest Base Images

```bash
docker-compose pull
```

### Clean Up

```bash
# Remove containers and networks
docker-compose down

# Remove containers, networks, and images
docker-compose down --rmi all

# Remove everything including volumes
docker-compose down --rmi all -v
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**:
   ```bash
   # Check what's using port 7860
   lsof -i :7860
   
   # Use a different port
   # Change ports section to: "8080:7860"
   ```

2. **Out of Memory**:
   Add memory limits to docker-compose.yml:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 8G
   ```

3. **Permission Issues with Volumes**:
   ```bash
   # Fix ownership of mounted volumes
   sudo chown -R $USER:$USER ./models ./outputs ./config
   ```

4. **Slow First Start**:
   The first run will download models and dependencies, which can take time.

### Performance Tips

1. **Use SSD storage** for volume mounts
2. **Allocate sufficient memory** (minimum 8GB recommended)
3. **Enable GPU support** if available
4. **Use `--no-half` flag** if you encounter precision issues

## Production Notes

This Docker Compose setup is intended for development and testing. For production deployment:

1. Use the Kubernetes manifests in `k8s/`
2. Implement proper secrets management
3. Use external storage for persistence
4. Set up monitoring and logging
5. Configure proper networking and security

## Next Steps

- Customize the `COMMANDLINE_ARGS` for your needs
- Set up persistent model storage
- Configure GPU acceleration
- Explore the Stable Diffusion WebUI features at http://localhost:7860