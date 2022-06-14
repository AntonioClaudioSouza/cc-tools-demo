#oc delete -f podssh.yaml
#sleep 5
#oc create -f podssh.yaml
#sleep 5

#criar imagem container servico
oc rsync ./ ssh-service-pod:/tmp/rest-server/ -c ssh-service-img
oc rsync ../fabric/crypto-config/rest-certs/ ssh-service-pod:/tmp/certs/ -c ssh-service-img

#oc rsync rest-server/ ssh-service-pod:/tmp/rest-server/ -c ssh-service-img
#oc rsync fabric/crypto-config/rest-certs/ ssh-service-pod:/tmp/certs/ -c ssh-service-img