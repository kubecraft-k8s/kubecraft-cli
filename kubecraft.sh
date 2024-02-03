#!/bin/bash
export BOOTSTRAPCLUSTER="kubecraft-bootstrap"
export KUBECONFIG="$HOME/.kube/$BOOTSTRAPCLUSTER"
export KIND_VERSION="v1.29.0"
export FLUX_VERSION="2.12.2"

if [[ $(kind get clusters) != *"$BOOTSTRAPCLUSTER"* ]]; then
  kind create cluster "--image=kindest/node:$KIND_VERSION" "--name=$BOOTSTRAPCLUSTER"
fi
helm upgrade --atomic --install --create-namespace -n flux-system flux flux2 --repo https://fluxcd-community.github.io/helm-charts --version "$FLUX_VERSION"
helm upgrade --atomic --install --create-namespace -n kubecraft-bootstrap kubecraft-bootstrap  charts/flux-release/ -f kubecraft-bootstrap.yaml
#helm upgrade --atomic --install --create-namespace -n podinfo podinfo-restore charts/restore
#helm upgrade --atomic --install --create-namespace -n podinfo podinfo-release charts/release
#helm upgrade --atomic --install --create-namespace -n podinfo podinfo-backup charts/backup
#helm upgrade --atomic --install --create-namespace -n kubecraft-workload kubecraft-workload charts/flux-release/ -f kubecraft-workload.yaml
