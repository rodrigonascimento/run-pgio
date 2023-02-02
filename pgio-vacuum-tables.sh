#!/bin/bash

NUM_SCHEMAS=${1}
DBNAME=${2}

function f_pgio_vacuum_freeze_tables() {
    table=pgio${1}

    echo "VACUUM (FREEZE, VERBOSE) ${table};"
}

#------ Main

echo "Running VACUUM FREEZE for ${NUM_SCHEMAS} schemas..."
vacuum_start=${SECONDS}
echo "Waiting for vacuum freeze to complete..."

for (( i=1; i <= ${NUM_SCHEMAS}; i++ ))
do
    ( f_pgio_vacuum_freeze_tables ${i} | psql ${DBNAME} > vacuum_freeze_pgio${i}_table.out 2>&1 ) &
done

wait 
(( total_vacuum_time = ${SECONDS} - ${vacuum_start}))

echo -e "Vacuum freeze complete. Elapsed: ${total_vacuum_time} seconds."
