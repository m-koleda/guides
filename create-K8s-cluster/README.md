# create-K8s-cluster
# Description of how to create a Kubernetes cluster with [Calico](https://projectcalico.docs.tigera.io/about/about-calico "What is Calico?") networking solution  

In the process of learning, I wondered how to create a Kubernetes cluster by myself? After reading many different articles and trying many different ways, I came up with the following way to create a cluster.

### Before you begin

Make sure you have a linux host that meets the following requirements:  

+ x86-64, arm64, ppc64le, or s390x processor
+ 2CPU
+ 2GB RAM
+ 10GB free disk space
+ RedHat Enterprise Linux 7.x+, CentOS 7.x+, Ubuntu 16.04+, or Debian 9.x+
+ Ensure that Calico can manage `cali` and `tunl` interfaces on the host. 

If NetworkManager (network-manager) is present on the host, refer to Configure NetworkManager:  
NetworkManager manipulates the routing table for interfaces in the default network namespace where Calico veth pairs are anchored for connections to containers. This can interfere with the Calico agent’s ability to route correctly.  
Create the following configuration file at `/etc/NetworkManager/conf.d/calico.conf` to prevent NetworkManager from interfering with the interfaces:

    [keyfile]  
    unmanaged-devices=interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico;interface-name:vxlan-v6.calico;interface-name:wireguard.cali;interface-name:wg-v6.cali<br/>
    
In this case, I used Ubuntu 20.04 LTS virtual machines on VirtualBox with 2CPU, 2GB RAM, 10GB free disk space.  

### Preparing a sample of a virtual machine
(which we will then clone into the master and nodes)

As a regular user with sudo privileges, open a bash terminal and run the following commands:

  0. Disable automatic updates in Ubuntu 20.04 LTS so that it does not interfere with installing applications, the apt-get service will be free and you will be able to install applications without delay.
  
    sudo nano /etc/apt/apt.conf.d/20auto-upgrades
    
   Set the values in this file to 0:
  
    APT::Periodic::Update-Package-Lists "0";
    APT::Periodic::Download-Upgradeable-Packages "0";
    APT::Periodic::AutocleanInterval "0";
    APT::Periodic::Unattended-Upgrade "0";

  1. Disable swapping.
  
    sudo swapoff -a
    sudo nano /etc/fstab
    
  Just add # to the beginning of the line where swap is.

  2. Import the keys and register the repository for Kubernetes.
  
    sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee -a /etc/apt/sources.list.d/kubernetes.list

  3. Configure docker and Kubernetes prerequisites on the machine.
  
    KUBE_DPKG_VERSION=1.23.0-00 #or your other target K8s version, which should be at least 1.13. Docker is removed in k8s version 1.24+. Please use containerd or other CRI.
    sudo apt-get update && \
    sudo apt-get install -y ebtables ethtool && \
    sudo apt-get install -y docker.io && \
    sudo apt-get install -y apt-transport-https && \
    sudo apt-get install -y kubelet=$KUBE_DPKG_VERSION kubeadm=$KUBE_DPKG_VERSION kubectl=$KUBE_DPKG_VERSION

  4. Set `net.bridge.bridge-nf-call-iptables=1`. On Ubuntu 20.04, the following commands first enable `br_netfilter`.
  
    . /etc/os-release
    if [ "$VERSION_CODENAME" == "focal" ]; then sudo modprobe br_netfilter; fi
    
    sudo sysctl net.bridge.bridge-nf-call-iptables=1
    
  5. Change the Docker cgroup to systemd by editing the Docker service with the following command.  
  
    sudo nano /usr/lib/systemd/system/docker.service
    
  Modify this line  
  
    ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock  
  
  to  
  
    ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd
    
    #Restart the Docker service by running the following command
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo kubeadm reset
    
### Create the master and worker nodes.
Turn off the VM and clone it into the master and nodes.  
  
  0. Check that swappin is disable.
  
    sudo swapoff -a

  1. Set the IP addresses. Master and worker nodes must be on the same subnetwork.
  
    sudo nano /etc/netplan/00-installer-config.yaml
    sudo netplan apply  
    
  ![image](https://user-images.githubusercontent.com/97964258/210066370-a72a44c4-39fc-41ee-a9db-4fdbf960999e.png)

    
  2. Change the `hostname` to `kube-master` or `kube-worker01`
  
    sudo hostnamectl set-hostname kube-master
    
  3. Add the current machine to the `/etc/hosts` file:
  
    echo $(hostname -i) $(hostname) | sudo tee -a /etc/hosts
    
### Configure the Kubernetes master.
  
  1. Initialize the master using the following command.
  
    sudo kubeadm init --pod-network-cidr=192.168.2.0/16
    
  `Note:  
  If 192.168.0.0/16 is already in use within your network you must select a different pod network CIDR, replacing 192.168.0.0/16 in the above command.`
  
  You should see output that the Kubernetes master was successfully initialized.  
  Note the kubeadm join command that you need to use on the other servers worker-nodes to join the Kubernetes cluster.
  
  ![image](https://user-images.githubusercontent.com/97964258/205933500-ca0a30b6-030f-495f-97dc-86842a15b993.png)
  
  2. Execute the following commands to configure kubectl (also returned by kubeadm init).
  
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

  3. Install the Tigera Calico operator and custom resource definitions.
  
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/tigera-operator.yaml

  4. Install Calico by creating the necessary custom resource. For more information on configuration options available in this manifest, see the [installation reference](https://projectcalico.docs.tigera.io/reference/installation/api).
  
  `Note: Before creating this manifest, read its contents and make sure its settings are correct for your environment. For example, you may need to change the default IP pool CIDR to match your pod network CIDR.`
  
  5. Confirm that all of the pods are running with the following command.
  
    watch kubectl get pods -n calico-system

  Wait until each pod has the `STATUS` of `Running`.  
  `Note: The Tigera operator installs resources in the calico-system namespace. Other install methods may use the kube-system namespace instead.`
  
  6. Remove the taints on the master so that you can schedule pods on it.
  
    kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-

  It should return the following.
  
    node/<your-hostname> untainted

  7. Confirm that you now have a node in your cluster with the following command.
  
    kubectl get nodes -o wide

  It should return something like the following.
  
    NAME              STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
    <your-hostname>   Ready    master   52m   v1.24.0   192.168.1.115   <none>        Ubuntu 20.04.4 LTS   5.4.0-100-generic   containerd://1.5.9
    
  
  ### Configure the Kubernetes worker nodes.
  
  The other machines will act as Kubernetes worker nodes in the cluster.

  On each of the other machines, run the kubeadm join command that you copied in the previous section.  
  
  ![image](https://user-images.githubusercontent.com/97964258/205933835-0718e3d1-62d4-4c34-a0cc-c0d84be92191.png)
  
  To verify the connection to your cluster, use the [kubectl get](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands) command to return a list of the cluster nodes.
  
    kubectl get nodes
  
  ### Congratulations! You now have a Kubernetes cluster with Calico!  
  The next step is to deploy an application on your own K8s cluster. Good luck!<br/><br/><br/><br/>

  In this guide I used materials:  
  https://learn.microsoft.com/en-us/sql/big-data-cluster/deploy-with-kubeadm?view=sql-server-ver15  
  https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart  
  https://kubernetes.io/docs/home/  
  https://habr.com/ru/post/530352/  
  https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/  
  https://stackoverflow.com/questions/54728254/kubernetes-kubeadm-init-fails-due-to-dial-tcp-127-0-0-110248-connect-connecti  
  https://www.devopsschool.com/blog/how-to-change-the-cgroup-driver-from-cgroupfs-systemd-in-docker/  
