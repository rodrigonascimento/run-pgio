#!/bin/bash

#
# -tm == run time in seconds per lap
# -tt == Testing type [ linux_nfs, dnfs, asm_dnfs ]
# -rn == RUN Name. e.g. RUN001 
# -update-pct == % of UPDATE
# -sc == number of schemas
# -tc == number of threads per schema

# Example 1: $ ./run-pgio-wle -tm 600 -tt fsxn -rn RUN001 -update-pct 0 -sc 128 -tc 1 
#

# -- Variable Definitions -----------------------------------------------------
PGIO_HOME="/home/postgres/pgio"
RESULTS_HOME="${PGIO_HOME}/TESTRUNS/"
NUM_THREADS=1
LAP=1

# -- Functions ----------------------------------------------------------------
function f_arg_parser() {
  if [ ${1} != "-tm" ]
  then
    echo "Positional argument different than -tm"
    exit 1
  else
    LAP_RUN_TIME=${2}
  fi
  
  if [ ${3} != "-tt" ]
  then
    echo "Positional argument different than -tt"
    exit 1
  else
    TEST_TYPE=${4}
  fi

  if [ ${5} != "-rn" ]
  then
    echo "Positional argument different than -rn"
    exit 1
  else
    RUN_NAME=${6}
  fi

  if [ ${7} != "-update-pct" ]
  then
    echo "Positional argument different than -nl"
    exit 1
  else
    PGIO_UPDATE_PCT=${8}
  fi

  if [ ${9} != "-sc" ]
  then
    echo "Positional argument different than -ss"
    exit 1
  else
    PGIO_SCHEMA_COUNT=${10}
  fi

  if [ ${11} != "-tc" ]
  then
    echo "Positional argument different than -incs"
    exit 1
  else
    PGIO_THREAD_COUNT=${12}
  fi
}

function f_edit_slob_conf() {
  local VAR_LOOKUP=${1}
  local VAR_NEW_VALUE=${2}

  OLD_VAR=$(grep ^${VAR_LOOKUP} ${PGIO_HOME}/pgio.conf)
  OLD_VAR_NAME=$(echo ${OLD_VAR} | awk -F"=" '{ print $1 }')
  OLD_VAR_VALUE=$(echo ${OLD_VAR} | awk -F"=" '{ print $2 }')

  sed -i "s/^${OLD_VAR}/${OLD_VAR_NAME}=${VAR_NEW_VALUE}/" ${PGIO_HOME}/pgio.conf
}

function f_create_dirs() {
  if [ ! -d ${RESULTS_HOME} ]
  then
    mkdir -p ${RESULTS_HOME}
  fi

  if [ ! -d ${RESULTS_HOME}/${TEST_TYPE} ]
  then
    mkdir -p ${RESULTS_HOME}/${TEST_TYPE}
  fi 

  if [ ! -d ${RESULTS_HOME}/${TEST_TYPE}/${RUN_NAME} ]
  then
    mkdir -p  ${RESULTS_HOME}/${TEST_TYPE}/${RUN_NAME}
  fi
}

# -- Main body ----------------------------------------------------------------

f_arg_parser ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8} ${9} ${10} ${11} ${12}

RUN_HOME=${RESULTS_HOME}/${TEST_TYPE}/${RUN_NAME}

f_create_dirs

f_edit_slob_conf "RUN_TIME" ${LAP_RUN_TIME}
f_edit_slob_conf "NUM_SCHEMAS" ${PGIO_SCHEMA_COUNT}
f_edit_slob_conf "NUM_THREADS" ${PGIO_THREAD_COUNT}

for run in 1 2 3;
do
    echo "Running at ${PGIO_SCHEMA_COUNT} schemas..."
    echo "LAP_RUN_TIME = ${LAP_RUN_TIME}"
    echo "TEST_TYPE = ${TEST_TYPE}"
    echo "RUN_NAME = ${RUN_NAME}"
    ${PGIO_HOME}/runit.sh > ${RUN_HOME}/run0${run}_pgio.${PGIO_SCHEMA_COUNT}schemas.out 2>&1

    echo "Saving results..."
    cp ${PGIO_HOME}/pgio.conf ${RUN_HOME}/run0${run}_pgio_conf.${PGIO_SCHEMA_COUNT}schemas.out
    mv ${PGIO_HOME}/mpstat.out ${RUN_HOME}/run0${run}_mpstat.${PGIO_SCHEMA_COUNT}schemas.out
    mv ${PGIO_HOME}/vmstat.out ${RUN_HOME}/run0${run}_vmstat.${PGIO_SCHEMA_COUNT}schemas.out
    mv ${PGIO_HOME}/iostat.out ${RUN_HOME}/run0${run}_iostat.${PGIO_SCHEMA_COUNT}schemas.out
    mv ${PGIO_HOME}/pgio_session_detail.out ${RUN_HOME}/run0${run}_pgio_sesssion_detail.${PGIO_SCHEMA_COUNT}schemas.out

    echo "Taking a 300 seconds nap before next lap..."
    sleep 300
done
