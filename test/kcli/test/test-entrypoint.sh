#!/bin/bash


THIS_FOLDER=`dirname -- "$0"`
SHUNIT2=$THIS_FOLDER/../shunit2
CONFIGURE_OVS_SCRIPT=$THIS_FOLDER/../configure-ovs.sh
INITIAL_NMSTATE_FILE=/tmp/initial-nmstate

oneTimeSetUp() {
    nmstatectl show -r > ${INITIAL_NMSTATE_FILE}
}

setUp() {
    nmstatectl apply ${INITIAL_NMSTATE_FILE}
}

testBase() {
  ${CONFIGURE_OVS_SCRIPT} OVNKubernetes
}

# Load shUnit2.
. ${SHUNIT2}