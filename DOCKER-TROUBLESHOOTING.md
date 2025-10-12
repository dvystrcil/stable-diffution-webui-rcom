# Docker Setup and Troubleshooting

## Current Issue: Docker Permission Denied

You're seeing a permission denied error because your user needs proper access to the Docker daemon. Here are several ways to fix this:

## Solution 1: Apply Docker Group Changes (Recommended)

The user was added to the docker group, but the changes haven't taken effect yet. Try one of these:

### Option A: Log out and back in
```bash
# Log out of your session and log back in
# This is the most reliable way to apply group changes
```

### Option B: Use newgrp command
```bash
newgrp docker
docker-compose up --build
```

### Option C: Start a new shell session
```bash
su - $USER
cd /home/dan/Code/stable-diffution-rcom
docker-compose up --build
```

## Solution 2: Verify Docker Group Membership

Check if you're properly in the docker group:

```bash
# Check current groups
groups

# Check if docker group exists and you're in it
getent group docker

# Re-add yourself to docker group if needed
sudo usermod -aG docker $USER
```

## Solution 3: Temporary Workaround (Use sudo)

If you need to test immediately, you can use sudo:

```bash
sudo docker-compose up --build
```

**Note**: Using sudo with Docker can create files owned by root, which may cause permission issues later.

## Solution 4: Restart Docker Service

Sometimes restarting the Docker service helps:

```bash
sudo systemctl restart docker
```

## Solution 5: Check Docker Socket Permissions

Verify the Docker socket permissions:

```bash
ls -la /var/run/docker.sock
# Should show: srw-rw---- 1 root docker

# If permissions are wrong, fix them:
sudo chmod 666 /var/run/docker.sock
```

## Recommended Steps to Try (in order):

1. **First, try logging out and back in** (most reliable)
2. **Or use newgrp docker** and then run docker-compose
3. **Verify you're in the docker group** with `groups`
4. **If still failing, restart Docker** with `sudo systemctl restart docker`

## Testing Docker Access

Once you think it's fixed, test with:

```bash
# Test basic Docker access
docker --version
docker info

# Test Docker Compose
docker-compose --version

# Test running a simple container
docker run hello-world
```

## After Docker Works

Once Docker permissions are fixed, you can run:

```bash
docker-compose up --build
```

This will:
1. Build the Stable Diffusion WebUI Docker image
2. Download the ROCm base image (~4GB)
3. Clone the Stable Diffusion WebUI repository
4. Set up the environment
5. Start the application on port 7860

**Note**: The first build will take several minutes as it downloads the large base image and sets up the environment.

## Expected Build Process

1. **Downloading base image** - ROCm PyTorch image (~4GB)
2. **Cloning source code** - Stable Diffusion WebUI repository
3. **Installing dependencies** - System packages and Python dependencies
4. **Starting application** - WebUI will start on port 7860

The application will be available at: http://localhost:7860

## Troubleshooting Build Issues

If the build fails:

1. **Check available disk space**: `df -h`
2. **Check Docker logs**: `docker-compose logs`
3. **Clean up old images**: `docker system prune`
4. **Try building with more verbose output**: `docker-compose up --build --verbose`