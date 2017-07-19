#!/usr/bin/env bash

VAGRANT_USER=vagrant

# install RVM unless it is already installed
if [ ! -d /usr/local/rvm ]; then
	echo 'Fetching GPG keys for RVM...'
	sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
	if [ $? -ne 0 ]; then
		curl -sSL https://rvm.io/mpapis.asc | sudo gpg --import -
	fi

	echo 'Fetching and installing RVM...'
	curl -sSL https://get.rvm.io | sudo bash -s $1

	echo "Adding ${VAGRANT_USER} to 'rvm' group..."
	sudo usermod -a -G rvm ${VAGRANT_USER}
fi

