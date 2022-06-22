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
    
    currentPath=$(dirname "$0")
    pathNewOrg=$currentPath"/orgs/"$org

    if [ -d "$pathNewOrg" ]
    then

        if [ "$force" == "false" ]
        then
            echo 'arquivos de configuracao da org já existem, nada a fazer'
            return
        fi
        
        pathNewOrg='/tmp/demo1/org1'
        rmdir $pathNewOrg > /dev/null 2>&1
        if [ -d "$pathNewOrg" ]
        then
            echo 'falhou ao tentar remover os arquivos de configuracao, nada a fazer'
            return
        fi
        
    fi


#    if [ "$POD_SSH_SERVICE" == true ]
#    then
#        tmpNameArqTemplate='template/openshift-ssh-'$org'-template1.yaml'
#    else
#        tmpNameArqTemplate='template/openshift-nfs-'$org'-template1.yaml'
#    fi    
    
#    if [ ! -f "$tmpNameArqTemplate" ]
#    then
#       echo $org' não localizada nos arqs de templates'
#       return 
#    fi


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