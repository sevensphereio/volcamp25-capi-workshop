#!/bin/bash
echo "🔍 Validation Complète Management Cluster"
echo "=========================================="

# Check cluster exists
if kind get clusters 2>/dev/null | grep -q "capi-management"; then
  echo "✅ Cluster kind existe"
else
  echo "❌ Cluster kind manquant"
  exit 1
fi

# Check all namespaces
for ns in capi-system capd-system cert-manager; do
  if kubectl get namespace $ns &>/dev/null; then
    echo "✅ Namespace $ns existe"
  else
    echo "❌ Namespace $ns manquant"
    exit 1
  fi
done

# Check all deployments running
DEPLOYMENTS=(
  "capi-system/capi-controller-manager"
  "capd-system/capd-controller-manager"
  "cert-manager/cert-manager"
)

for deploy in "${DEPLOYMENTS[@]}"; do
  ns=$(echo $deploy | cut -d'/' -f1)
  name=$(echo $deploy | cut -d'/' -f2)
  if kubectl get deployment -n $ns $name &>/dev/null; then
    ready=$(kubectl get deployment -n $ns $name -o jsonpath='{.status.readyReplicas}')
    desired=$(kubectl get deployment -n $ns $name -o jsonpath='{.spec.replicas}')
    if [ "$ready" == "$desired" ]; then
      echo "✅ Deployment $deploy : $ready/$desired ready"
    else
      echo "❌ Deployment $deploy : $ready/$desired ready"
      exit 1
    fi
  else
    echo "❌ Deployment $deploy manquant"
    exit 1
  fi
done

echo "=========================================="
echo "🎉 Validation complète réussie!"
echo "🚀 Management cluster opérationnel"
