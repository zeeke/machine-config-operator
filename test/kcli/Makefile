
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))


setupvm: _data/configure-ovs.sh _data/shunit2
	kcli create plan -f plan.yml -P curdir=$(current_dir)
	tail -n 1 _data/test-results.txt | grep OK || (echo "Test suite FAILED"; cat _data/test-results.txt; exit 1)

deletevm:
	kcli delete -y vm vm3

sshvm:
	kcli ssh vm3

_data:
	mkdir _data

_data/configure-ovs.sh: ../../templates/common/_base/files/configure-ovs-network.yaml _data
	cat ../../templates/common/_base/files/configure-ovs-network.yaml| yq -r .contents.inline > _data/configure-ovs.sh

runtest: bats _data/configure-ovs.sh
	./bats/bin/bats configure-ovs-network-test.bats

bats test_helper:
	git clone --branch v1.8.2 https://github.com/bats-core/bats-core.git bats
	git clone --branch v0.3.0 https://github.com/bats-core/bats-support.git test_helper/bats-support
	git clone --branch v2.1.0 https://github.com/bats-core/bats-assert.git test_helper/bats-assert
	git clone --branch master https://github.com/bats-core/bats-file.git test_helper/bats-file
