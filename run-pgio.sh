#!/bin/bash

#
# -tm == run time in seconds per lap
# -tt == Testing type [ linux_nfs, dnfs, asm_dnfs ]
# -rn == RUN Name. e.g. RUN001 
# -nl == Number of laps
# -ss == start schema count at
# -incs == increment schema count by factor
#
# Example 1: $ ./run-pgio -tm 600 -tt dnfs -rn RUN003 -nl 7 -ss 4 -es 64 -incs 2
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

  if [ ${7} != "-nl" ]
  then
    echo "Positional argument different than -nl"
    exit 1
  else
    MAX_LAPS=${8}
  fi

  if [ ${9} != "-ss" ]
  then
    echo "Positional argument different than -ss"
    exit 1
  else
    PGIO_SCHEMA_START=${10}
  fi

  if [ ${11}} != "-incs" ]
  then
    echo "Positional argument different than -incs"
    exit 1
  else
    PGIO_SCHEMA_FACTOR=${12}
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

f_create_dirs

RUN_HOME=${RESULTS_HOME}/${TEST_TYPE}/${RUN_NAME}

f_edit_slob_conf "RUN_TIME" ${LAP_RUN_TIME}
f_edit_slob_conf "NUM_SCHEMAS" ${PGIO_SCHEMA_START}

while [ ${LAP} -le ${MAX_LAPS} ]
do
  if [ ${NUM_SCHEMAS} -ge 1 ] && [ ${NUM_SCHEMAS} -le 9 ]
  then
    ZEROS="00"
  elif [ ${NUM_SCHEMAS} -gt 9 ] && [ ${NUM_SCHEMAS} -lt 100 ]
  then
    ZEROS="0"
  else
    ZEROS=""
  fi

  echo "Running at ${NUM_SCHEMAS} schemas..."
  echo "LAP_RUN_TIME = ${LAP_RUN_TIME}"
  echo "TEST_TYPE = ${TEST_TYPE}"
  echo "RUN_NAME = ${RUN_NAME}"
  echo "MAX_LAPS = ${MAX_LAPS}"
  ${PGIO_HOME}/runit.sh > ${RUN_HOME}/lap${LAP}.pgio.${ZEROS}${NUM_SCHEMAS}schemas.out 
  sleep 3

  echo "Saving results..."
  mv ${PGIO_HOME}/mpstat.out ${RUN_HOME}/lap0${LAP}.mpstat.${ZEROS}${NUM_SCHEMAS}schemas.out
  mv ${PGIO_HOME}/vmstat.out ${RUN_HOME}/lap0${LAP}.vmstat.${ZEROS}${NUM_SCHEMAS}schemas.out
  mv ${PGIO_HOME}/iostat.out ${RUN_HOME}/lap0${LAP}.nfsiostat.${ZEROS}${NUM_SCHEMAS}schemas.out

  echo "Taking a 120 seconds nap before next lap..."
  sleep 120
  
  NUM_SCHEMAS=$(( NUM_SCHEMAS * PGIO_SCHEMA_FACTOR ))
  f_edit_slob_conf "NUM_SCHEMAS" ${NUM_SCHEMAS}

  LAP=$(( LAP + 1 ))
done