#!/usr/bin/env bash

project_path=$1
output_format=$2

generate_spdx() {
	cp /opt/spdx-sbom-generator $1
	cd $1 && ./spdx-sbom-generator -f $2
}

if [[ -d $1 ]]; then
	if [[ -n $2 ]]; then
		generate_spdx $1 $2
	else
		generate_spdx $1 "spdx"
	fi
else
	echo -e "[-] Error: No such directory \n"
	echo -e "[+] USAGE : ./besman-playbook-spdx-generator.sh [path to project] [output format -> \"json\", \"spdx\"] (Default - spdx)]\n"
	echo "[+] Example : ./besman-playbook-spdx-generator.sh /home/username/Desktop/projectA/ \"json\""
fi
