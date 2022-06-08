#!/bin/bash

installRequisitos(){
yum update -y
yum install -y wget
yum -y install net-tools wget telnet yum-utils device-mapper-persistent-data lvm2
yum -y install nfs-utils bash-completion git nano
yum -y install ebtables ethtool
yum install -y socat
yum install -y conntrack
yum -y install elinks
yum install wget -y
wget https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-14.noarch.rpm
rpm -ivh epel-release-7-14.noarch.rpm
yum install glances -y

source /usr/share/bash-completion/bash_completion

#Install helm
#by snap
#https://snapcraft.io/install/helm/centos
#or
#curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
#chmod 700 get_helm.sh
#./get_helm.sh
}
pathDestino="./binKubernetes1.23/"
#mkdir pathDestino

# Download Binários
downloadBinaries(){
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/apiextensions-apiserver -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-aggregator  -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-apiserver  -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-controller-manager -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-log-runner -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-proxy -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-scheduler -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kubeadm -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kubectl -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kubectl-convert -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kubelet -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/mounter -P $pathDestino
}

# Download CheckSum
downloadCheckSum(){
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/apiextensions-apiserver.sha256 -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-aggregator.sha256  -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-apiserver.sha256  -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-controller-manager.sha256 -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-log-runner.sha256 -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-proxy.sha256 -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-scheduler.sha256 -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kubeadm.sha256 -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kubectl.sha256 -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kubectl-convert.sha256 -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kubelet.sha256 -P $pathDestino
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/mounter.sha256 -P $pathDestino
}

# CheckSum Files
checkIsValid(){
    cd $pathDestino
    echo "$(cat apiextensions-apiserver.sha256)  apiextensions-apiserver" | sha256sum --check
    echo "$(cat kube-aggregator.sha256)  kube-aggregator" | sha256sum --check
    echo "$(cat kube-apiserver.sha256)  kube-apiserver" | sha256sum --check
    echo "$(cat kube-controller-manager.sha256)  kube-controller-manager" | sha256sum --check
    echo "$(cat kube-log-runner.sha256)  kube-log-runner" | sha256sum --check
    echo "$(cat kube-proxy.sha256)  kube-proxy" | sha256sum --check
    echo "$(cat kube-scheduler.sha256)  kube-scheduler" | sha256sum --check
    echo "$(cat kubeadm.sha256)  kubeadm" | sha256sum --check
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    echo "$(cat kubectl-convert.sha256)  kubectl-convert" | sha256sum --check
    echo "$(cat kubelet.sha256)  kubelet" | sha256sum --check
    echo "$(cat mounter.sha256)  mounter" | sha256sum --check  
    cd ..
}

installBinaries(){
    echo "export PATH=$PATH:/usr/local/bin/"
    source ~/.bashrc
    echo "Install binaries.."
    cd $pathDestino
   
    chmod +x apiextensions-apiserver
    chmod +x kube-aggregator
    chmod +x kube-apiserver
    chmod +x kube-controller-manager
    chmod +x kube-log-runner
    chmod +x kube-proxy
    chmod +x kube-scheduler
    chmod +x kubeadm
    chmod +x kubectl
    chmod +x kubectl-convert
    chmod +x kubelet
    chmod +x mounter

    install -o root -g root -m 0755 apiextensions-apiserver /usr/local/bin/apiextensions-apiserver
    install -o root -g root -m 0755 kube-aggregator /usr/local/bin/kube-aggregator
    install -o root -g root -m 0755 kube-apiserver /usr/local/bin/kube-apiserver
    install -o root -g root -m 0755 kube-controller-manager /usr/local/bin/kube-controller-manager
    install -o root -g root -m 0755 kube-log-runner /usr/local/bin/kube-log-runner
    install -o root -g root -m 0755 kube-proxy /usr/local/bin/kube-proxy
    install -o root -g root -m 0755 kube-scheduler /usr/local/bin/kube-scheduler
    install -o root -g root -m 0755 kubeadm /usr/local/bin/kubeadm
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert
    install -o root -g root -m 0755 kubelet /usr/local/bin/kubelet
    install -o root -g root -m 0755 mounter /usr/local/bin/mounter

    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
    cd ..
}

configEnviroment(){

    #MUDAR HOSTNAME PARA master-ibm
    #hostname master-ibm
    #hostname master-ibm
   
    # Informe o IP privado de sua instancia
    #echo "xxx.xxx.xxx.xxx  master-ibm" > /etc/hosts

    # Disable swap
    swapoff -a
    sed -i 's/^\(.*swap.*\)$/#\1/' /etc/fstab 
    #bash
}

configForKubeAdm(){

    # load netfilter probe specifically
    modprobe br_netfilter

    # disable SELinux. If you want this enabled, comment out the next 2 lines. But you may encounter issues with enabling SELinux
    setenforce 0
    sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Letting iptables see bridged traffic
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
}

installDocker(){

    yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo -y

    ## Install Docker CE.
    yum -y  install docker-ce-18.06.2.ce

    ## Create /etc/docker directory.
    mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

    mkdir -p /etc/systemd/system/docker.service.d

    # Restart Docker
    systemctl daemon-reload
    systemctl enable docker
    systemctl restart docker
}

installCNI(){
    # https://v1-23.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
    CNI_VERSION="v0.8.2"
    ARCH="amd64"
    sudo mkdir -p /opt/cni/bin
    curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz" | sudo tar -C /opt/cni/bin -xz
}

installCRICTL(){
    # https://v1-23.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
    DOWNLOAD_DIR=/usr/local/bin
    CRICTL_VERSION="v1.22.0"
    ARCH="amd64"
    curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz
}

installServiceKubelet(){

    DOWNLOAD_DIR=/usr/local/bin
    RELEASE_VERSION="v0.4.0"
    curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
    sudo mkdir -p /etc/systemd/system/kubelet.service.d
    curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    systemctl enable --now kubelet
}

startCluster(){
    # Restarting services
    systemctl daemon-reload
    
    # Kubeadm Configuration
    mkdir -p /etc/kubernetes

## Create Default Audit Policy
cat > /etc/kubernetes/audit-policy.yaml <<EOF
apiVersion: audit.k8s.io/v1beta1
kind: Policy
rules:
- level: Metadata
EOF
    # folder to save audit logs
    mkdir -p /var/log/kubernetes/audit
    systemctl  restart kubelet && systemctl enable kubelet
}

configureModelNetwork(){

    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
}

configEnviromentKubernetes(){
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    export KUBECONFIG=/etc/kubernetes/admin.conf

    echo 'alias k=kubectl' >>~/.bashrc
    echo 'complete -F __start_kubectl k' >>~/.bashrc
}

installIngressNginx(){
    helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

  #Mudar o seu ip externo
  kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type": "LoadBalancer", "externalIPs":["0.0.0.0"]}}' 
  kubectl --namespace ingress-nginx get services ingress-nginx-controller -o wide
}

installHaProxy(){
    helm repo add haproxy-ingress https://haproxy-ingress.github.io/charts

cat > ./haproxy-ingress-values.yaml <<EOF
controller:
  hostNetwork: true
EOF
   
   helm install haproxy-ingress haproxy-ingress/haproxy-ingress\
  --create-namespace --namespace ingress-controller\
  --version 0.13.7\
  -f haproxy-ingress-values.yaml

  #Mudar seu ip externo
  kubectl patch svc haproxy-ingress -n ingress-controller -p '{"spec": {"type": "LoadBalancer", "externalIPs":["0.0.0.0"]}}' 
  kubectl --namespace ingress-controller get services haproxy-ingress -o wide
}

enableNode(){
    kubectl taint nodes --all node-role.kubernetes.io/master-

    echo "Enable node....wait..."
    sleep 6
    echo "done"
}


#installRequisitos
#downloadBinaries
#downloadCheckSum
#checkIsValid
#installBinaries
#configEnviroment
#configForKubeAdm
#installDocker
#installCNI
#installCRICTL
#installServiceKubelet
#startCluster

#kubeadm init

#configEnviromentKubernetes
#configureModelNetwork
#enableNode
##installIngressNginx -> aws check se será necessário

