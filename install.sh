#!/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2016 Killian Kemps
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

echo "*******************************************************************************"
echo "***             Arch Linux Production Server Installation Script            ***"
echo "*******************************************************************************"
echo "This script will install sudo, FTP, SFTP, Git"

# Get the server's IP adress
ipadress=$(ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//' | head -n 1)

read -r -p 'Would you like to install sudo? [Y/n] : ' ifsudo

if [[ $ifsudo = "Y" ]] || [[ $ifsudo = 'y' ]]
  then
    # Install sudo
    echo "Installing sudo..."
    pacman -S --noconfirm sudo
fi

read -r -p 'Would you like to install FTP? [Y/n] : ' ifFTP

if [[ $ifFTP = "Y" ]] || [[ $ifFTP = 'y' ]]
  then
    # Install FTP
    echo "Installing FTP..."
    pacman -S --noconfirm vsftpd
    curl https://raw.githubusercontent.com/KillianKemps/Production-Server-Installer/master/conf/vsftpd.conf > /etc/vsftpd.conf
    systemctl start vsftpd
    systemctl enable vsftpd

    echo "You can now connect by FTP to your server with the root user"
    echo "If you have SSL certificates, you may transfer them now to /root/certificates. It is more secure through SSH."

    read -r -p 'Would you like to use SFTP by installing your certificates? [Y/n] : ' ifSFTP

    if [[ $ifSFTP = "Y" ]] || [[ $ifSFTP = 'y' ]]
      then
        echo "NOT YET IMPLEMENTED"

        # echo "Put your key and certificate in /root/certificates"
        # read -r -p 'Give the key name: ' SSLKey
        # read -r -p 'Give the certificate name: ' SSLCert
        # echo "Setting up SFTP with $SSLKey as key and $SSLCert as certificate"

        # XXX Add SSL keys to conf/vsftp_sftp configuration file of the script
        # and append this sftp conf to vsftpd.conf
    fi
fi

read -r -p 'Would you like to setup SSH for easy root login? [Y/n] : ' ifSSH

if [[ $ifSSH = "Y" ]] || [[ $ifSSH = 'y' ]]
  then
    echo "Put your public key to root's ~/.ssh/authorized_keys"
fi

read -r -p 'Would you like to setup Git and the project repository? [Y/n] : ' ifGit

if [[ $ifGit = "Y" ]] || [[ $ifGit = 'y' ]]
  then
    if id "git" >/dev/null 2>&1; then
      echo "git user already exist"
      if [ ! -d "/home/git" ]; then
        echo "git user doesn't have a home directory. Creating it."
        mkhomedir_helper git
      fi
    else
      # Create git user with its home
      useradd -m -d /home/git -s /bin/bash git
    fi

    pacman -S --noconfirm git

    cd /home/git || exit
    mkdir .ssh && chown git:git .ssh/ && chmod 700 .ssh
    touch .ssh/authorized_keys && chown git:git .ssh/authorized_keys && chmod 600 .ssh/authorized_keys

    # XXX Put dynamic vars instead
    cat /root/.ssh/id_rsa.killian.pub >> /home/git/.ssh/authorized_keys

    read -r -p 'Please give the project name in low-case : ' project_name

    if [ ! -d "/opt/git" ]; then
      echo "/opt/git directory doesn't exist. Creating directory."
      mkdir /opt/git
    fi

    # Create git project repository
    cd /opt/git || exit
    mkdir "$project_name.git"
    cd "$project_name.git" || exit
    git init --bare
    chown -R git:git /opt/git

    echo "Your project is now available at git@$ipadress:/opt/git/$project_name.git (you may replace the IP address with the domain name)"
    # Come back to original user
    exit
fi

read -r -p 'Would you like to setup NginX for NodeJS? [Y/n] : ' ifNginx

if [[ $ifNginx = "Y" ]] || [[ $ifNginx = 'y' ]]; then
  pacman -S --noconfirm nginx
  systemctl start nginx
  systemctl enable nginx
fi

read -r -p 'Would you like to setup Docker and Docker Compose? [Y/n] : ' ifDocker

if [[ $ifDocker = "Y" ]] || [[ $ifDocker = 'y' ]]; then
  pacman -S --noconfirm docker
  systemctl start docker
  systemctl enable docker

  pacman -S --noconfirm docker-compose
fi
