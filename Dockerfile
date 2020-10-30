FROM ubuntu:20.04

RUN apt-get update && \
apt-get install -y python3-pip libssl-dev && \ 
python3 -m pip install "molecule[ansible, lint, docker, molecule-vagrant]"
