#!/bin/bash

# This stops multiple coreos instances using digital ocean cloud platform
#
# Prerequisites:
# The following environment variables are used:
#   TOKEN  : digital ocean api-token (as environment variable)
#
# Optional prerequisites:
#   OUTPUT : local output log folder (e.g. -d my-directory)

#set -e
set -u

OUTPUT="azure"

while getopts ":d:" opt; do
  case $opt in
    d)
      OUTPUT="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ ! -e "$OUTPUT" ] ;  then
  echo "$0: directory '$OUTPUT' not found"
  exit 1
fi

. $OUTPUT/clusterinfo.sh

declare -a SERVERS_IDS=(${SERVERS_IDS[@]})

NUMBER=${#SERVERS_IDS[@]}

echo "NUMBER OF MACHINES: $NUMBER"
echo "OUTPUT DIRECTORY: $OUTPUT"
echo "MACHINE PREFIX: $PREFIX"

wait

export CLOUDSDK_CONFIG="$OUTPUT/azure"

function deleteMachine () {
  echo "deleting machine $PREFIX$1"
  id=${SERVERS_IDS[`expr $1 - 1`]}

  ok=0
  while [ "$ok" == "0" ]; do
    azure vm delete "$id" -q
    if [ $? -eq 0 ] ; then
      ok=1
    else
      echo Failed to delete service $PREFIX$1. Retrying.
    fi
  done
}

echo "Destroying machines"
for i in `seq $NUMBER`; do
  sleep 1
  deleteMachine $i &
done

wait

echo "Destroying virtual network"
azure network vnet delete "arangodb-test-vnet"

#wait
