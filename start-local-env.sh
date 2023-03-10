#!/bin/sh
set -o errexit

printf "\nš¤ Starting local environment...\n\n"

printf '\nš Create registry container unless it already exists\n\n'
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

printf '\nš Create kind cluster called: azd-aks\n\n'
kind create cluster --name azd-aks --config ./local/kind-cluster-config.yaml

printf '\nš Connect the registry to the cluster network if not already connected\n'
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

printf '\nš Map the local registry to cluster\n\n'
kubectl apply -f ./local/deployments/config-map.yaml --wait=true


printf '\nš Deploy Redis\n\n'
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install redis bitnami/redis

printf '\nš Init Darp\n\n'
dapr init --kubernetes --wait --timeout 600

printf '\nš Deploy pub-sub broker component backed by Redis\n\n'
kubectl apply -f ./local/components/pubsub.yaml --wait=true

printf '\nš Deploy state store component backed Redis\n\n'
kubectl apply -f ./local/components/state.yaml --wait=true


printf "\nš Local environment setup completed!\n\n"