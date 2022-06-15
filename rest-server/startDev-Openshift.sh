oc delete -f tools-for-openshift/pod_service/podssh.yaml
sleep 1
oc create -f tools-for-openshift/pod_service/podssh.yaml
sleep 5

#oc delete -f openshift-org1.yaml
#sleep 1

#criar imagem container servico
oc rsync ./ ssh-service:/mnt/rest-server/ -c ssh-service-img
oc rsync ../fabric/crypto-config/rest-certs/ ssh-service:/mnt/certs/ -c ssh-service-img

