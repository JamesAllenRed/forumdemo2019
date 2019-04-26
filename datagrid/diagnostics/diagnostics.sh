#!/usr/bin/env bash

set -e

# Quick check
oc project

declare -a PodArray=("datagrid-service-0" "datagrid-service-1" "datagrid-service-2" "datagrid-service-3")

DIAGNOSTICS_DIR=$(mktemp -d -t datagrid-)
echo "Diagnostics directory: ${DIAGNOSTICS_DIR}"

for pod in ${PodArray[@]}; do
    echo "Diagnostics for: ${pod}"

    podDir=${DIAGNOSTICS_DIR}/${pod}
    mkdir ${podDir}

    pid=$(oc exec ${pod} -- jps | grep jboss-modules.jar | awk '{print $1}')

    echo "Copy GC log"
    oc rsync "${pod}:/opt/datagrid/standalone/log" ${podDir}
    cat ${podDir}/log/gc.log* > ${podDir}/gc.log

    echo "Generate a heap dump and copy locally"
    oc exec ${pod} -- rm heap.bin || true
    oc exec ${pod} -- jmap -dump:format=b,file=heap.bin ${pid}
    oc rsync "${pod}:/home/jboss/heap.bin" ${podDir}

    echo "Generate thread dump and copy log"
    oc exec ${pod} -- kill -3 ${pid}
    oc logs ${pod} > ${podDir}/${pod}.log
done