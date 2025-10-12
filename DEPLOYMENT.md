# Deployment Instructions

## Prerequisites

Before deploying this Stable Diffusion WebUI application, ensure you have:

- Kubernetes cluster with sufficient resources (minimum 4GB RAM per pod)
- kubectl configured to access your cluster
- Docker registry access (GitHub Container Registry recommended)
- Ingress controller installed (if using external access)

## Step-by-Step Deployment

### 1. Prepare Your Repository

1. **Fork or clone this repository**:
   ```bash
   git clone <your-repo-url>
   cd stable-diffution-rcom
   ```

2. **Update configuration**:
   - Edit `k8s/deployment.yaml` and replace `your-username` with your actual GitHub username:
     ```yaml
     image: ghcr.io/YOUR-USERNAME/stable-diffution-rcom:latest
     ```
   - Update the ingress host in `k8s/deployment.yaml`:
     ```yaml
     host: stable-diffusion.your-domain.com
     ```

### 2. Build and Push Docker Image

#### Option A: Automatic Build via GitHub Actions (Recommended)

1. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Initial setup"
   git push origin main
   ```

2. **Monitor the build**:
   - Go to your repository's "Actions" tab
   - Watch the "Build and Push Docker Image" workflow
   - Ensure it completes successfully

#### Option B: Manual Build

1. **Build locally**:
   ```bash
   docker build -t ghcr.io/YOUR-USERNAME/stable-diffution-rcom:latest .
   ```

2. **Login to GitHub Container Registry**:
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR-USERNAME --password-stdin
   ```

3. **Push the image**:
   ```bash
   docker push ghcr.io/YOUR-USERNAME/stable-diffution-rcom:latest
   ```

### 3. Deploy to Kubernetes

1. **Apply the deployment**:
   ```bash
   kubectl apply -f k8s/deployment.yaml
   ```

2. **Verify deployment**:
   ```bash
   # Check if pods are running
   kubectl get pods -l app=stable-diffusion-webui
   
   # Check deployment status
   kubectl get deployment stable-diffusion-webui
   
   # Check service
   kubectl get service stable-diffusion-webui-service
   ```

3. **Monitor pod startup** (this may take several minutes):
   ```bash
   kubectl logs -f deployment/stable-diffusion-webui
   ```

### 4. Access the Application

#### Option A: Port Forwarding (for testing)

```bash
kubectl port-forward service/stable-diffusion-webui-service 7860:80
```

Then open http://localhost:7860 in your browser.

#### Option B: Ingress (for production)

1. **Ensure ingress controller is installed**:
   ```bash
   # For NGINX Ingress Controller
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
   ```

2. **Check ingress status**:
   ```bash
   kubectl get ingress stable-diffusion-webui-ingress
   ```

3. **Access via your domain**:
   Navigate to `http://stable-diffusion.your-domain.com`

## Configuration Options

### Environment Variables

You can customize the application by modifying environment variables in `k8s/deployment.yaml`:

```yaml
env:
- name: COMMANDLINE_ARGS
  value: "--listen --port 7860 --api --cors-allow-origins=*"
```

Common options:
- `--api`: Enable API access
- `--cors-allow-origins=*`: Allow CORS from any origin
- `--share`: Create a public link (not recommended for production)
- `--xformers`: Use xformers for better performance

### Resource Scaling

Adjust resources based on your needs:

```yaml
resources:
  requests:
    memory: "8Gi"    # Increase for larger models
    cpu: "2000m"     # Increase for better performance
  limits:
    memory: "16Gi"
    cpu: "4000m"
```

### Horizontal Scaling

Scale the number of replicas:

```bash
kubectl scale deployment stable-diffusion-webui --replicas=3
```

## Troubleshooting

### Common Issues

1. **ImagePullBackOff Error**:
   ```bash
   # Check if image exists and is accessible
   kubectl describe pod <pod-name>
   
   # Verify image URL in deployment
   kubectl get deployment stable-diffusion-webui -o yaml | grep image:
   ```

2. **Pod Stuck in Pending**:
   ```bash
   # Check resource availability
   kubectl describe pod <pod-name>
   kubectl top nodes
   ```

3. **Application Not Starting**:
   ```bash
   # Check application logs
   kubectl logs deployment/stable-diffusion-webui
   
   # Check events
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

4. **Out of Memory**:
   ```bash
   # Increase memory limits
   kubectl patch deployment stable-diffusion-webui -p '{"spec":{"template":{"spec":{"containers":[{"name":"stable-diffusion-webui","resources":{"limits":{"memory":"16Gi"}}}]}}}}'
   ```

### Health Checks

Monitor application health:

```bash
# Check readiness
kubectl get pods -l app=stable-diffusion-webui

# Test health endpoint manually
kubectl exec -it deployment/stable-diffusion-webui -- curl http://localhost:7860
```

## Production Considerations

### Security

1. **Network Policies**:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: stable-diffusion-netpol
   spec:
     podSelector:
       matchLabels:
         app: stable-diffusion-webui
     policyTypes:
     - Ingress
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             name: ingress-nginx
   ```

2. **Resource Quotas**:
   ```yaml
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: stable-diffusion-quota
   spec:
     hard:
       requests.memory: "32Gi"
       requests.cpu: "8"
       limits.memory: "64Gi"
       limits.cpu: "16"
   ```

### Monitoring

1. **Add monitoring labels**:
   ```yaml
   metadata:
     labels:
       app: stable-diffusion-webui
       monitoring: "true"
   ```

2. **Prometheus metrics** (if available):
   ```yaml
   annotations:
     prometheus.io/scrape: "true"
     prometheus.io/port: "7860"
     prometheus.io/path: "/metrics"
   ```

### Persistence

For model storage persistence:

```yaml
spec:
  template:
    spec:
      volumes:
      - name: models-storage
        persistentVolumeClaim:
          claimName: stable-diffusion-models
      containers:
      - name: stable-diffusion-webui
        volumeMounts:
        - name: models-storage
          mountPath: /app/models
```

## Cleanup

To remove the deployment:

```bash
kubectl delete -f k8s/deployment.yaml
```

## Next Steps

1. **Set up monitoring** with Prometheus/Grafana
2. **Configure persistent storage** for models
3. **Implement backup strategies** for generated content
4. **Set up alerting** for application health
5. **Configure auto-scaling** based on load

## Support

- Check the main [README.md](README.md) for general information
- Review logs: `kubectl logs deployment/stable-diffusion-webui`
- Check Kubernetes events: `kubectl get events`
- Consult the [Stable Diffusion WebUI documentation](https://github.com/AUTOMATIC1111/stable-diffusion-webui)