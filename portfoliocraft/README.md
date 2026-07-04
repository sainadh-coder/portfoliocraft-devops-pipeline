# PortfolioCraft

A Dockerized portfolio website deployed through a CI/CD pipeline (Jenkins → Docker → Kubernetes), with live monitoring via Graphite, Grafana and Nagios.

**Student:** Sainadh Hari · **Register No:** 24BCE8582 · **University:** VIT-AP
**Course:** IBM DevOps Engineering, 2026

---

## 1. Requirements

- Docker Desktop (with Docker Compose) installed and running
- PowerShell (built into Windows)
- Optional: Jenkins and `kubectl` + a local Kubernetes cluster (e.g. Docker Desktop's built-in Kubernetes, or Minikube) if you want to run the Jenkins pipeline / Kubernetes stages

---

## 2. Quick start (Docker Compose)

1. Open a terminal in this project folder.
2. Run the launcher:

   ```
   START_EVERYTHING.bat
   ```

   This stops any old containers, builds fresh images, starts everything with `docker compose up --build -d`, and waits 30 seconds for services to come up.

3. Open these URLs:

   | Service      | URL                          | Notes                    |
   |--------------|-------------------------------|---------------------------|
   | Website      | http://localhost:8080         | The portfolio site        |
   | Health check | http://localhost:8080/healthz | Returns `ok`               |
   | Graphite     | http://localhost:8090         | Metrics storage UI        |
   | Grafana      | http://localhost:3000         | Login: `admin` / `admin`  |
   | Nagios       | http://localhost:8081          | Login: `nagiosadmin` / `nagios` (default image credentials) |

4. In a **new** PowerShell window, start sending live metrics:

   ```
   powershell -ExecutionPolicy Bypass -File .\send_metrics.ps1
   ```

   This sends `portfolio.system.cpu_percent`, `portfolio.system.mem_percent`, `portfolio.app.http_up`, and `portfolio.app.response_time_ms` to Graphite's Carbon receiver (`localhost:2003`) every 10 seconds.

5. Open Grafana (http://localhost:3000) → the **PortfolioCraft — System & App Metrics** dashboard is already provisioned and will start populating once `send_metrics.ps1` is running.

---

## 3. Manual commands (if you don't want to use the .bat file)

```
docker compose down
docker compose up --build -d
```

To stop everything:

```
docker compose down
```

---

## 4. Kubernetes (optional stage)

```
docker build -t portfoliocraft:latest .
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl get pods
```

The site will then be reachable at `http://localhost:30080` on a cluster that exposes NodePorts on localhost (e.g. Docker Desktop Kubernetes).

---

## 5. Jenkins (optional stage)

Point a Jenkins Pipeline job at this repository — it will pick up the `Jenkinsfile` automatically and run:

1. **Checkout** – pulls the repo
2. **Build** – verifies site assets exist
3. **Test** – verifies `Dockerfile` and `nginx.conf` exist
4. **Docker Build** – builds the `portfoliocraft:latest` image
5. **Deploy** – runs `docker compose down` then `docker compose up --build -d`

Jenkins needs to run on (or have Docker access to) the same machine as Docker Desktop for the `bat` steps to work.

---

## 6. Project structure

```
src/index.html                                        Website (HTML + embedded CSS/JS, no external deps)
Dockerfile                                             nginx:alpine image definition
nginx.conf                                             nginx server config incl. /healthz
docker-compose.yml                                     portfolio + graphite + grafana + nagios
monitoring/graphite/storage-schemas.conf               Graphite retention policy for portfolio.* metrics
monitoring/grafana/provisioning/datasources/graphite.yml   Auto datasource → Graphite
monitoring/grafana/provisioning/dashboards/dashboard.yml   Dashboard provider config
monitoring/grafana/provisioning/dashboards/portfoliocraft.json  The 5-panel dashboard
monitoring/nagios/portfolio_website.cfg                Host + service checks
k8s/deployment.yaml                                    2-replica Deployment with health probes
k8s/service.yaml                                       NodePort Service (30080)
Jenkinsfile                                             5-stage declarative pipeline
send_metrics.ps1                                       PowerShell metrics sender (Windows)
START_EVERYTHING.bat                                   One-click stack launcher
```

---

## 7. Troubleshooting

- **Grafana shows "No data"** → make sure `send_metrics.ps1` is running; metrics only appear once they've been sent.
- **Port already in use** → another process is using 8080/8090/3000/8081; stop it or change the port mapping in `docker-compose.yml`.
- **Nagios login** → default image credentials are `nagiosadmin` / `nagios`; change them in production use.
- **Website looks unstyled** → this build has zero external font/CSS dependencies, so it should render identically online or fully offline in Docker.
