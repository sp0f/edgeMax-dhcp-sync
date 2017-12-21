#!/bin/vbash

OUT_FILE="runMeOnRTR2.sh"
DST_RTR_IP="10.10.10.2"

source /opt/vyatta/etc/functions/script-template

configure

dhcp_raw_data=`show service dhcp-server shared-network-name LAN-miners subnet 192.168.16.0/20 static-mapping | grep -A2 static-mapping| sed -e ':a' -e 'N' -e '$!ba' -e 's/[\n,{]/ /g; s/--/\n/g; s/ \+/ /g; s/ mac-address//g; s/ static-mapping //g; s/ ip-address//g'`

echo "#!/bin/vbash

source /opt/vyatta/etc/functions/script-template

configure
delete service dhcp-server shared-network-name LAN-miners subnet 192.168.16.0/20 static-mapping
commit" > $OUT_FILE

while read -r line; do
    tab=($line) # (name ip mac)
    echo "set service dhcp-server shared-network-name LAN-miners subnet 192.168.16.0/20 static-mapping ${tab[0]} mac-address ${tab[2]}" >> $OUT_FILE
    echo "set service dhcp-server shared-network-name LAN-miners subnet 192.168.16.0/20 static-mapping ${tab[0]} ip-address ${tab[1]}" >> $OUT_FILE
done <<< "$dhcp_raw_data"

echo "commit
save
" >> $OUT_FILE

chmod +x $OUT_FILE

# send to rtr2
scp ./$OUT_FILE ubnt@"$DST_RTR_IP":/home/ubnt/
ssh -l ubnt "$DST_RTR_IP" /home/ubnt/$OUT_FILE
