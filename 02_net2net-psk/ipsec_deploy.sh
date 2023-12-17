#!/bin/bash

## NOTE:
## before running the script, customize the values of variables suitable for your deployment. 

outdir="out"

moon="local-test"
sun="wcdi-test"

outdirmoon="$outdir/$moon"
outdirsun="$outdir/$sun"

swanconf="swanctl.conf"
strongswanconf="strongswan.conf"
updown="_updown.sh"

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
    mkdir "$outdirmoon"
fi 

## Directorios
if [ ! -d $outdirsun ]; then
    mkdir "$outdirsun"
fi 


## Enable IPv4 forwarding
#echo "net.ipv4.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf 
#echo "net.ipv4.conf.default.forwarding=1" | sudo tee -a /etc/sysctl.conf 
#sysctl -p

## MOON ##

echo "MOON: add ipsec.conf"
cat <<EOF > "$outdir/$moon/$swanconf"
connections {

   gw-gw {
      local_addrs  = $moonip
      remote_addrs = $sunip

      local {
         auth = psk
         id = $moonid
      }
      remote {
         auth = psk
         id = $sunip
      }
      children {
         net-net {
            local_ts  = $moonsubnet
            remote_ts = $sunsubnet

            updown = /usr/local/libexec/ipsec/_updown iptables
            rekey_time = 5400
            rekey_bytes = 500000000
            rekey_packets = 1000000
            esp_proposals = aes128gcm128-x25519
         }
      }
      version = 2
      mobike = no
      reauth_time = 10800
      proposals = aes128-sha256-x25519
   }
}

secrets {
   ike-1 {
      id-1 = $moonid
      secret = $secret
   }
   ike-2 {
      id-2 = $sunid
      secret = $secret
   }
   ike-3 {
      id-3a = $moonid
      id-3b = $sunid
      secret = $secret
   }
}

EOF


## SUN ##

echo "SUN: add $swanconf"
cat <<EOF > "$outdir/$sun/$swanconf"
connections {

   gw-gw {
      local_addrs  = $sunip
      remote_addrs = $moonip

      local {
         auth = psk
         id = $sunid
      }
      remote {
         auth = psk
         id = $moonip
      }
      children {
         net-net {
            local_ts  = $sunnsubnet
            remote_ts = $moonsubnet

            updown = /usr/local/libexec/ipsec/_updown iptables
            rekey_time = 5400
            rekey_bytes = 500000000
            rekey_packets = 1000000
            esp_proposals = aes128gcm128-x25519
         }
      }
      version = 2
      mobike = no
      reauth_time = 10800
      proposals = aes128-sha256-x25519
   }
}

secrets {
   ike-1 {
      id-1 = $moonid
      secret = $secret
   }
   ike-2 {
      id-2 = $sunid
      secret = $secret
   }
   ike-3 {
      id-3a = $sunid
      id-3b = $moonid
      secret = $secret
   }
}

EOF


## COMMON ##
echo "COMMON: add strongswan.conf"
cat <<EOF > "$outdir/$strongswanconf"
# /etc/strongswan.conf - strongSwan configuration file

swanctl {
  load = pem pkcs1 x509 revocation constraints pubkey openssl random
}

charon-systemd {
  load = random nonce aes sha1 sha2 hmac kdf pem pkcs1 x509 revocation curve25519 gmp curl kernel-netlink socket-default updown vici
}

EOF

echo "COMMON: add updown.sh"
cat <<EOF > "$outdir/$updown"
#!/bin/bash

PROG="$(basename $0)"

_ip()
{
  logger -i -t "$PROG" ip "$@"
  ip "$@"
}

logger -i -t "$PROG" "$0 $@"

case "$PLUTO_VERB" in

up-host)
  TUNNEL_NAME="$PLUTO_CONNECTION"
  LOCAL="$PLUTO_ME"
  REMOTE="$PLUTO_PEER"

  _ip link set "$TUNNEL_NAME" type gre local "$LOCAL" remote "$REMOTE"

  # disable martian filtering on unnumbered links; Required for doing OSPF over unnumbered links.
  sysctl -q -w "net.ipv4.conf.$TUNNEL_NAME.rp_filter=0"
  ;;

down-host)
	;;

esac

exit 0

EOF


#Copy files
/usr/bin/scp "$outdir/$moon/$swanconf" "jam@$moon:/home/jam"
/usr/bin/scp "$outdir/$sun/$swanconf" "jam@$sun:/home/jam"
/usr/bin/scp "$outdir/$strongswanconf" "jam@$moon:/home/jam"
/usr/bin/scp "$outdir/$strongswanconf" "jam@$sun:/home/jam"
/usr/bin/scp "$outdir/$updown" "jam@$moon:/home/jam"
/usr/bin/scp "$outdir/$updown" "jam@$sun:/home/jam"