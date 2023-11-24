#!/bin/sh

#

if python --version 2>&1 | grep -q '^Python 3\.'; then
   echo "You have Python3 image"
   PYTHON='PY3'
else
   echo "You have Python2 image"
   PYTHON='PY2'
fi

if [ $PYTHON = "PY3" ]; then
   opkg update && opkg upgrade
   opkg install p7zip
   opkg install wget 
   opkg install curl  
   opkg install python3-lxml 
   opkg install python3-requests  
   opkg install python3-beautifulsoup4   
   opkg install python3-cfscrape 
   opkg install livestreamersrv 
   opkg install python3-six 
   opkg install python3-sqlite3 
   opkg install python3-pycrypto 
   opkg install f4mdump python3-image  
   opkg install python3-imaging  
   opkg install python3-argparse 
   opkg install python3-multiprocessing
   opkg install python3-mmap 
   opkg install python3-ndg-httpsclient  
   opkg install python3-pydoc 
   opkg install python3-xmlrpc
   opkg install python3-certifi 
   opkg install python3-urllib3 
   opkg install python3-chardet
   opkg install python3-pysocks 
   opkg install python3-js2py 
   opkg install python3-pillow
   opkg update
   opkg install enigma2-plugin-systemplugins-serviceapp
   opkg install ffmpeg
   opkg install exteplayer3
   opkg install gstplayer
   opkg update
   opkg install gstreamer1.0-plugins-good
   opkg install gstreamer1.0-plugins-ugly
   opkg install gstreamer1.0-plugins-base
   opkg install gstreamer1.0-plugins-bad
else
   opkg update && opkg upgrade
   opkg update
   opkg install 
   opkg install wget 
   opkg install curl  
   opkg install hlsdl 
   opkg install python-lxml 
   opkg install python-requests 
   opkg install python-beautifulsoup4 
   opkg install python-cfscrape 
   opkg install livestreamer 
   opkg install vlivestreamersrv 
   opkg install python-six 
   opkg install python-sqlite3 
   opkg install python-pycrypto 
   opkg install f4mdump 
   opkg install python-image 
   opkg install python-imaging 
   opkg install python-argparse 
   opkg install python-multiprocessing 
   opkg install python-mmap 
   opkg install python-ndg-httpsclient 
   opkg install python-pydoc python-xmlrpc 
   opkg install python-certifi 
   opkg install python-urllib3 
   opkg install python-chardet 
   opkg install python-pysocks
   opkg install enigma2-plugin-systemplugins-serviceapp
    opkg install ffmpeg
    opkg install exteplayer3
    opkg install gstplayer
    opkg update
    opkg install gstreamer1.0-plugins-good
    opkg install gstreamer1.0-plugins-ugly
    opkg install gstreamer1.0-plugins-base
    opkg install gstreamer1.0-plugins-bad
fi

echo ""
sync
echo ""
echo "#         Enigma TOOLS $version INSTALLED SUCCESSFULLY              #"
echo "#      Uploded BY Emil_Nabil #"
echo "**************************************************************"
echo "#              your Device will RESTART Now                  #"
echo "**************************************************************"
echo "   UPLOADED BY  >>>>   EMIL_NABIL "   
sleep 4;
		echo 'RESTARTING GUI ...'
echo '--------------------------------------------------------------------------------'
sync; sleep 3; if which systemctl; then systemctl restart enigma2; else killall -9 enigma2; fi
exit 0
