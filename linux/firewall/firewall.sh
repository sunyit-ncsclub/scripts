#!/bin/sh
if [ $# -lt 2 ]; then
echo "$0 localnetwork dns_server services
dns_server	trusted dns server
localnetwork  the local net work to allow
services	sesrvices we want ex ssh, dns, web
"
exit 1
fi

dns=$1
shift

local_net=$1
shift

INPUT="-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT"
OUTPUT="-A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
-A OUTPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
-A OUTPUT -p icmp -m icmp --icmp-type 3 -j ACCEPT"
for service in "$@"
do
	case $service in
	dns)
	INPUT="$INPUT\n-A INPUT -p udp --dport 53 -j ACCEPT"
	INPUT="$INPUT\n-A INPUT -p tcp --dport 53 -j ACCEPT"
	;;
	ftp)
	INPUT="$INPUT\niptables -A INPUT  -p tcp --sport 21 -j ACCEPT
	iptables -A INPUT -p tcp --sport 20 -j ACCEPT"
	;;
	http)
	INPUT="$INPUT\n-A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT"
	;;
	imap)
	INPUT="$INPUT\n-A INPUT -p tcp -m multiport --dports 143,993 -j ACCEPT"
	;;
	mta)
	eximuser=`getent passwd exim | awk -F : '{print $3}'`
	postfixuser=`getent passwd postfix | awk -F : '{print $3}'`
	if [ -z $eximuser ]; then
		mailuser=$postfixuser
	else
		mailuser=$eximuser
	fi
	INPUT="$INPUT\n-A INPUT -p tcp -m multiport --dports 25,465 -j ACCEPT"
	OUTPUT="$OUTPUT\n-A OUTPUT -p tcp -m owner --uid-owner $mailuser -m multiport --dports 25,465 -j ACCEPT"
	;;
	mysql)
	INPUT="$INPUT\n-A INPUT -p tcp --dport 3306 -j ACCEPT"
	;;
	nfs)
	INPUT="$INPUT\n-A INPUT -p tcp -m multiport --dports 111,625,737,2049 -j ACCEPT"
	;;
	pop)
	INPUT="$INPUT\n-A INPUT -p tcp -m multiport --dports 110,995 -j ACCEPT"
	;;
	esac
done

INPUT="$INPUT\n-A INPUT -s ${local_net} -p tcp -m tcp --dport 22 -j ACCEP
-A INPUT -m limit --limit 2/min -j LOG --log-prefix \"Iptables-In \" 
-A INPUT -j REJECT --reject-with icmp-host-prohibited"
OUTPUT="$OUTPUT\n-A OUTPUT -d $dns -p udp -m udp --dport 53 -j ACCEPT
-A OUTPUT -m owner --uid-owner 0 -j ACCEPT
-A OUTPUT -m limit --limit 2/min -j LOG --log-prefix \"Iptables-OUT \" 
-A OUTPUT -j REJECT --reject-with icmp-host-prohibited"

echo -e "${INPUT}"
echo -e "${OUTPUT}"
