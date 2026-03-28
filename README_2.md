# todo-node-app — DevOps Setup

CI/CD pipeline, Docker, Terraform (AWS), and Prometheus + Grafana monitoring for the todo-node-app.

---

## How it all fits together

```
Merge PR to main
      │
      ▼
GitHub Actions
  test → build & push image to Docker Hub → deploy to EC2 via SSH
      │
      ▼
EC2 (provisioned by Terraform)
  ├── node_container   (todo app, port 8000)   ← pipeline updates this
  ├── prometheus       (port 9090)             ← runs independently
  ├── node-exporter    (port 9100)             ← host system metrics
  └── grafana          (port 3000)             ← dashboards
```

---

## Files

```
.github/workflows/cicd.yml      Pipeline: test → build → deploy
docker-compose.yaml             Prometheus + Node Exporter + Grafana (monitoring only)
monitoring/prometheus.yml       Scrape config
terraform/main.tf               VPC, EC2, S3, security groups
terraform/variables.tf          Region, SSH CIDR, key path
```

> The todo app is **not** in docker-compose. The pipeline deploys it directly via `docker run`. The compose file is only for the monitoring stack.

---

## 1. Provision Infrastructure (once)

```bash
cd terraform

terraform init

# Replace with your actual IP to restrict SSH access
terraform apply -var="ssh_cidr=$<value>)/32"

# Note the outputs
terraform output
```

**What gets created:** VPC, public subnet, internet gateway, security group (ports 22, 8000, 3000, 9090, 9100), EC2 t3.medium running Ubuntu 22.04, S3 bucket for artifacts.

> ⚠️ Use `t3.medium` or larger. The monitoring stack needs at least 2GB RAM.

---

## 2. Start Monitoring Stack on Server (once)

Copy files to the server, then start the monitoring containers:

```bash
# Copy compose and prometheus config
scp docker-compose.yaml ubuntu@SERVER_IP:/opt/app/
scp monitoring/prometheus.yml ubuntu@SERVER_IP:/opt/app/monitoring/

# SSH in and start only the monitoring stack
ssh ubuntu@SERVER_IP
cd /opt/app
docker compose up -d prometheus node-exporter grafana
```

The todo app (`node_container`) is deployed and managed entirely by the pipeline via `docker run` — not via compose. Never start it manually.

---

## 3. CI/CD Pipeline

**Trigger:** every merge (push) to `main` branch.

| Job | What it does |
|-----|-------------|
| Test | Runs `npm test` |
| Build & Push | Builds Docker image, pushes to Docker Hub with `latest` and `sha` tags |
| Deploy | SSHs into EC2, pulls new image, restarts `node_container` |

### GitHub Secrets required

Go to your repo → Settings → Secrets and variables → Actions → New repository secret.

| Secret | Value |
|--------|-------|
| `DOCKERHUB_USER` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token (not your password) |
| `SERVER_HOST` | EC2 public IP from `terraform output server_ip` |
| `SERVER_USER` | `ubuntu` |
| `SSH_PRIVATE_KEY` | Full contents of `~/.ssh/id_rsa` |

---

## 4. Monitoring

| Service | URL | Login |
|---------|-----|-------|
| Todo app | `http://SERVER_IP:8000` | — |
| Prometheus | `http://SERVER_IP:9090` | — |
| Grafana | `http://SERVER_IP:3000` | admin / admin123 |

### Grafana setup

1. Open `http://SERVER_IP:3000` → login with `admin / admin123`
2. Go to **Connections → Data sources → Add data source → Prometheus**
3. URL: `http://prometheus:9090` → click **Save & test**
4. Go to **Dashboards → Import** → enter ID `1860` → Load → Import
   - This gives you full CPU, memory, disk, and network charts from Node Exporter

### What Prometheus monitors by default

| Target | What it tracks |
|--------|---------------|
| `node-exporter:9100` | Host CPU, RAM, disk, network — full system metrics |
| `web:8000` | Whether the todo app is up or down |
| `localhost:9090` | Prometheus itself |

---

