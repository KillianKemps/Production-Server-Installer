#!/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2015 Killian Kemps
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
echo "This script will install sudo, FTP"

read -p 'Would you like to install sudo? [Y/n] : ' ifsudo

if [ $ifsudo = "Y" ] || [ $ifsudo = 'y' ]
  then
    # Install sudo
    echo "Installing sudo..."
    pacman -S --noconfirm sudo
fi

read -p 'Would you like to install FTP? [Y/n] : ' ifFTP

if [ $ifFTP = "Y" ] || [ $ifFTP = 'y' ]
  then
    # Install FTP
    echo "Installing FTP..."
    pacman -S --noconfirm vsftpd
    # XXX Set right wget fetch of conf
    cp https://github.com/KillianKemps/Production-Server-Installer/conf/vsftpd.conf /etc/vsftpd.conf
    systemctl start vsftpd
    systemctl enable vsftpd

    echo "You can now connect by FTP to your server with the root user"
    echo "If you have SSL certificates, you may transfer them now to /root/certificates. It is more secure through SSH."

    read -p 'Would you like to use SFTP by installing your certificates? [Y/n] : ' ifSFTP

    if [ $ifSFTP = "Y" ] || [ $ifSFTP = 'y' ]
      then
        echo "Put your key and certificate in /root/certificates"
        read -p 'Give the key name: ' SSLKey
        read -p 'Give the certificate name: ' SSLCert
        echo "Setting up SFTP with $SSLKey as key and $SSLCert as certificate"
    fi
fi

read -p 'Would you like to setup SSH for easy root login? [Y/n] : ' ifSSH

if [ $ifSSH = "Y" ] || [ $ifSSH = 'y' ]
  then
    echo "Put your public key to root's ~/.ssh/authorized_keys"
fi

read -p 'Would you like to setup Git? [Y/n] : ' ifGit

if [ $ifGit = "Y" ] || [ $ifGit = 'y' ]
  then
    pacman -S --noconfirm git
    # Create git user
    useradd -m -s /bin/bash git
    su git
    cd
    mkdir .ssh && chmod 700 .ssh
    touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys
    # XXX Put dynamic vars instead
    cat /root/.ssh/id_rsa.killian.pub >> ~/.ssh/authorized_keys

    read -p 'Please give the project name in low-case : ' project_name
    # Create git project repository
    cd /opt/git
    mkdir $project_name.git
    cd $project_name.git
    git init --bare
fi
