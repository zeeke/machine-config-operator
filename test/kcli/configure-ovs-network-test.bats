#!/usr/bin/env bats


cleanUpCmd="echo 'empty cleanup'"

setup() {

    load 'test_helper/bats-file/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
   
    cleanUpCmd="echo 'empty cleanup'"
}

setUp() {
    cleanUpCmd="echo 'empty cleanup'"
    var_defined="xxx"
}

teardown() {
    echo "Tearing down with [$cleanUpCmd]"
    run ${cleanUpCmd}
    echo "$var_defined"
}

@test "Single NIC" {
    output_file=${DIR}/_data/single-nic.output.txt
    nmstate_path=${DIR}/_data/single-nic.nmstate.txt
    run kcli create plan -f plans/single-nic.yml -P script_output_path=${output_file} -P final_nmstate_path=${nmstate_path}

    cleanUpCmd="kcli delete -y vm vm3"


    assert_file_contains ${output_file} "Brought up connection br-ex successfully"
    assert_file_contains ${output_file} "Brought up connection ovs-if-br-ex successfully"

}

