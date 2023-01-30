
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))


setupvm: _data/configure-ovs.sh _data/shunit2
	kcli create plan -f plan.yml -P curdir=$(current_dir)
	tail -n 1 _data/test-results.txt | grep OK || (echo "Test suite FAILED"; cat _data/test-results.txt; exit 1)

deletevm:
	kcli delete -y vm vm3

sshvm:
	kcli ssh vm3

_data/configure-ovs.sh: ../../templates/common/_base/files/configure-ovs-network.yaml
	cat ../../templates/common/_base/files/configure-ovs-network.yaml| yq -r .contents.inline > _data/configure-ovs.sh

_data/shunit2:
	curl https://raw.githubusercontent.com/kward/shunit2/v2.1.8/shunit2 > _data/shunit2

