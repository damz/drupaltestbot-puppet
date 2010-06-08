#!/bin/bash

<% servers.each do |host| -%>
$IPTABLES -A INPUT -p <%= protocol %> --dport <%= port %> -s <%= host %> -j ACCEPT
<% end -%>
