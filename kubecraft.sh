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

cat <<EOF | kubectl apply -f-
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: github.com-kubecraft-k8s-kubecraft-bootstrap
  namespace: flux-system
spec:
  interval: 1m
  ref:
    branch: main
  url: https://github.com/kubecraft-k8s/kubecraft-bootstrap.git
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: github.com-kubecraft-k8s-kubecraft-bootstrap
  namespace: flux-system
spec:
  interval: 1m
  prune: true
  postBuild:
    substitute:
      var_substitution_enabled: 'true'
      velero_plugins_aws_accesskeyid:
      velero_plugins_aws_bucket:
      velero_plugins_aws_region:
      velero_plugins_aws_secretaccesskey:
      velero_plugins_aws_url:
  sourceRef:
    kind: GitRepository
    name: github.com-kubecraft-k8s-kubecraft-bootstrap
EOF

cat <<EOF | kubectl apply -f-
apiVersion: v1
kind: Secret
metadata:
  name: github.com-kubecraft-k8s-kubecraft-podinfo
  namespace: flux-system
type: Opaque
data:
  username:
  password:
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: github.com-kubecraft-k8s-kubecraft-podinfo
  namespace: flux-system
spec:
  interval: 1m
  ref:
    branch: main
  url: https://github.com/kubecraft-k8s/kubecraft-podinfo
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: github.com-kubecraft-k8s-kubecraft-podinfo
  namespace: flux-system
spec:
  prune: true
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: github.com-kubecraft-k8s-kubecraft-podinfo
#---
#apiVersion: helm.toolkit.fluxcd.io/v2beta2
#kind: HelmRelease
#metadata:
#  name: "sync-kubecraft-podinfo"
#  namespace: "flux-system"
#spec:
#  chart:
#    spec:
#      chart: flux2-sync
#      interval: 1m
#      sourceRef:
#        kind: HelmRepository
#        name: fluxcd-community
#        namespace: flux-system
#      version: "1.8.1"
#  interval: 1m
#  values:
#    gitRepository:
#      spec:
#        ignore: |
#          chart
#        url: "https://github.com/kubecraft-k8s/kubecraft-podinfo"
#        interval: "1m"
#        ref:
#          branch: "main"
#    kustomization:
#      spec:
#        interval: "1m"
EOF

#echo ""
#echo "######################"
#echo "# bootstrap/teardown #"
#echo "######################"
#kind delete clusters $BOOTSTRAPCLUSTER
