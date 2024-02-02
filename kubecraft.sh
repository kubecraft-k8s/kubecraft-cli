#!/bin/bash
source cli/.env.example
source cli/.env
export GITHUB_TOKEN="$CAPI_GITHUB_TOKEN"

# TODO dont install if name already exists
# TODO: allow to select between stable name that wont be deleted and random name that gets deleted
# TODO: kubecraft --keep / --delete
# TODO: kubecraft --random / --name kubecrfaft-bootstrap --> if name is provided, skip installation if cluster already exists
# creates a kind cluster
echo "####################"
echo "# bootstrap/create #"
echo "####################"
export KUBECONFIG="$HOME/.kube/$BOOTSTRAPCLUSTER"
if [[ $(kind get clusters) != *"$BOOTSTRAPCLUSTER"* ]]; then
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: "$BOOTSTRAPCLUSTER"
nodes:
  - role: control-plane
    image: kindest/node:$KIND_VERSION
EOF
fi

# provisions the bootstrap cluster using flux HelmReleases
echo "#######################"
echo "# bootstrap/provision #"
echo "#######################"
export KUBECONFIG="$HOME/.kube/$BOOTSTRAPCLUSTER"

helm repo add fluxcd-community https://fluxcd-community.github.io/helm-charts
helm upgrade --install \
  flux fluxcd-community/flux2 \
 --create-namespace -n "flux-system" \
 --version "$FLUX_VERSION"
helm repo remove fluxcd-community

helm upgrade --install sync-bootstrap cli/chart/ -f sync-bootstrap.yaml
## TODO: pause here if a restore is desired, because restore needs to be done before any workloads are synced with git
helm upgrade --install sync-podinfo cli/chart/ -f sync-podinfo.yaml

#echo ""
#echo "######################"
#echo "# bootstrap/teardown #"
#echo "######################"
#kind delete clusters $BOOTSTRAPCLUSTER
