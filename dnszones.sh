#!/bin/bash

# Necesario ter instalado o azcli e cli53, apos instalar azcli, efetuar fazer o az login
# como instalar o cli53 https://github.com/barnybug/cli53
# como instalar azcli https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# AWS credential
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""

# Azure Subscription e Resource Group onde a Zona DNS está ou será criada
SUBSCRIPTION=""
RESOUCEGROUP=""

function AWSLIST () {
    cli53 list
}

ZONEEXP=$2
function AWSEXPORT() {
    if [ "$ZONEEXP" == "" ]
        then
            AWSDNSLIST=$(cli53 list | grep -v Name | awk '{print $2}')
            # export all zones
            mkdir -p zones
            while read AWSDNS
                do cli53 export $AWSDNS > zones/${AWSDNS%?}
                echo ''$AWSDNS' Exported'
                # remove alias AWS from zone
                sed -i '' -e '/AWS/d' zones/${AWSDNS%?}
            done <<< "$AWSDNSLIST"
        else
            cli53 export $ZONEEXP > zones/$ZONEEXP && echo ''$ZONEEXP' Exported'
            sed -i '' -e '/AWS/d' zones/$ZONEEXP
    fi
}

ZONEIMP=$2
function AZUREIMPORT () {
    if [ "$ZONEIMP" == "" ] 
        then
            #Importa somente para ZONAS DNS EXISTENTES NA AZURE
            AZDNSLIST=$(az network dns zone list -o tsv | awk '{print $6}')
            while read AZDNS
                do az network dns zone import -g $RESOUCEGROUP -n $AZDNS -f zones/$AZDNS --subscription $SUBSCRIPTION
            done <<< "$AZDNSLIST"
        else
            if [ -f zones/$ZONEIMP ]
                then 
                    #Cria e importa a zona se não existe na Azure
                    az network dns zone import -g $RESOUCEGROUP -n $ZONEIMP -f zones/$ZONEIMP --subscription $SUBSCRIPTION
                else
                    echo "File $ZONEIMP in folder ./zones Not found"
            fi
    fi
}

OPT=$1
case $OPT
in 
    "awslist" )
        AWSLIST
    ;;
    "awsexport" )
        AWSEXPORT
    ;;
    "azureimport" )
        AZUREIMPORT
    ;;
    *)
    echo "Use awslist, awsexport ou azureimport"
esac
