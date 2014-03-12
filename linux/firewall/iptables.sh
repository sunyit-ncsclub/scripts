ip=IP_ADDRESS_HERE
subnet=CIDER_NOTATION_SUBNET
interface=INTERFACE

LOGLIMIT="2/s"
LOGLIMITBURST="10"

# flush rules, set default to log and drop, and allow on loopback
iptables -F
iptables -P INPUT -j LOGDROP 
iptables -P FORWARD -j LOGDROP 
iptables -P OUTPUT -j LOGDROP 
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
#iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

############################
# Allow ALL incoming SSH
#iptables -A INPUT -i $interface -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

# Allow incoming SSH only from a sepcific network
#iptables -A INPUT -i $interface -p tcp -s $subnet --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

# Allow outgoing SSH
#iptables -A OUTPUT -o $interface -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A INPUT -i $interface -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

# Allow outgoing SSH only to a specific network
#iptables -A OUTPUT -o $interface -p tcp -d 192.168.101.0/24 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A INPUT -i $interface -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
############################


############################
# Allow incoming HTTP
#iptables -A INPUT -i $interface -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# Allow outgoing HTTP
#iptables -A OUTPUT -o $interface -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A INPUT -i $interface -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# Allow incoming HTTPS
#iptables -A INPUT -i $interface -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

# Allow outgoing HTTPS
#iptables -A OUTPUT -o $interface -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A INPUT -i $interface -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
############################


############################
# ICMP from inside to outside
#iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
#iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

# ICMP from outside to inside
#iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
#iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
############################


############################
# Allow outbound DNS
#iptables -A OUTPUT -p udp -o $interface --dport 53 -j ACCEPT
#iptables -A INPUT -p udp -i $interface --sport 53 -j ACCEPT

# Allow inbound DNS
#iptables -A INPUT -p udp -i $interface --dport 53 -j ACCEPT
#iptables -A OUTPUT -p udp -o $interface --sport 53 -j ACCEPT
############################


############################
# Allow FTP connections 
iptables -A INPUT  -p tcp --sport 21 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 21 -m state --state NEW,ESTABLISHED -j ACCEPT

# Allow Active FTP Connections
iptables -A INPUT -p tcp --sport 20 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 20 -m state --state ESTABLISHED -j ACCEPT

# Allow Passive FTP Connections - PROBIBLY NOT WHAT YOU WHANT, WILL OPEN ANY USER PORT TO ANY EXTERNAL USER PORTS BASICALLY BYPASSING FIREWALL
#iptables -A INPUT -p tcp --sport 1024: --dport 1024: -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 1024: --dport 1024:  -m state --state ESTABLISHED,RELATED -j ACCEPT

############################
# Allow MySQL connection only from a specific network
#iptables -A INPUT -i $interface -p tcp -s $subnet --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT
############################


############################
# Allow Sendmail or Postfix
#iptables -A INPUT -i $interface -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT

# Allow IMAP and IMAPS
#iptables -A INPUT -i $interface -p tcp --dport 143 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 143 -m state --state ESTABLISHED -j ACCEPT

#iptables -A INPUT -i $interface -p tcp --dport 993 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 993 -m state --state ESTABLISHED -j ACCEPT

# Allow POP3 and POP3S
#iptables -A INPUT -i $interface -p tcp --dport 110 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 110 -m state --state ESTABLISHED -j ACCEPT

#iptables -A INPUT -i $interface -p tcp --dport 995 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 995 -m state --state ESTABLISHED -j ACCEPT
############################


############################
# Log dropped packets
iptables -N LOGDROP
iptables -A LOGDROP -p tcp -m limit --limit $LOGLIMIT --limit-burst $LOGLIMITBURST -j LOG --log-prefix "TCP LOGDROP: "
iptables -A LOGDROP -p udp -m limit --limit $LOGLIMIT --limit-burst $LOGLIMITBURST -j LOG --log-prefix "UDP LOGDROP: "
iptables -A LOGDROP -p icmp -m limit --limit $LOGLIMIT --limit-burst $LOGLIMITBURST -j LOG --log-prefix "ICMP LOGDROP: "
iptables -A LOGDROP -f -m limit --limit $LOGLIMIT --limit-burst $LOGLIMITBURST -j LOG --log-prefix "FRAGMENT LOGDROP: "
iptables -A LOGDROP -j DROP
############################


# MultiPorts example (Allow incoming SSH, HTTP, and HTTPS)
#iptables -A INPUT -i $interface -p tcp -m multiport --dports 22,80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp -m multiport --sports 22,80,443 -m state --state ESTABLISHED -j ACCEPT

# Port forwarding example from 422 to 22
#iptables -t nat -A PREROUTING -p tcp -d 192.168.102.37 --dport 422 -j DNAT --to 192.168.102.37:22
#iptables -A INPUT -i $interface -p tcp --dport 422 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o $interface -p tcp --sport 422 -m state --state ESTABLISHED -j ACCEPT
