#
# For CentOS 7
#
#https://www.golinuxcloud.com/configure-nfs-server-client-rhel-centos-7-8/
#https://matthewpalmer.net/kubernetes-app-developer/articles/kubernetes-volumes-example-nfs-persistent-volume.html
yum install nfs-utils -y
mkdir /nfsshare
echo "/nfsshare *(rw,sync,no_root_squash)" >> /etc/exports
systemctl restart nfs-server
systemctl enable nfs-server
systemctl enable rpcbind
netstat --listening --tcp --udp | grep nfs
exportfs -a
exportfs -r
exportfs -v

mkdir /mnt/media
mount -t nfs localhost:/nfsshare /mnt/media
mount -t nfs 172.31.10.22:/nfsshare /mnt/media
echo "localhost:/nfsshare /mnt/media  nfs defaults 0 0" >> /etc/fstab
