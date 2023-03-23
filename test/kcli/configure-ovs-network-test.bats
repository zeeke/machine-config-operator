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
    cat <<EOT >> ${testArtifactDir}/input_nmstate.yml
routes:
  config:
  - destination: 0.0.0.0/0
    next-hop-address: 10.10.10.254
    next-hop-interface: eth1.22
    metric: 75
    table-id: 254

interfaces:
- name: eth1.22
  type: vlan
  state: up
  ipv4:
    dhcp: false
    enabled: true
    address:
    - ip: 10.10.10.22
      prefix-length: 24
  vlan:
    base-iface: eth0
    id: 22
EOT

    
    kcli create plan \
        -P output_dir="${testArtifactDir}" \
        -P input_nmstate_file="${testArtifactDir}/input_nmstate.yml" \
        -P run_configure_ovs=true
    cleanUpCmd="kcli delete -y vm vm3"

    output_file="${testArtifactDir}/configure-ovs-output.txt"
    assert_file_contains "${output_file}" "Brought up connection br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex successfully"
    assert_file_contains "${output_file}" "convert_to_bridge eth1.22 br-ex phys0 48"

    nmstate_file="${testArtifactDir}/nmstate.txt"
    assert_default_route_interface ${nmstate_file} "br-ex"
    assert_brex_ip_matches ${nmstate_file} 10.10.10.22
}


@test "VLAN 2br" {
 
    cat <<EOT >> ${testArtifactDir}/input_nmstate.yml
routes:
  config:
  - destination: 0.0.0.0/0
    next-hop-address: 10.10.10.254
    next-hop-interface: eth1.22
    metric: 75
    table-id: 254

interfaces:
- name: eth1.22
  type: vlan
  state: up
  ipv4:
    dhcp: false
    enabled: true
    address:
    - ip: 10.10.10.22
      prefix-length: 24
  vlan:
    base-iface: eth0
    id: 22
- name: eth1.44
  type: vlan
  state: up
  ipv4:
    dhcp: false
    enabled: true
    address:
    - ip: 10.10.44.44
      prefix-length: 24
  vlan:
    base-iface: eth0
    id: 44
EOT

    kcli create plan \
        -P output_dir="${testArtifactDir}" \
        -P input_nmstate_file="${testArtifactDir}/input_nmstate.yml" \
        -P run_configure_ovs=true \
        -P secondary_bridge_interface=eth1.44
    cleanUpCmd="kcli delete -y vm vm3"

    output_file="${testArtifactDir}/configure-ovs-output.txt"
    assert_file_contains "${output_file}" "Brought up connection br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex1 successfully"
    assert_file_contains "${output_file}" "convert_to_bridge eth1.22 br-ex phys0 48"
    assert_file_contains "${output_file}" "convert_to_bridge eth1.44 br-ex1 phys1 49"

    nmstate_file="${testArtifactDir}/nmstate.txt"
    assert_default_route_interface ${nmstate_file} "br-ex"
    assert_brex_ip_matches ${nmstate_file} 10.10.10.22
}

# https://issues.redhat.com/browse/OCPBUGS-10379
@test "br-ex1 as VLAN of br-ex connection" {
    cat <<EOT >> ${testArtifactDir}/input_nmstate.yml
interfaces:
- name: eth0.33
  type: vlan
  state: up
  ipv4:
    dhcp: false
    enabled: true
    address:
    - ip: 10.10.33.33
      prefix-length: 24
  vlan:
    base-iface: eth0
    id: 33
EOT

    kcli create plan \
        -P output_dir="${testArtifactDir}" \
        -P input_nmstate_file="${testArtifactDir}/input_nmstate.yml" \
        -P run_configure_ovs=true \
        -P secondary_bridge_interface=eth0.33
    cleanUpCmd="kcli delete -y vm vm3"

    output_file="${testArtifactDir}/configure-ovs-output.txt"
    assert_file_contains "${output_file}" "Brought up connection br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex successfully"
    assert_file_contains "${output_file}" "convert_to_bridge eth0 br-ex phys0 48"
    assert_file_contains "${output_file}" "convert_to_bridge eth0.33 br-ex1 phys1 49"

    nmstate_file="${testArtifactDir}/nmstate.txt"
    assert_default_route_interface ${nmstate_file} "br-ex"
    assert_brex_ip_matches ${nmstate_file} 192.168.122.*
}

@test "Bond VLAN 2nd bridge" {
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
- name: bond99.77
  type: vlan
  state: up
  ipv4:
    dhcp: false
    enabled: true
    address:
    - ip: 10.10.77.77
      prefix-length: 24
  vlan:
    base-iface: bond99
    id: 77
EOT

    kcli create plan \
        -P output_dir="${testArtifactDir}" \
        -P input_nmstate_file="${testArtifactDir}/input_nmstate.yml" \
        -P run_configure_ovs=true \
        -P secondary_bridge_interface=bond99.77
    cleanUpCmd="kcli delete -y vm vm3"

    output_file="${testArtifactDir}/configure-ovs-output.txt"
    assert_file_contains "${output_file}" "Brought up connection br-ex successfully"
    assert_file_contains "${output_file}" "Brought up connection ovs-if-br-ex successfully"
    assert_file_contains "${output_file}" "convert_to_bridge bond99 br-ex phys0 48"
    assert_file_contains "${output_file}" "convert_to_bridge bond99.77 br-ex1 phys1 49"

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
