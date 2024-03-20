function __besman_init {
	echo -e "\ninit - collecting required info to execute the playbook\n"
	echo -e "check & install snap"
	if ! [ -x "$(command -v snap)" ]; then
		echo "installing snap..."
		sudo apt update
		sudo apt install snapd
	else
		echo -e "snap is available\n"
	fi

	echo -e "check and install go"
	if [ -x "$(command -v go)" ]; then
		echo -e "removing go..."
		sudo snap remove go
	fi
	echo -e "\ninstalling go..."
	sudo snap install --classic --channel=1.21/stable go
	export GOPATH=$HOME/go
	export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

	echo -e "\ncheck and install criticality_score using go\n"
	if [ -x "$(command -v criticality_score)" ]; then
		echo -e "removing criticality_score..."
		cd $GOPATH/bin
		sudo rm -r criticality_score
		echo -e "criticality_score removed from go list\n"
	fi
	echo -e "installing criticality_score..."
	go install github.com/ossf/criticality_score/cmd/criticality_score@latest
	echo -e "criticality_score is installed\n"

	if [[ -z "$GITHUB_TOKEN" && -z "$GITHUB_AUTH_TOKEN" ]]; then
		echo -e "Enter Your GITHUB_AUTH_TOKEN: "
		read github_auth_token
		export GITHUB_TOKEN=$github_auth_token
		export GITHUB_AUTH_TOKEN=$github_auth_token
	else
		echo -e "\n GITHUB_AUTH_TOKEN is already set. Do you want to override it ? (Y/n)"
		read override_gh_auth_token
		if [[ "$override_gh_auth_token" == "Y" || "$override_gh_auth_token" == "y" ]]; then
			echo -e "Enter Your GITHUB_AUTH_TOKEN: "
			read github_auth_token
			export GITHUB_TOKEN=$github_auth_token
			export GITHUB_AUTH_TOKEN=$github_auth_token
		fi

	fi

	echo -e "\ninit completed"
}

function __besman_execute {
	echo -e "\nexecuting - the playbook"
	echo -e "enter project GITHUB_URL of project to scan: (note : (-)without .git in URL)"
	read project_github_url
	criticality_score -depsdev-disable -format json $project_github_url

	echo -e "\nlaunch completed."
}

function __besman_prepare {
	echo -e "\npreparing report..."

	echo -e "\nprepare completed"
}

function __besman_publish_report {
	echo -e "\npublishing-report - with necessary data-store"

	echo -e "\npublish-report completed"
}

function __besman_cleanup {
	echo -e "\nclean-up started"
	echo -e "\nclean-up done"
	# Handles the cleanup tasks.
}

function __besman_launch {
	echo -e "\nlaunching besman-criticality_score-playbook ...\n"

	__besman_init
	__besman_execute
	__besman_prepare
	__besman_publish_report
	__besman_cleanup

	echo -e "\nlaunch completed."
}

__besman_launch
