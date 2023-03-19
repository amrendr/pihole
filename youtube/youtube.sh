#!/bin/sh

# The script will create a file with all the youtube ads found in hostsearch and from the logs of the Pi-hole


repoDir='/home/amar/youtube'
adlist='/etc/pihole/list.3.raw.githubusercontent.com.domains'
blacklist="$repoDir/black.list"
tempblacklist="$repoDir/temp.black.list"
ignorelist="$repoDir/ignore.list"


sudo curl 'https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/ignore.list' > $ignorelist
sudo curl 'https://raw.githubusercontent.com/amrendr/pihole/main/youtube/ignore.list' >> $ignorelist


echo 'blacklist'
sudo curl 'https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/black.list' > $tempblacklist

echo 'Create list from blocked domain list'
sudo /usr/bin/sqlite3 /etc/pihole/gravity.db "select domain from domainlist where domain like '%googlevideo.com'" > $blacklist


# check to see if gawk is installed. if not it will install it
dpkg -l | grep -qw gawk || sudo apt-get install gawk -y

# Remove duplicates
echo 'Remove duplicates'
gawk -i inplace '!a[$0]++' $tempblacklist
wait
gawk -i inplace '!a[$0]++' $blacklist
wait
gawk -i inplace '!a[$0]++' $ignorelist
wait

# Remove already blocked domain from templist
echo 'Remove adlist from potential blacklist'
while read line ;  do  sed -i "/.*$line.*/d" $tempblacklist ; done < $adlist
wait
echo 'Remove existing blacklist from potential blacklist'
while read line ;  do  sed -i "/.*$line.*/d" $tempblacklist ; done < $blacklist
wait

echo 'Remove ignored list from potential blacklist'
# remove the domains from the ignore.list 
while read line ;  do  sed -i "/.*$line.*/d" $tempblacklist ; done < $ignorelist
wait

echo 'Remove existing blacklisted domain'
# this in case you have an old blocked domain the the database 
sudo /usr/bin/sqlite3 /etc/pihole/gravity.db "delete from domainlist where domain like '%googlevideo.com%' "


echo 'add to blacklist domain'
## adding it to the blacklist in Pihole V5 
# only 200 Domains at once
sudo xargs -a $tempblacklist -L200 pihole -b -nr
# restart dns  
sudo pihole restartdns reload-lists
