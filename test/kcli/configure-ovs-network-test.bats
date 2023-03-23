#!/usr/bin/env bats


setup() {
    load 'bats/bats-support/load'
    load 'bats/bats-assert/load'
    load 'bats/bats-file/load'

    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    
    testArtifactDir="${DIR}/_artifacts/${BATS_TEST_NAME}"
    rm -rf -- "${testArtifactDir}"
    mkdir -p "${testArtifactDir}"

    cleanUpCmd=""
}

teardown() {
    run ${cleanUpCmd}
}

@test "fake Stomcasti with strange name$%^" {
    env > /tmp/toh2
}

@test "Single NIC" {
    kcli create plan -P output_dir="${testArtifactDir}" -P run_configure_ovs=true 
    cleanUpCmd="kcli delete -y vm vm3"

    output_file="${testArtifactDir}/configure-ovs-output.txt"
    assert_file_contains "${output_file}" "Brought up connection br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex successfully"

    nmstate_file="${testArtifactDir}/nmstate.txt"
    assert_default_route_interface ${nmstate_file} "br-ex"
    assert_brex_ip_matches ${nmstate_file} 192.168.122.*
}

@test "Bonding NICs" {
    cat <<EOT >> ${testArtifactDir}/input_nmstate.yml
routes:
  config:
  - destination: 0.0.0.0/0
    next-hop-address: 192.168.122.1
    next-hop-interface: bond99
    metric: 75
    table-id: 254

interfaces:
- name: bond99
  type: bond
  state: up
  ipv4:
    dhcp: true
    enabled: true
  link-aggregation:
    mode: 802.3ad
    options:
      miimon: '100'
    port:
    - eth1
    - eth2

EOT

    kcli create plan \
        -P output_dir="${testArtifactDir}" \
        -P input_nmstate_file="${testArtifactDir}/input_nmstate.yml" \
        -P run_configure_ovs=true
    cleanUpCmd="kcli delete -y vm vm3"

    output_file="${testArtifactDir}/configure-ovs-output.txt"
    assert_file_contains "${output_file}" "Brought up connection br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex successfully"
    assert_file_contains "${output_file}" "convert_to_bridge bond99 br-ex phys0 48"

    nmstate_file="${testArtifactDir}/nmstate.txt"
    assert_default_route_interface ${nmstate_file} "br-ex"
    assert_brex_ip_matches ${nmstate_file} 192.168.122.*
}

@test "VLAN 1br" {
    case_name="vlan_1br"
    output_dir="${DIR}/_artifacts/${case_name}"
    rm -rf -- "${testArtifactDir}"
    mkdir -p "${testArtifactDir}"

    cat <<EOT >> greetings.txt
line 1
line 2
EOT

    
    kcli create plan -P output_dir="${testArtifactDir}" -P input_nmstate_file="${DIR}/nmstate/vlan_eth20.yml"
    cleanUpCmd="kcli delete -y vm vm3"

    output_file="${testArtifactDir}/configure-ovs-output.txt"
    assert_file_contains "${output_file}" "Brought up connection br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex successfully"
    assert_file_contains "${output_file}" "convert_to_bridge eth1.20 br-ex phys0 48"

    nmstate_file="${testArtifactDir}/nmstate.txt"
    assert_default_route_interface ${nmstate_file} "br-ex"
    assert_brex_ip_matches ${nmstate_file} 10.10.10.10
}


@test "VLAN 2br" {
    plan_name="vlan_2br"

    output_dir="${DIR}/_artifacts/${plan_name}"
    rm -rf -- "${testArtifactDir}"
    mkdir -p "${testArtifactDir}"
    kcli create plan -f plans/${plan_name}.yml -P output_dir="${testArtifactDir}"
    cleanUpCmd="kcli delete -y vm vm3"

    output_file="${testArtifactDir}/configure-ovs-output.txt"
    assert_file_contains "${output_file}" "Brought up connection br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex successfully"
    assert_file_contains "${output_file}" "convert_to_bridge eth1.20 br-ex phys0 48"
    assert_file_contains "${output_file}" "convert_to_bridge eth1.44 br-ex1 phys1 49"

    nmstate_file="${testArtifactDir}/nmstate.txt"
    assert_default_route_interface ${nmstate_file} "br-ex"
    assert_brex_ip_matches ${nmstate_file} 10.10.10.10
}

@test "br-ex1 as VLAN of br-ex connection" {
    plan_name="br-ex1_as_vlan_of_br-ex_connection"

    output_dir="${DIR}/_artifacts/${plan_name}"
    rm -rf -- "${testArtifactDir}"
    mkdir -p "${testArtifactDir}"
    kcli create plan -f plans/${plan_name}.yml -P output_dir="${testArtifactDir}"
    cleanUpCmd="kcli delete -y vm vm3"

    output_file="${testArtifactDir}/configure-ovs-output.txt"
    assert_file_contains "${output_file}" "Brought up connection br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex successfully"
    assert_file_contains "${output_file}" "convert_to_bridge eth0 br-ex phys0 48"
    assert_file_contains "${output_file}" "convert_to_bridge eth0.55 br-ex1 phys1 49"

    nmstate_file="${testArtifactDir}/nmstate.txt"
    assert_default_route_interface ${nmstate_file} "br-ex"
    assert_brex_ip_matches ${nmstate_file} 192.168.122.*
}

@test "Bond VLAN 2nd bridge" {
    plan_name="bond_vlan_2br"

    output_dir="${DIR}/_artifacts/${plan_name}"
    rm -rf -- "${testArtifactDir}"
    mkdir -p "${testArtifactDir}"
    kcli create plan -f plans/${plan_name}.yml -P output_dir="${testArtifactDir}"
    cleanUpCmd="kcli delete -y vm vm3"

    output_file="${testArtifactDir}/configure-ovs-output.txt"
    assert_file_contains "${output_file}" "Brought up connection br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex successfully"
    assert_file_contains "${output_file}" "convert_to_bridge bond99 br-ex phys0 48"
    assert_file_contains "${output_file}" "convert_to_bridge bond99.777 br-ex1 phys1 49"

    nmstate_file="${testArtifactDir}/nmstate.txt"
    assert_default_route_interface ${nmstate_file} "br-ex"
    assert_brex_ip_matches ${nmstate_file} 192.168.122.*
}

run_configureovs_on_vm() {
    nmstate_file=$1
    output_dir=$2


}

assert_brex_ip_matches() {
    local -r nmstate_file="$1"
    local -r regex=$2

    assert_nmstate_expression ${nmstate_file} \
        '.interfaces[] | select(.name=="br-ex" and .type=="ovs-interface") | .ipv4.address[0].ip' \
        ${regex}
}

assert_default_route_interface() {
    local -r nmstate_file="$1"
    local -r expected_interface="$2"
    assert_nmstate_expression ${nmstate_file} \
        '.routes.running | map(select(.destination=="0.0.0.0/0")) | sort_by(.metric)[0]."next-hop-interface"' \
        "${expected_interface}"
}

assert_nmstate_expression() {
    local -r nmstate_file="$1"
    local -r yq_expression="$2"
    local -r expected_regex=$3
    actual_artifacts=`yq -r "$yq_expression" $nmstate_file`

    if [[ "$actual_artifacts" =~ $expected_regex ]]; then
        return
    fi

    cat $nmstate_file \
    | batslib_decorate "NMState expression [$yq_expression] output [$actual_artifacts] didn't match [$expected_regex]" \
    | fail
}
