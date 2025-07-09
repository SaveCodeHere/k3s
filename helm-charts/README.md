helm upgrade --install cert-manager jetstack/cert-manager   --namespace cert-manager   --create-namespace   --values helm-charts/cert-manager-values.yaml


helm install rancher rancher-latest/rancher \
  --namespace cattle-system --create-namespace \
  --set hostname=192.168.1.49 \
  --set bootstrapPassword=admin \
  --values helm-charts/rancher-values.yaml