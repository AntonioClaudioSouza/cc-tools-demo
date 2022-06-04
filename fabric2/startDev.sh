#!/usr/bin/env bash


./network.sh down
rm -rf organizations/peerOrganizations
rm -rf organizations/ordererOrganizations
rm -rf organizations/rest-certs
docker network create HLResProject-net
./network.sh up createChannel
./network.sh deployCC -ccn HLResProject -ccp ../chaincode -ccl go