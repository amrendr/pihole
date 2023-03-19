#!/bin/sh

# The script will create a file with all the youtube ads found in hostsearch and from the logs of the Pi-hole


repoDir='/home/amar/youtube'
adlist='/etc/pihole/list.3.raw.githubusercontent.com.domains'
blacklist="$repoDir/black.list"
tempblacklist="$repoDir/temp.black.list"
ignorelist="$repoDir/ignore.list"


sudo curl 'https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/ignore.list' > $ignorelist
sudo curl 'https://raw.githubusercontent.com/amrendr/pihole/main/youtube/ignore.list' >> $ignorelist


sudo /usr/bin/sqlite3 /etc/pihole/pihole-FTL.db "select domain from queries where domain like '%googlevideo.com'" > $tempblacklist
sudo /usr/bin/sqlite3 /etc/pihole/gravity.db "select domain from domainlist where domain like '%googlevideo.com'" > $blacklist

# Remove duplicates
gawk -i inplace '!a[$0]++' $tempblacklist
gawk -i inplace '!a[$0]++' $blacklist
gawk -i inplace '!a[$0]++' $ignorelist

# Remove already blocked domain from templist
while read line ;  do  sed -i "/.*$line.*/d" $tempblacklist ; done < $adlist
while read line ;  do  sed -i "/.*$line.*/d" $tempblacklist ; done < $blacklist

# remove the domains from the ignore.list 
while read line ;  do  sed -i "/.*$line.*/d" $tempblacklist ; done < $ignorelist

# this in case you have an old blocked domain the the database 
while read ignoredDns ; do sudo /usr/bin/sqlite3 /etc/pihole/gravity.db "delete from domainlist where domain like '%$ignoredDns%' " ; done < $ignorelist


## adding it to the blacklist in Pihole V5 
# only 200 Domains at once
sudo xargs -a $tempblacklist -L200 pihole -b -nr
# restart dns  
sudo pihole restartdns reload-lists
