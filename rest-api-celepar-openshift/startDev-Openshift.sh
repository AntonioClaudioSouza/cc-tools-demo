#!/usr/bin/env bash

# Get env file
source .env


#
# Check source is load
#
if [ -z "$PATH_TARGET_CONFIG_FILES_ORG" ]
then
   echo 'Arquivo de configuração ambiente nao encontrado. Nada a fazer'
   exit 0
fi

if [ -z "$TYPE_PERSISTENCE" ]
then
   echo 'Tipo de persistencia de dados não informado. Nada a fazer'
   exit 0
fi


#
# If not exist path target, create.
#
if [ ! -d "$PATH_TARGET_CONFIG_FILES_ORG" ]
then
    mkdir -p $PATH_TARGET_CONFIG_FILES_ORG
    if [ ! -d "$PATH_TARGET_CONFIG_FILES_ORG" ]
    then
        echo 'Não foi possível criar pasta no volume persistente'
        echo $PATH_TARGET_CONFIG_FILES_ORG
    fi
fi


# ******************************************************************************
#                           ROUTINES FOR REST-SERVER
# ******************************************************************************
#
# Assemble name file of org
#
function getNameFileOrgConfig(){

    org=$1

    if [ -z "$org" ]
    then
        echo 'informe o nome da org!'       
        return 
    fi

    local nameFileOrgConfig=$PATH_TARGET_CONFIG_FILES_ORG"/$org/openshift-$TYPE_PERSISTENCE-$org.yaml"    
    echo $nameFileOrgConfig 
}

#
# Deploy rest-server by org name
#
function restServerDeploy(){

    org=$1

    #
    # Get file config or for deploy
    #
    nameFileConfigOrg=$( getNameFileOrgConfig $org )

    if [ ! -f "$nameFileConfigOrg" ]
    then
       echo $org' não localizada nos arqs de configuração, para essa org!. Execute org-manager.sh create org='$org
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
    nameFileConfigOrg=$( getNameFileOrgConfig $org )

    if [ ! -f "$nameFileConfigOrg" ]
    then
       echo $org' não localizada nos arqs de configuração, para essa org!. Execute org-manager.sh create org='$org
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
# Search value in yaml file config of org
#
function getValueFileConfigOrg(){

    org=$1
    searchBy=$2
    
    nameFileConfigOrg=$( getNameFileOrgConfig $org )

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
# Help
#
function showFunctions(){

    echo 'restServerDeploy'
    echo 'restServerRemoveDeploy'
    echo 'restServerScaleTo'        
    echo 'restServerSuspendAll'      
}


# * ------------------------
# * Script starts here.
# * ------------------------
case $1 in
  
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

    help)
        showFunctions
        exit 1
        ;;
	*)
		showFunctions
        exit 1
		;;
esac