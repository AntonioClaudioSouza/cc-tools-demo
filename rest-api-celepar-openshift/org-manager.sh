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



#
# Create new enviroment org
# params:
#   org             = org name
#   domain          = domain of org
#   chaincode       = name of chaincode
#   force           = true              # If exist files config, force new creation
#   https           = true or false
#   lets_encrypt    = true or false
#   useauth         = true or false
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
        echo 'informe o nome da nova org para rest-api, nada a fazer'       
        return 
    fi

    # Check name chaincode
    if [ -z "$chaincode" ]
    then
        echo 'informe o nome do chaincode, nada a fazer'       
        return 
    fi

    # Check domain of org
    if [ -z "$domain" ]
    then
        domain='example.com'
    fi

    # Check https of org
    if [ -z "$https" ]
    then
        https=false        
    fi

    # Set port rest-server
    if [ "$https" == "true" ]
    then
        port='443'
    else
        port='80'
    fi

    # Check lets_encrypt of org
    if [ -z "$lets_encrypt" ]
    then
        lets_encrypt=false
    fi

    # Check useauth of org
    if [ -z "$useauth" ]
    then
        useauth=false
    fi
    
    #
    # Check folder
    #
    currentPath=$(dirname "$0")   
    pathNewOrg=$PATH_TARGET_CONFIG_FILES_ORG"/"$org

    if [ -d "$pathNewOrg" ]
    then
        if [ "$force" == "false" ]
        then
            echo 'arquivos de configuracao da org já existem, nada a fazer'
            return
        fi
      
        # If force=true, remove folder
        echo " "
        echo "Aguarde..."
        echo " "
        sudo rm -rf $pathNewOrg > /dev/null 2>&1
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

    mkdir $pathNewOrg'/rest-server' > /dev/null 2>&1
    if [ ! -d "$pathNewOrg/rest-server" ]
    then
        echo 'falhou ao tentar criar pasta a rest-server, nada a fazer'
        return 
    fi

    #
    # Copy files of rest-server into org folder
    #
    cp -r $currentPath'/templates/rest-server/.'  $pathNewOrg'/rest-server/'


    #
    # Create File .env for org
    #    
    fileName=$pathNewOrg'/rest-server/.env'
    echo "HTTPS=$https"         >> $fileName
    echo "LETS_ENCRYPT=$lets_encrypt" >> $fileName
    echo "DOMAIN=$domain"       >> $fileName
    echo "USERNAME="            >> $fileName
    echo "PASSWORD="            >> $fileName
    echo "USEAUTH=$useauth"     >> $fileName
    echo "POD_SSH_SERVICE=false">> $fileName

    #
    # Create File configsdk-org.yaml    
    #
    nameFileConfigSdkTemplate=$currentPath'/templates/configsdk-template1.yaml'
    nameFileConfigSdkOutPut=$pathNewOrg"/rest-server/configsdk-$org.yaml"    
    sed "s/#ORG#/$org/g;s/#DOMAIN#/$domain/g" $nameFileConfigSdkTemplate > $nameFileConfigSdkOutPut
       
    #
    # Create File openshift-nfs-org.yaml
    # 
    domain_label="${domain//./-}"   
    nameFileConfigOpenShiftTemplate=$currentPath'/templates/openshift-nfs-template1.yaml'
    nameFileConfigOpenShiftOutPut=$pathNewOrg"/openshift-nfs-$org.yaml" 
    sed "s/#ORG#/$org/g;s/#DOMAIN#/$domain/g;s/#DOMAIN-FOR-LABEL#/$domain_label/g;s/PORT#/$port/g;s/#CHAINCODE-NAME#/$chaincode/g" $nameFileConfigOpenShiftTemplate > $nameFileConfigOpenShiftOutPut
    
    
    #
    # Show results
    #
    tree $pathNewOrg -L 2
    echo " "
    echo " Copie os arquivos de certificados para $pathNewOrg/certs"
    echo " Sem eles não será possível realizar o deploy!"
    echo " "

    #check.....
    # Generate certs for rest-server
    #cd scripts
    #if [ "$HTTPS" == true ]; then
    #if [ "$GENERATE_CERT" == true ]; then
    #    ./generate-dummy-cert.sh -d $DOMAIN
    #    if [ "$LETS_ENCRYPT" == true ];then
    #    ./letsencrypt-init.sh -g
    #    fi
    #else
    #    if [ "$LETS_ENCRYPT" == true ];then
    #        ./letsencrypt-init.sh
    #    fi
    #fi
    #fi
    #cd ..
}   

#
# Remove config org
# params:
#   org   = org name
function remove(){

    # Get options of arguments
    for ARGUMENT in "$@"
    do
        key=$(echo $ARGUMENT | cut -f1 -d=)

        KEY_LENGTH=${#key}
        VALUE="${ARGUMENT:$KEY_LENGTH+1}"

        export "$key"="$VALUE"
    done

    # Check org
    if [ -z "$org" ]
    then
        echo 'informe o nome da org a ser removida da rest-api, nada a fazer'       
        return 
    fi

    # Check folder
    #currentPath=$(dirname "$0")
    pathNewOrg=$PATH_TARGET_CONFIG_FILES_ORG"/"$org

    if [ -d "$pathNewOrg" ]
    then
        while true; do
            echo "**************************************************************************"
            echo "       OS CERTIFICADOS DESSA ORG SERÃO REMOVIDOS DA PASTA REST-SERVER"
            echo "  TENHA CERTEZA DA REMOÇÃO, OU, FAÇA UM BACKUP ANTES SE ASSIM DESEJAR!!!!"
            echo "**************************************************************************"
            read -p "Tem certeza que deseja remover essa org:($org) da rest-api(SN)? " yn
            case $yn in
                [Ss]* ) break;;
                [Nn]* ) echo 'Operacao abortada';exit;;
                * ) echo "Por favor informe sim ou nao.";;
            esac
        done

        # Remove folder config org
        sudo rm -rf $pathNewOrg > /dev/null 2>&1        
        if [ -d "$pathNewOrg" ]
        then
            echo 'falhou ao tentar remover os arquivos de configuracao, nada a fazer'
            return
        fi        
    else
        echo 'org nao localizada para remocao da rest-api, nada a fazer'
    fi
}

#
# List Orgs in folders
# params:
#   org   = org name
#   or no params
function list(){

    # Get options of arguments
    for ARGUMENT in "$@"
    do
        key=$(echo $ARGUMENT | cut -f1 -d=)

        KEY_LENGTH=${#key}
        VALUE="${ARGUMENT:$KEY_LENGTH+1}"

        export "$key"="$VALUE"
    done

    # Check org
    if [ -z "$org" ]
    then
        tree $PATH_TARGET_CONFIG_FILES_ORG -L 1
        return 
    fi

    tree $PATH_TARGET_CONFIG_FILES_ORG'/'$org -L 2
}

function showFunctions(){
    echo " "
    echo " "
    echo "> create"
    echo "  Cria os arquivos de configuração para uma nova org rest-api"
    echo "  Parametros:"
    echo "   org            = nome a org a ser criada"
    echo "   domain         = domínio que a org pertence"
    echo "   chaincode      = nome do chaincode"
    echo "   force          = caso exista, força a criação ( valor: true ou false )"
    echo "   https          = usa https? ( valor: true ou false )"
    echo "   lets_encrypt   = usa lets_encrypt? ( valor: true ou false )"
    echo "   useauth        = usa useauth? ( valor: true ou false )"
    echo " "
    echo "  Exemplo: ./org-manager.sh create org=org1 domain=example.com force=true"
    echo " "
    echo " "
    echo "> remove"
    echo "  Remove os arquivos de configuração de uma org rest-api"
    echo "  Parametros:"
    echo "   org  = nome a org a ser removida"
    echo " "
    echo "  Exemplo: ./org-manager.sh remove org=org1"
    echo " "
    echo " "
    echo "> list"
    echo "  Mostra as orgs configuradas para deploy"
    echo "  Parametros:"
    echo "    nenhum irá listar todas"
    echo "    nome da org, mostrar a listagem os arqs de config"
    echo " "
    echo "  Exemplo: ./org-manager.sh list"
    echo "  Exemplo: ./org-manager.sh list org=org1"
    echo " "
    echo " "
}

# * ------------------------
# * Script starts here.
# * ------------------------
case $1 in

    create)
        create $@
        exit 1
        ;;

    remove)
        remove $@
        exit 1
        ;;
    list)
        list $@
        exit 1
        ;;        
    *)
		showFunctions
        exit 1
		;;
esac        