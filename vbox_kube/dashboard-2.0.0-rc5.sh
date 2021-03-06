#
# kubernetes-dashboard installing script
# this script assumes 
# 1) to be executed in home directory of main admin account (not root).
# 2) to be executed in the environment generated by vagrant, with /vagrant shared directory 
# 3) dashboard version = v2.0.0-rc5
echo -e "\n###\n### Installing dashboard...\n###\n"

# dashboard: installing
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc5/aio/deploy/recommended.yaml

# dashboard: clusterRoleBinding firstly authorized too little, should be extended to admin
# how: mapped ClusterRole originally kubernetes-dashboard, to be cluster-admin
kubectl get clusterrolebindings kubernetes-dashboard -o yaml   | awk 'BEGIN{flag=0}{
    if(flag==1){print "  name: cluster-admin"; flag=0} 
    else { print $0 } 
    ; if ($0 == "  kind: ClusterRole") flag=1 }'> cluster-role-binding-dashboard-for2.0.0.yaml
kubectl delete clusterrolebinding kubernetes-dashboard
kubectl create -f cluster-role-binding-dashboard-for2.0.0.yaml


# dashboard: get token
# since 2.0.0 makes ServiceAccount kubernetes-dashboard in namespace kubernetes-dashboard,
# token is also generated in the same namespace.
TOKEN_NAME=$(kubectl get secret -n kubernetes-dashboard | grep kubernetes-dashboard-token | awk '{print $1}')
TOKEN=$(kubectl describe -n kubernetes-dashboard secret ${TOKEN_NAME} | grep "token:" | awk '{print $2'} )
kubectl config set-credentials kubernetes-admin --token="${TOKEN}"


# dashboard: you will be using this config file to log on
cp $HOME/.kube/config /vagrant/config


# dashboard: generate cert and key
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout k8s.dashboard.key -out k8s.dashboard.crt -subj "/CN=dashboard.k8s.com"
kubectl -n kubernetes-dashboard create secret tls kubernetes-dashboard-tls-secret --cert k8s.dashboard.crt --key k8s.dashboard.key


# dashboard: install ingress controller
# it will be nicer if ingress controller installed as daemonset, so edit some
curl -s  https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/mandatory.yaml | sed -e "s/kind: Deployment/kind: DaemonSet/" -e "s/replicas: 1/#replicas: 1/" -e "s#kubernetes.io/os:#beta.kubernetes.io/os:#" | kubectl create -f -

# dashboard: add service for ingress controller
#
# NOTICE: USING NODEPORT 32443 !!
#
cat > nginx-ingress-svc.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: "2020-02-21T02:26:01Z"
  name: ingress-nginx
  namespace: ingress-nginx
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  - name: https
    nodePort: 32443
    port: 443
    protocol: TCP
    targetPort: 443
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
  sessionAffinity: None
  type: LoadBalancer
EOF
kubectl create -f nginx-ingress-svc.yaml

# dashboard: add ingress
cat > dashboard-ingress.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: dashboard-ingress
  namespace: kubernetes-dashboard
  annotations:
    # redirect to https while access by http
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /
    # HTTPS transfer，(because ingress use HTTP  by default)
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  # configure the secret created above
  tls:
   - secretName: kubernetes-dashboard-tls-secret
     hosts:
     - dashboard.k8s.com
  rules:
  - host: dashboard.k8s.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kubernetes-dashboard
          servicePort: 443
EOF
kubectl create -f dashboard-ingress.yaml
    
echo "### Done. You need to do the followings:"
echo "### 1) Edit your hosts file to add this host to be dashboard.k8s.com"
echo "### 2) Access dashboard by https://dashboard.k8s.com:32443/"
echo "### 3) Choose option 'config' and upload the config file generated."
