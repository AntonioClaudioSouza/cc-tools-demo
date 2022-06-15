#!/usr/bin/env bash

pod-service(){
    oc delete -f tools-for-openshift/pod_service/podssh.yaml
    sleep 1
    oc create -f tools-for-openshift/pod_service/podssh.yaml
    sleep 5

    #oc delete -f openshift-org1.yaml
    #sleep 1

    #criar imagem container servico
    oc rsync ./ ssh-service:/mnt/rest-server/ -c ssh-service-img
    oc rsync ../fabric/crypto-config/rest-certs/ ssh-service:/mnt/certs/ -c ssh-service-img
}

# ******************************************************************************
#                           ROUTINES FOR NFS-SERVER
# ******************************************************************************

#
# Setup local nfs server
# Check config ipAddress for nfs server
#
createServerNFs(){
    cd tools-for-openshift/volume-nfs/
    ./create-server-nfs-local.sh
    cd ../../
}

#
# The server NFs must be running
# If not installed, use function createServerNFs
#
createVolumeNFs(){
    oc create -f tools-for-openshift/volume-nfs/pv-pvc-nfs-volume.yaml
}

deleteVolumeNFs(){
    oc delete -f tools-for-openshift/volume-nfs/pv-pvc-nfs-volume.yaml
}


# ******************************************************************************
#                           ROUTINES FOR REST-SERVER
# ******************************************************************************
#
# Assemble name file of org
#
setNameFileOrgConfig(){

    org=$1

    if [ -z "$org" ]
    then
        echo 'informe a org!'       
        return 
    fi

    local nameFileOrgConfig='openshift-nfs-'$org'.yaml'
    echo $nameFileOrgConfig
}

#
# Assemble name file config of template org
#
setNameFileOrgTemplate(){

    org=$1

    if [ -z "$org" ]
    then
        echo 'informe a org!'       
        return 
    fi

    tmpNameArqTemplate='template/openshift-nfs-'$org'-template1.yaml'

    if [ ! -f "$tmpNameArqTemplate" ]
    then
       echo $org' não localizada nos arqs de templates'
       return 
    fi

    local nameFileOrgTemplate=$tmpNameArqTemplate
    echo $nameFileOrgTemplate
}

#
# Deploy rest-server by org name
#
restServerDeploy(){

    org=$1

    nameFileConfigOrg=$( setNameFileOrgConfig $org )

    if [ ! -f "$nameFileConfigOrg" ]
    then
       echo $org' não localizada nos arqs de configuração'
       return 1
    fi

    oc create -f $nameFileConfigOrg
}

#
# Remove deploy by org name
#
restServerRemoveDeploy(){

    org=$1

    nameFileConfigOrg=$( setNameFileOrgConfig $org )

    if [ ! -f "$nameFileConfigOrg" ]
    then
       echo $org' não localizada nos arqs de configuração'
       return 1
    fi

    oc delete -f $nameFileConfigOrg
}

#
# Scale rest-server
# by org name and number of replicas
# sample: org1 2
#
restServerScaleTo(){   

    org=$1
    scale=$2
    
    nameAppLabel=$( getValueFileConfigOrg $org 'metadata_labels_app' )
    if [ -z "$nameAppLabel" ]
    then
        echo 'label aplicação para org nao localizado, operação abortada!'       
        return 
    fi

    oc scale deploymentconfig --replicas=$scale $nameAppLabel
}


# ******************************************************************************
#                           ROUTINES FOR TOOLS
# ******************************************************************************
#
# Search value in yaml file config of org
#
getValueFileConfigOrg(){

    org=$1
    searchBy=$2
    
    nameFileConfigOrg=$( setNameFileOrgConfig $org )

    if [ ! -f "$nameFileConfigOrg" ]
    then
       echo $org' não localizada nos arqs de configuração'
       return 1
    fi
    
    r=$(parse_yaml $nameFileConfigOrg)
    array=($r)
    result=''

    for i in "${array[@]}"
    do	    
        param=$(echo "$i" | cut -d'=' -f1)
        value=$(echo "$i" | cut -d'=' -f2)         
        if [ "$param" = "$searchBy" ]
        then
            value=$(echo $value | sed 's/"//g')
            result=$value
            local res=$value
            echo $res
            return  
        fi                
    done

    local res=''
    echo $res   
}

#
# Parse Yaml into string for search values
#
function parse_yaml() {

   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

#
# Parse and prepar file config template by org
#
preparYamls(){
    
    org=$1
    nameFileTemplateOrgNewConfigOutput=$( setNameFileOrgConfig $org )
    nameFileTemplateOrg=$( setNameFileOrgTemplate $org )

    if [ ! -f "$nameFileTemplateOrg" ]
    then
       echo $org' não localizada nos arqs de configuração'       
       return 
    fi

    echo 'Preparando configurações de '$org

    if [ "$HTTPS" == true ] 
    then        
        sed "s/PORT/443/g" $nameFileTemplateOrg > $nameFileTemplateOrgNewConfigOutput
    else        
        sed "s/PORT/80/g" $nameFileTemplateOrg > $nameFileTemplateOrgNewConfigOutput
    fi

    # Generate certs for rest-server
    cd scripts
    if [ "$HTTPS" == true ]; then
    if [ "$GENERATE_CERT" == true ]; then
        ./generate-dummy-cert.sh -d $DOMAIN
        if [ "$LETS_ENCRYPT" == true ];then
        ./letsencrypt-init.sh -g
        fi
    else
        if [ "$LETS_ENCRYPT" == true ];then
            ./letsencrypt-init.sh
        fi
    fi
    fi
    cd ..

    echo 'Finalizado sucesso'
    return 0
}


# Get env file
source .env

while getopts "g" opt; do
    case $opt in
        g)
            GENERATE_CERT=true
            ;;
    esac
done


# * ------------------------
# * Script starts here.
# * ------------------------
case $1 in
	createServerNFs)
		createServerNFs
        exit 1
		;;
    createVolumeNFs)
		createVolumeNFs
        exit 1
		;;
    deleteVolumeNFs)
		deleteVolumeNFs
        exit 1
		;;
    restServerDeploy)
		restServerDeploy $2
        exit 1
		;;
    restServerRemoveDeploy)
		restServerRemoveDeploy $2
        exit 1
		;;
    restServerScaleTo)
		restServerScaleTo $2 $3
        exit 1
		;;

    preparYamls)
        preparYamls $2
        exit 1
        ;;
	*)
		echo "ola"
        exit 1
		;;
esac