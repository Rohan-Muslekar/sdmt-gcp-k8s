# Lab 3 Part 1: Docker and Kubernetes on GKE

ENGR 5520G / SOFE4630U. Student 101006689.

Containerize the Binary Calculator web application with Docker and deploy it to
Google Kubernetes Engine (GKE) with Kubernetes YAML manifests, then deploy a
MySQL server the same two ways (imperative kubectl and YAML).

## Layout

```
webapp/      BinaryCalculatorWebapp (Spring Boot, serves on 8080) + Dockerfile
             supports + (add), * (multiply), | (or), & (and) on binary numbers
k8s/         deployment.yaml + service.yaml for the web app (LoadBalancer :8080)
mysql/       mysql-deploy.yaml + mysql-service.yaml (LoadBalancer :3306)
scripts/     setup-k8s.sh (build/push/deploy + MySQL), record-demo.sh (videos)
build_report.py   renders REPORT.md to a printable report
```

## Web application

The calculator operates on unsigned binary numbers. The operators the rubric
tests are implemented in `Binary` (`add`, `multiply`, `or`, `and`) and wired in
`BinaryController`. Example results:

```
110 | 1010 = 1110      1 | 100   = 101
110 & 1010 = 10        111 & 101 = 101
11  * 11   = 1001      111 * 101 = 100011
```

## Deploy

See `scripts/setup-k8s.sh` for every step (Artifact Registry, image build,
cluster, app via YAML, MySQL via kubectl and via YAML, access, teardown). It is
scoped to the `sdt-ms3` gcloud config. Build the web image with:

```bash
cd webapp && mvn package && docker build -t <image> . && docker push <image>
```

## Notes

The service account key is never committed (`.gitignore`). The MySQL image is
`mysql/mysql-server`; the user is `user` / `sofe3980u`, schema `Readings`.
