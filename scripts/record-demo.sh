#!/usr/bin/env bash
# record-demo.sh - shot lists for the Lab 3 Part 1 videos. Prints the beats to
# narrate; records nothing itself. Use a screen recorder and read each aloud.
#
#   ./scripts/record-demo.sh app      # rubric 7 and 12: deploy app via YAML
#   ./scripts/record-demo.sh mysql    # rubric 10 and 11: MySQL two ways

set -euo pipefail

case "${1:-}" in
app)
  cat <<'EOF'
VIDEO: web app via YAML + instructions  (rubric 7 and 12)
------------------------------------------------------------
0:00  Intro: name, student ID, "Lab 3 Part 1, deploying the Binary Calculator
      to GKE with YAML files."
0:20  Show k8s/deployment.yaml: kind Deployment, image (Artifact Registry path),
      containerPort 8080. Show k8s/service.yaml: kind Service, type LoadBalancer,
      port 8080. Explain each field as you go (this doubles as the instructions).
1:10  Apply: ./scripts/setup-k8s.sh app-yaml   (kubectl apply -f k8s/).
1:30  kubectl get deployments,services. Wait for the service EXTERNAL-IP.
2:00  Open http://<EXTERNAL-IP>:8080, show the calculator loads.
2:20  Access tests (rubric 9): enter two OR (|), two AND (&), two multiplication
      (*) examples, showing each result page.
      e.g. 110 | 1010 = 1110 ; 1 | 100 = 101
           110 & 1010 = 10   ; 111 & 101 = 101
           11  * 11   = 1001 ; 111 * 101 = 100011
2:50  Wrap up.
EOF
  ;;
mysql)
  cat <<'EOF'
VIDEO: MySQL two ways  (rubric 10 and 11)
------------------------------------------------------------
PART A - kubectl commands (rubric 10)
0:00  "Deploying MySQL with imperative kubectl commands."
0:15  ./scripts/setup-k8s.sh mysql-cmd
        kubectl create deployment mysql-deployment --image mysql/mysql-server --port 3306
        kubectl expose deployment mysql-deployment --type LoadBalancer --name mysql-service
0:45  kubectl get deployments,services; wait for the pod to be Running.
1:00  Access MySQL: kubectl exec -it <pod> -- mysql -uroot -p   (password sofe3980u).
      Run: show databases;
1:30  Delete it so part B is a clean slate:
        kubectl delete deployment mysql-deployment ; kubectl delete service mysql-service

PART B - YAML files (rubric 11)
2:00  "Deploying the same MySQL with YAML files."
2:10  Show mysql/mysql-deploy.yaml (image mysql/mysql-server, env user/sofe3980u,
      database Readings, port 3306) and mysql/mysql-service.yaml (LoadBalancer 3306).
2:50  Apply: ./scripts/setup-k8s.sh mysql-yaml
3:10  kubectl get deployments,services.
3:30  Access MySQL and run the example SQL:
        use Readings;
        create table meterType(ID int, type varchar(50), cost float);
        insert into meterType values(1,'boston',100.5);
        insert into meterType values(2,'denver',120.0);
        select * from meterType where cost>=110;
4:10  Wrap up.
EOF
  ;;
*)
  echo "usage: $0 {app|mysql}"
  ;;
esac
