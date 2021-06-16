ssh yourLinux_id@your_designated_linux_master_IP

##################### Run this on all Linux nodes #######################

#Update the server
sudo apt-get update -y
sudo apt-get upgrade -y

#Install containerd
sudo apt-get install containerd -y

#Configure containerd and start the service
sudo mkdir -p /etc/containerd
sudo su -
containerd config default  /etc/containerd/config.toml
exit

#Next, install Kubernetes. First you need to add the repository's GPG key with the command:
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add

#Add the Kubernetes repository
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

#Install all of the necessary Kubernetes components with the command:
sudo apt-get install kubeadm kubelet kubectl -y

#Modify "sysctl.conf" to allow Linux Node’s iptables to correctly see bridged traffic
sudo nano /etc/sysctl.conf
    #Add this line: net.bridge.bridge-nf-call-iptables = 1

sudo -s
#Allow packets arriving at the node's network interface to be forwaded to pods. 
sudo echo '1' > /proc/sys/net/ipv4/ip_forward
exit

#Reload the configurations with the command:
sudo sysctl --system

#Load overlay and netfilter modules 
sudo modprobe overlay
sudo modprobe br_netfilter
  
#Disable swap by opening the fstab file for editing 
sudo nano /etc/fstab
    #Comment out "/swap.img"

#Disable swap from comand line also 
sudo swapoff -a

#Pull the necessary containers with the command:
sudo kubeadm config images pull

####### This section must be run only on the Master node##############################################
sudo kubeadm init 

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#Download Calico CNI
curl https://docs.projectcalico.org/manifests/calico.yaml > calico.yaml
#Apply Calico CNI
kubectl apply -f ./calico.yaml

#Copy the "/.kube" folder to other Linux and Windows nodes
#scp -r $HOME/.kube gary@10.0.0.153:/home/gary
scp -r $HOME/.kube administrator@10.0.0.194:/users/administrator

#Create folder "c:/k" on Windows node
ssh administrator@windows_node_ip_address 'mkdir c:\k'
#Copy "config" file from master to Windows node
scp -r $HOME/.kube/config administrator@windows_node_ip_address:/k/

##################### Run this on other Linux nodes #######################
exit

ssh yourLinux_id@your_designated_linux_node_IP
    
sudo -i 
    #Copy the token and cert from "kubeadm init" operation and run it below

    #Note to join future nodes after inial cluster set up, run "kubeadm token create --print-join-command" to get a new "kubeadm join" with fresh certs.
exit

exit

##############################################Calico settings (must perform these if you have Windows worker nodes)##################
#On Linux master:
	
	#1.1- Install "calicococtl" on one or more nodes: "https://docs.projectcalico.org/getting-started/clis/calicoctl/install"
        sudo -i
        cd /usr/local/bin/
        curl -o calicoctl -O -L  "https://github.com/projectcalico/calicoctl/releases/download/v3.19.1/calicoctl" 
        chmod +x calicoctl
        exit        
    
    #1.2- Disable "IPinIP":  
        calicoctl get ipPool default-ipv4-ippool  -o yaml > ippool.yaml
        nano ippool.yaml
        calicoctl apply -f ippool.yaml
    
        kubectl get felixconfigurations.crd.projectcalico.org default  -o yaml -n kube-system > felixconfig.yaml
        nano felixconfig.yaml #Set: "ipipEnabled: false"
        kubectl apply -f felixconfig.yaml

    #3- Configure strict affinity for clusters using Calico networking
        # For Linux control nodes using Calico networking, strict affinity must be set to true. 
        # This is required to prevent Linux nodes from borrowing IP addresses from Windows nodes:"
             calicoctl ipam configure --strictaffinity=true
    ""
    sudo reboot 

################################################################################################################################
############################################################################Verify Cluster#########################################################################
#Get cluster info
kubectl cluster-info

#View nodes (one in our case)
kubectl get nodes -o wide

