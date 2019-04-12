

# https://medium.com/@vovaprivalov/setup-minikube-on-virtualbox-7cba363ca3bc

curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl

sudo chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl

curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.24.1/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

minikube version

export CHANGE_MINIKUBE_NONE_USER=true
sudo -E minikube start -vm-driver=none

echo "export CHANGE_MINIKUBE_NONE_USER=true" >> ~/.bashrc

kubectl cluster-info