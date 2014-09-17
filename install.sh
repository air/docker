# DONE
# install .vimrc (done as /etc/vimrc)
# sudo apt-get -y install vim xclip git strace man curl iptables apt-transport-https
# AS cmd.run apt-get autoremove -y
#apt-get update
#apt-get dist-upgrade -y
# is reboot needed
# ack
# service ssh restart

# TODO

# create user
# salt: http://www.heystephenwood.com/2013/11/using-saltstack-to-manage-linux-users.html
adduser air
# set up sudo - copy the root line and adapt it for user 'air'
visudo

# for user air
# install gitconfig from chromebook/gitconfig
# install bashrc from chromebook/bashrc

# docker
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb https://get.docker.io/ubuntu docker main >/etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get install -y lxc-docker

# ready to test with $ sudo docker run -i -t ubuntu /bin/bash