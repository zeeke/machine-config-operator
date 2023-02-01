#!/usr/bin/env bats


#cleanUpCmd="echo 'empty cleanup'"

setup() {

    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-file/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
   
    cleanUpCmd="echo 'empty cleanup'"
}

teardown() {
    echo "Tearing down with [$cleanUpCmd]"
    run ${cleanUpCmd}

}

@test "Single NIC" {
    output_file=${DIR}/_data/single-nic.output.txt
    nmstate_path=${DIR}/_data/single-nic.nmstate.txt
    rm -rf ${output_file} ${nmstate_path}

    run kcli create plan -f plans/single-nic.yml -P script_output_path=${output_file} -P final_nmstate_path=${nmstate_path}
    cleanUpCmd="kcli delete -y vm vm3"


    assert_file_contains ${output_file} "Brought up connection br-ex successfully"
    assert_file_contains ${output_file} "Brought up connection ovs-if-br-ex successfully"
}

@test "Bonding NICs" {
    output_file=${DIR}/_data/bonding-nics.output.txt
    nmstate_path=${DIR}/_data/bonding-nics.nmstate.txt
    rm -rf ${output_file} ${nmstate_path}

    run kcli create plan -f plans/bonding-nics.yml -P script_output_path=${output_file} -P final_nmstate_path=${nmstate_path}    
    cleanUpCmd="kcli delete -y vm vm3"

    assert_file_contains ${output_file} "Brought up connection br-ex successfully"
    assert_file_contains ${output_file} "Brought up connection ovs-if-br-ex successfully"
    assert_file_contains ${output_file} "convert_to_bridge bond99 br-ex phys0 48"

}
