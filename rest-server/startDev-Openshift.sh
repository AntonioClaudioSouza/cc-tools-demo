#!/usr/bin/env bash

# Get env file
source .env

while getopts "g" opt; do
    case $opt in
        g)
            GENERATE_CERT=true
            ;;
    esac
done

#
# Remove the pod ssh service 
#
function deletePodServiceSSH(){

    if [ "$POD_SSH_SERVICE" == false ]
    then
        echo 'POD SSH nao habilitado'
        return 0
    fi 

    oc delete -f tools-for-openshift/pod_service/podssh.yaml
    sleep 1
}

#
# Setup pod service SSH
# 
function createPodServiceSSH(){

    if [ "$POD_SSH_SERVICE" == false ]
    then
        echo 'POD SSH nao habilitado'
        return 0
    fi 
    
    deletePodServiceSSH

    oc create -f tools-for-openshift/pod_service/podssh.yaml
    sleep 5

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
function createServerNFs(){

    if [ "$POD_SSH_SERVICE" == true ]
    then
        echo 'POD SSH habilitado, desabilite-o para continuar'
        return 0
    fi  

    cd tools-for-openshift/volume-nfs/
    ./create-server-nfs-local.sh
    cd ../../
}

#
# The server NFs must be running
# If not installed, use function createServerNFs
#
function createVolumeNFs(){
    
    if [ "$POD_SSH_SERVICE" == true ]
    then
        echo 'POD SSH habilitado, desabilite-o para continuar'
        return 0
    fi     

    oc create -f tools-for-openshift/volume-nfs/pv-pvc-nfs-volume.yaml
}

#
# Delete volume NFs
#
function deleteVolumeNFs(){

    if [ "$POD_SSH_SERVICE" == true ]
    then
        echo 'POD SSH habilitado, desabilite-o para continuar'
        return 0
    fi  

    oc delete -f tools-for-openshift/volume-nfs/pv-pvc-nfs-volume.yaml
}


# ******************************************************************************
#                           ROUTINES FOR REST-SERVER
# ******************************************************************************
#
# Assemble name file of org
#
function setNameFileOrgConfig(){

    org=$1

    if [ -z "$org" ]
    then
        echo 'informe a org!'       
        return 
    fi

    if [ "$POD_SSH_SERVICE" == true ]
    then
        tmp='openshift-ssh-'$org'.yaml'  
    else
        tmp='openshift-nfs-'$org'.yaml'
    fi 

    local nameFileOrgConfig=$tmp
    echo $nameFileOrgConfig
}

#
# Assemble name file config of template org
#
function setNameFileOrgTemplate(){

    org=$1

    if [ -z "$org" ]
    then
        echo 'informe a org!'       
        return 
    fi

    if [ "$POD_SSH_SERVICE" == true ]
    then
        tmpNameArqTemplate='template/openshift-ssh-'$org'-template1.yaml'
    else
        tmpNameArqTemplate='template/openshift-nfs-'$org'-template1.yaml'
    fi    
    
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
function restServerDeploy(){

    org=$1

    #
    # Get file config or for deploy
    #
    nameFileConfigOrg=$( setNameFileOrgConfig $org )

    if [ ! -f "$nameFileConfigOrg" ]
    then
       echo $org' não localizada nos arqs de configuração, tente "preparYamls" antes'
       return 1
    fi


    #
    # Get name app the deploy
    #
    nameAppLabel=$( getValueFileConfigOrg $org 'metadata_labels_app' )
    if [ -z "$nameAppLabel" ]
    then
        echo 'label aplicação para org nao localizado, operação abortada!'       
        return 
    fi


    #
    # Deploy and wait start pods
    #
    oc create -f $nameFileConfigOrg
    
    status='no'
    while [ ! "$status" = "Running" ]
    do
        sleep 3      
        status=$(oc get pods --selector app=$nameAppLabel --no-headers -o wide | awk '{print $3}')        
        
        echo "wait...:"$status
        
        if [ "$status" = "Running" ];then
            isOk="yes"
            continue
        fi

    done    
}

#
# Remove deploy by org name
#
function restServerRemoveDeploy(){

    org=$1

    #
    # Get file config or for deploy
    #
    nameFileConfigOrg=$( setNameFileOrgConfig $org )

    if [ ! -f "$nameFileConfigOrg" ]
    then
       echo $org' não localizada nos arqs de configuração, tente "preparYamls" antes'
       return 1
    fi


    #
    # Get name app the deploy
    #
    nameAppLabel=$( getValueFileConfigOrg $org 'metadata_labels_app' )
    if [ -z "$nameAppLabel" ]
    then
        echo 'label aplicação para org nao localizado, operação abortada!'       
        return 
    fi


    #
    # Remove deploy and wait finnish
    #
    oc delete -f $nameFileConfigOrg

    status='wait'
    while [ -n "$status" ]
    do
        sleep 3      
        status=$(oc get pods --selector app=$nameAppLabel --no-headers -o wide | awk '{print $3}')                
        echo "wait...:"$status                    
    done  
}

#
# Scale rest-server
# by org name and number of replicas
# sample: org1 2
#
function restServerScaleTo(){   

    org=$1
    scale=$2
    
    nameAppLabel=$( getValueFileConfigOrg $org 'metadata_labels_app' )
    if [ -z "$nameAppLabel" ]
    then
        echo 'label aplicação para org nao localizado, operação abortada!'       
        return 
    fi

    oc scale deploymentconfig --replicas=$scale $nameAppLabel

    status='wait'
    isOk=0
    while [ "$isOk" = 0 ]
    do        
        status=$(oc get pods --selector app=$nameAppLabel --no-headers -o wide | awk '{print $3}')
        #echo "wait...:"$status
        
        arrayStatus=($status)
        countArray="${#arrayStatus[@]}"

        isRunning=0
        isTerminating=0
        for statusPod in "${arrayStatus[@]}"
        do             
            if [ $statusPod = "Running" ]
            then
                ((isRunning++))
            fi

            if [ $statusPod = "Terminating" ]
            then
                ((isTerminating++))
            fi
        done

        if [ "$isRunning" = $scale ]
        then
            if [ "$isTerminating" = "0" ]
            then
                isOk=1
            fi
        fi 
        
        echo "Status: Running "$isRunning" Terminating "$isTerminating #" Total "$countArray
        sleep 3
    done      
}

#
# Suspend All rest-server
# by org name
# sample: org1
#
function restServerSuspendAll(){

    #Scale to 0 replicas
    org=$1
    restServerScaleTo $org 0
}

# ******************************************************************************
#                           ROUTINES FOR TOOLS
# ******************************************************************************
#
# Help
#
function showFunctions(){

    echo 'deletePodServiceSSH'
    echo 'createPodServiceSSH'

    echo 'createServerNFs'
    echo 'createVolumeNFs'
	echo 'deleteVolumeNFs'

    echo 'restServerDeploy'
    echo 'restServerRemoveDeploy'
    echo 'restServerScaleTo'
    
    echo 'preparYamls'  
    echo 'restServerSuspendAll'      
}

#
# Search value in yaml file config of org
#
function getValueFileConfigOrg(){

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
function preparYamls(){
    
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
        sed "s/PORT#/443/g" $nameFileTemplateOrg > $nameFileTemplateOrgNewConfigOutput
    else        
        sed "s/PORT#/80/g" $nameFileTemplateOrg > $nameFileTemplateOrgNewConfigOutput
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




# * ------------------------
# * Script starts here.
# * ------------------------
case $1 in

    deletePodServiceSSH)
        deletePodServiceSSH
        exit 1
        ;;
    createPodServiceSSH)
        createPodServiceSSH
        exit 1
        ;;
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

    restServerSuspendAll)
		restServerSuspendAll $2
        exit 1
		;;
    preparYamls)
        preparYamls $2
        exit 1
        ;;
    help)
        showFunctions
        exit 1
        ;;
	*)
		showFunctions
        exit 1
		;;
esac