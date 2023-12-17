#!/bin/bash

PROG="ipsec_deploy.sh"

_ip()
{
  logger -i -t "" ip ""
  ip ""
}

logger -i -t "" "./ipsec_deploy.sh "

case "" in

up-host)
  TUNNEL_NAME=""
  LOCAL=""
  REMOTE=""

  _ip link set "" type gre local "" remote ""

  # disable martian filtering on unnumbered links; Required for doing OSPF over unnumbered links.
  sysctl -q -w "net.ipv4.conf..rp_filter=0"
  ;;

down-host)
	;;

esac

exit 0

