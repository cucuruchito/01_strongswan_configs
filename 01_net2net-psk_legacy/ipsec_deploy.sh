#!/bin/bash

## NOTE:
## before running the script, customize the values of variables suitable for your deployment. 

outdir="out/"

moon="local-test"
sun="wcdi-test"

outdirmoon="$outdir$moon"
outdirsun="$outdir$sun"

ipsecconf="ipsec.conf"
ipsecsecret="ipsec.secrets"

## variables
moonip=192.168.56.229 # Strongswan IP
moonsubnet=192.168.57.0/24 # Strongswan IP - network
moonid=@local-test.strongswan.org
secret='Yoparaserfelizquiero1camion!'
sunip=192.168.56.209 # Extremo remoto
sunsubnet=192.168.58.0/24 # Extremo remoto - network
sunid=@wcdi-test.strongswan.org

## Directorios
if [ ! -d $outdirmoon ]; then
    mkdir "$outdir$moon"
fi 

## Directorios
if [ ! -d $outdirsun ]; then
    mkdir "$outdir$sun"
fi 


## Enable IPv4 forwarding
#echo "net.ipv4.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf 
#echo "net.ipv4.conf.default.forwarding=1" | sudo tee -a /etc/sysctl.conf 
#sysctl -p

## MOON
## variables
left=$moonip
leftsubnet=$moonsubnet
leftid=$moonid
right=$sunip
rightsubnet=$sunsubnet
rightid=$sunid


echo "MOON: add ipsec.conf"
cat <<EOF > "$outdir$moon/$ipsecconf"
# /etc/ipsec.conf - strongSwan IPsec configuration file

config setup

conn %default
	ikelifetime=60m
	keylife=20m
	rekeymargin=3m
	keyingtries=1
	authby=secret
	keyexchange=ikev2
	mobike=no

conn net-net
	left=$left
	leftsubnet=$leftsubnet
	leftid=$leftid
	leftfirewall=no
	right=$right
	rightsubnet=$rightsubnet
	rightid=$rightid
	auto=add
EOF

echo "MOON: add ipsec.secret"
cat <<EOF > "$outdir$moon/$ipsecsecret"
# /etc/ipsec.secrets - strongSwan IPsec secrets file

$leftid $rightid : PSK $secret

EOF



## SUN
## variables
left=$sunip
leftsubnet=$sunsubnet
leftid=$sunid
right=$moonip
rightsubnet=$moonsubnet
rightid=$moonid


echo "SUN: add ipsec.conf"
cat <<EOF > "$outdir$sun/$ipsecconf"
# /etc/ipsec.conf - strongSwan IPsec configuration file

config setup

conn %default
	ikelifetime=60m
	keylife=20m
	rekeymargin=3m
	keyingtries=1
	authby=secret
	keyexchange=ikev2
	mobike=no

conn net-net
	left=$left
	leftsubnet=$leftsubnet
	leftid=$leftid
	leftfirewall=no
	right=$right
	rightsubnet=$rightsubnet
	rightid=$rightid
	auto=add
EOF

echo "SUN: add ipsec.secret"
cat <<EOF > "$outdir$sun/$ipsecsecret"
# /etc/ipsec.secrets - strongSwan IPsec secrets file

$leftid $rightid : PSK $secret

EOF

#Copy files
/usr/bin/scp "$outdir$moon/$ipsecconf" "jam@$moon:/home/jam"
/usr/bin/scp "$outdir$moon/$ipsecsecret" "jam@$moon:/home/jam"
/usr/bin/scp "$outdir$sun/$ipsecconf" "jam@$sun:/home/jam"
/usr/bin/scp "$outdir$sun/$ipsecsecret" "jam@$sun:/home/jam"