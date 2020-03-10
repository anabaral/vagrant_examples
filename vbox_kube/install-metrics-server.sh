git clone https://github.com/kubernetes-sigs/metrics-server
cd metrics-server
sed -i -e 's/^          - --secure-port=4443/&\n          - --kubelet-insecure-tls/' deploy/kubernetes/metrics-server-deployment.yaml
kubectl apply -f deploy/kubernetes/metrics-server-deployment.yaml
echo ######################################################
echo # if something wrong, restart kubelet of each nodes...
echo ######################################################


