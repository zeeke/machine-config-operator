
WHAT ?= .*
runtest: bats _artifacts/configure-ovs.sh
	kcli download image fedora37
	./bats/bats-core/bin/bats --timing --verbose-run --filter "$(WHAT)" configure-ovs-network-test.bats

bats test_helper:
	git -c advice.detachedHead=false clone -q --branch v1.8.2 https://github.com/bats-core/bats-core.git bats/bats-core
	git -c advice.detachedHead=false clone -q --branch v0.3.0 https://github.com/bats-core/bats-support.git bats/bats-support
	git -c advice.detachedHead=false clone -q --branch v2.1.0 https://github.com/bats-core/bats-assert.git bats/bats-assert
	git -c advice.detachedHead=false clone -q --branch master https://github.com/bats-core/bats-file.git bats/bats-file

_artifacts/configure-ovs.sh: ../../templates/common/_base/files/configure-ovs-network.yaml _artifacts
	cat ../../templates/common/_base/files/configure-ovs-network.yaml| yq -r .contents.inline > _artifacts/configure-ovs.sh

_artifacts:
	mkdir _artifacts
