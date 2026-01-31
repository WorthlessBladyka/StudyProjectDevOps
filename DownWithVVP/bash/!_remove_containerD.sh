#!/bin/bash

# Переделать под полную uninstall

sudo rm -r /etc/apt/keyrings

sudo rm -r /etc/apt/sources.list.d/docker.sources
sudo rm -r /etc/apt/sources.list.d/docker.list
sudo rm -r /etc/apt/keyrings/docker.asc

apt-get remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)

exit 0