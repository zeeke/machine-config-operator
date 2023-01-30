
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))


setupvm:
	kcli create plan -f plan.yml -P curdir=$(current_dir)


update-ovs-configure-script:
	cat ../../templates/common/_base/files/configure-ovs-network.yaml| yq -r .contents.inline > .data/configure-ovs.sh
	chmod a+x .data/configure-ovs.sh
	kcli scp --user root .data/configure-ovs.sh vm3:/usr/local/bin/configure-ovs.sh

