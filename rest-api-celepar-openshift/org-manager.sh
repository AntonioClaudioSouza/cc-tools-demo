#!/usr/bin/env bash
#https://unix.stackexchange.com/questions/129391/passing-named-arguments-to-shell-scripts

#
# Create new enviroment org
# params:
#   org     = org name
#   domain  = domain of org
#   force   = true              # If exist files config, force new creation
#   https   = true or false
#   lets_encrypt = true or false
#   useauth = true or false
#
function create(){

    # Get options of arguments
    for ARGUMENT in "$@"
    do
        key=$(echo $ARGUMENT | cut -f1 -d=)

        KEY_LENGTH=${#key}
        VALUE="${ARGUMENT:$KEY_LENGTH+1}"

        export "$key"="$VALUE"
    done

    #
    # Preparation for execute function
    #
    if [ -z "$force" ]
    then
        force=false
    fi

    # Check org
    if [ -z "$org" ]
    then
        echo 'informe o nome da nova org!'       
        return 
    fi

    # Check domain of org
    if [ -z "$domain" ]
    then
        domain='example.com'
    fi
    
    # Check folder
    currentPath=$(dirname "$0")
    pathNewOrg=$currentPath"/orgs/"$org

    if [ -d "$pathNewOrg" ]
    then
        if [ "$force" == "false" ]
        then
            echo 'arquivos de configuracao da org já existem, nada a fazer'
            return
        fi
      
        # If force=true, remove folder
        rm -rf $pathNewOrg > /dev/null 2>&1
        if [ -d "$pathNewOrg" ]
        then
            echo 'falhou ao tentar remover os arquivos de configuracao, nada a fazer'
            return
        fi        
    fi

    #
    # Create folder for files of new org
    # 
    mkdir $pathNewOrg > /dev/null 2>&1
    if [ ! -d "$pathNewOrg" ]
    then
        echo 'falhou ao tentar criar pasta para os arquivos de configuracao, nada a fazer'
        return 
    fi

    mkdir $pathNewOrg'/certs' > /dev/null 2>&1
    if [ ! -d "$pathNewOrg/certs" ]
    then
        echo 'falhou ao tentar criar pasta para os certificados, nada a fazer'
        return 
    fi

    #
    # Create File .env for org
    #    
    fileName=$pathNewOrg'/.env'
    echo "HTTPS=false"          >> $fileName
    echo "LETS_ENCRYPT=false"   >> $fileName
    echo "DOMAIN=$domain"       >> $fileName
    echo "USERNAME="            >> $fileName
    echo "PASSWORD="            >> $fileName
    echo "USEAUTH=false"        >> $fileName
    echo "POD_SSH_SERVICE=false">> $fileName

    #
    # Create File configsdk-org.yaml    
    #
    nameFileConfigSdkTemplate='templates/configsdk-template1.yaml'
    nameFileConfigSdkOutPut=$pathNewOrg"/configsdk-$org.yaml"    
    sed "s/#ORG#/$org/g;s/#DOMAIN#/$domain/g" $nameFileConfigSdkTemplate > $nameFileConfigSdkOutPut
       
    #
    # Create File openshift-nfs-org.yaml
    # 
    domain_label="${domain//./-}"     
    nameFileConfigOpenShiftTemplate='templates/openshift-nfs-template1.yaml'
    nameFileConfigOpenShiftOutPut=$pathNewOrg"/openshift-nfs-$org.yaml" 
    sed "s/#ORG#/$org/g;s/#DOMAIN#/$domain/g;s/#DOMAIN-FOR-LABEL#/$domain_label/g" $nameFileConfigOpenShiftTemplate > $nameFileConfigOpenShiftOutPut
 
}   

function showFunctions(){
    echo "wow!"
}

# * ------------------------
# * Script starts here.
# * ------------------------
case $1 in

    create)
        create $@
        exit 1
        ;;

  
    *)
		showFunctions
        exit 1
		;;
esac        