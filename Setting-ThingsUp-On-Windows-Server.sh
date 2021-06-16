
#################################################################################################################################
ssh or remote desk to to your Windows node
#####################################################################Open all ports#############################################
#Create a new rule and allow all traffic In and out:
New-NetFireWallRule -DisplayName "Allow All Traffic" -Direction OutBound -Action Allow 
New-NetFireWallRule -DisplayName "Allow All Traffic" -Direction InBound -Action Allow

#################################################################Install Windows containers and Docker##########################
Install-WindowsFeature -Name containers
Restart-Computer -Force

Install-Module DockerMsftProvider -Force
	
Install-Package Docker -ProviderName DockerMsftProvider -Force     
Restart-Computer -Force

Set-Service -Name docker -StartupType 'Automatic'

###############################################################Install additional Windows networking components######
Install-WindowsFeature RemoteAccess
Install-WindowsFeature RSAT-RemoteAccess-PowerShell
Install-WindowsFeature Routing
Restart-Computer -Force

Install-RemoteAccess -VpnType RoutingOnly
Set-Service -Name RemoteAccess -StartupType 'Automatic'
start-service RemoteAccess

###############################################################Install Calico####################################################
mkdir c:\k
#Copy the Kubernetes kubeconfig file from the master node (default, Location $HOME/.kube/config), to c:\k\config.

Invoke-WebRequest https://docs.projectcalico.org/scripts/install-calico-windows.ps1 -OutFile c:\install-calico-windows.ps1

c:\install-calico-windows.ps1 -KubeVersion 1.20.0

#Verify that the Calico services are running.
Get-Service -Name CalicoNode
Get-Service -Name CalicoFelix


#Install and start kubelet/kube-proxy service. Execute following PowerShell script/commands.
C:\CalicoWindows\kubernetes\install-kube-services.ps1
Start-Service -Name kubelet
Start-Service -Name kube-proxy

#Copy kubectl.exe, kubeadm.etc to the folder below which is on the path: 
cp C:\k\*.exe C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps


###############################################################Test Win node#####################################
#List all cluster nodes
kubectl get nodes -o wide	

#View the BGP cluster
sudo calicoctl node status

#Deploy a sample container 
 kubectl apply -f .\webapi-service.yaml

#Check the pod
kubectl get pods -o wide 

#Verify the service
kubectl get services

#Hit the service through its VIP (ClusterIP)
curl http://<ClusterIP>:8000/system -UseBasicParsing

#His the service throug NodePort
curl http://<NODE_IP_ADDRESS>:<NODE_PORT_PORT#>/system -UseBasicParsing

#Sh into a POD and call the service
kubectl exec -it hello-world-5457b44555-cqfct  -- s
	#Call the service using the ClusterIP
	curl http://<ClusterIP>:8000/system
	exit


#Cleanup
kubectl delete deployment webapi-service
kubectl delete service webapi-service

