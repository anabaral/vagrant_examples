#!/bin/sh
#
# 2020-06-02 metrics-server is changing fast! this shell may not work soon.
#
git clone https://github.com/kubernetes-sigs/metrics-server
cd metrics-server
sed -i -e 's/^          - --secure-port=4443/&\n          - --kubelet-insecure-tls/' manifests/base/deployment.yaml

echo "the below one thing may throw error, that's okay: 'no matches for kind \"Kustomization\" ... "
kubectl apply -f manifests/base/

echo ######################################################
echo # if something wrong, restart kubelet of each nodes...
echo ######################################################


