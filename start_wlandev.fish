#!/usr/local/bin/fish
if test ! -d ~/.config/wpa_key
mkdir ~/.config/wpa_key
chmod 700 ~/.config/wpa_key
touch ~/.config/wpa_key/db
chmod 600 ~/.config/wpa_key/db
end

set iwdev ( sudo sysctl net.wlan.devices | awk '{print $2}' )

sudo ifconfig wlan0 destroy
sudo rm -rf /var/run/wpa_supplicant/wlan0
sleep 3
sudo ifconfig wlan0 create wlandev $iwdev
sudo ifconfig wlan0 up
sleep 3
sudo ifconfig wlan0 scan

set netw ""
set pwd1 ""
set pwd2 ""
set bssid ""
set save false

while test \( -z "$netw" \) -o \( "$pwd1" != "$pwd2" \);
read -P "select a wlan network: " netw
if test -z $netw ; continue; end
set bssid ( sudo ifconfig wlan0 scan | egrep "^$netw " | tail -1 | awk '{print $2}' )
set epwd ( cat ~/.config/wpa_key/db | egrep "^$bssid" | tail -1 | egrep -o " .*" | sed "s/ //" )
if test -n "$epwd"
set pwd1 $epwd
set pwd2 $epwd
else
read -P "password: " -s pwd1
read -P "retype password: " -s pwd2
set save true
end
end

if $save 
echo "$bssid $pwd1" >> ~/.config/wpa_key/db 
end

sudo sed -r '/^network=/,/^}/d' -i /etc/wpa_supplicant.conf
echo "network={
	ssid=\"$netw\"
	key_mgmt=WPA-PSK
	psk=\"$pwd1\"
}" | sudo tee -a /etc/wpa_supplicant.conf

sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf 
sudo dhclient wlan0
