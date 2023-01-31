#!/bin/bash


THIS_FOLDER=`dirname -- "$0"`
SHUNIT2=$THIS_FOLDER/_data/shunit2

cleanUpCmd="echo 'empty cleanup'"

setUp() {
    cleanUpCmd="echo 'empty cleanup'"
}

tearDown() {
    # eval ${cleanUpCmd}
    echo "TearDown"
}

testSingleNIC() {
    output_file=${THIS_FOLDER}/_data/single-nic.output.txt
    nmstate_path=${THIS_FOLDER}/_data/single-nic.nmstate.txt
    #kcli create plan -f plans/single-nic.yml -P script_output_path=${output_file} -P final_nmstate_path=${nmstate_path}

    cleanUpCmd="kcli delete -y vm vm3"


    grep -q "Brought up connection br\-ex successfully" $output_file
    assertTrue "$?"

    grep -q "Brought up connection ovs\-if\-br\-ex successfully" $output_file
    assertTrue "$?"
}


# Load shUnit2.
. ${SHUNIT2}