#!/bin/sh

serviceName="custody-service"
version=$(date +%Y.%m.%d.%H.%M.%S)
printf "\nš  Releasing version: %s\n\n" "${version}"

printf "\nā¢ļø  Attempting to delete existing deployment %s\n\n" "${serviceName}"
kubectl delete deployment "${serviceName}"

printf "\nšļø  Building docker image\n\n"
docker build -t localhost:5001/"${serviceName}":"${version}" .

printf "\nš  Pushing docker image to local registry\n\n"
docker push localhost:5001/"${serviceName}":"${version}"

printf "\nš  Deploying to cluster\n\n"
cat <<EOF | kubectl apply -f -

apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${serviceName}
  labels:
    app: ${serviceName}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${serviceName}
  template:
    metadata:
      labels:
        app: ${serviceName}
      annotations:
        dapr.io/enabled: "true"
        dapr.io/app-id: "${serviceName}"
        dapr.io/app-port: "8080"
        dapr.io/enable-api-logging: "true"
    spec:
      containers:
      - name: node
        image: localhost:5001/${serviceName}:${version}
        env:
        - name: APP_PORT
          value: "8080"
        - name: APP_VERSION
          value: "${version}"
        ports:
        - containerPort: 80
        imagePullPolicy: Always
EOF


printf "\nš  Deployment complete\n\n"