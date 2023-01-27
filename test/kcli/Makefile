
WHAT ?= .*
runtest: bats _output/configure-ovs.sh
	./bats/bats-core/bin/bats --verbose-run --filter "$(WHAT)" configure-ovs-network-test.bats

bats test_helper:
	git clone --branch v1.8.2 https://github.com/bats-core/bats-core.git bats/bats-core
	git clone --branch v0.3.0 https://github.com/bats-core/bats-support.git bats/bats-support
	git clone --branch v2.1.0 https://github.com/bats-core/bats-assert.git bats/bats-assert
	git clone --branch master https://github.com/bats-core/bats-file.git bats/bats-file

_output/configure-ovs.sh: ../../templates/common/_base/files/configure-ovs-network.yaml _output
	cat ../../templates/common/_base/files/configure-ovs-network.yaml| yq -r .contents.inline > _output/configure-ovs.sh

_output:
	mkdir _output
