#!/bin/sh

echo "Uploaded by Emil Nabil"
sleep 4

PYTHON_VERSION=$(python --version 2>&1)
if echo "$PYTHON_VERSION" | grep -q '^Python 3\.'; then
    echo "You have Python3"
    PYTHON='PY3'
elif echo "$PYTHON_VERSION" | grep -q '^Python 2\.'; then
    echo "You have Python2"
    PYTHON='PY2'
else
    echo "Python 2 or 3 is required."
    exit 1
fi

if command -v apt-get >/dev/null 2>&1; then
    INSTALL="apt-get install -y"
    CHECK_INSTALLED="dpkg -l"
    OS='DreamOS'
    apt-get update
elif command -v opkg >/dev/null 2>&1; then
    INSTALL="opkg install --force-reinstall --force-depends"
    CHECK_INSTALLED="opkg list-installed"
    OS='Opensource'
    opkg update && opkg upgrade
else
    echo "Unsupported OS"
    exit 1
fi

if [ "$PYTHON" = "PY3" ]; then
    $INSTALL p7zip wget curl python3-lxml python3-requests python3-beautifulsoup4
    $INSTALL python3-cfscrape livestreamersrv python3-six python3-sqlite3 python3-pycrypto
    $INSTALL f4mdump python3-image python3-imaging python3-argparse python3-multiprocessing
    $INSTALL python3-mmap python3-ndg-httpsclient python3-pydoc python3-xmlrpc python3-certifi
    $INSTALL python3-urllib3 python3-chardet python3-pysocks python3-js2py python3-pillow
    $INSTALL enigma2-plugin-systemplugins-serviceapp ffmpeg exteplayer3 gstplayer
    $INSTALL gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-plugins-base
    $INSTALL gstreamer1.0-plugins-bad
else
    $INSTALL wget curl hlsdl python-lxml python-requests python-beautifulsoup4
    $INSTALL python-cfscrape livestreamer vlivestreamersrv python-six python-sqlite3
    $INSTALL python-pycrypto f4mdump python-image python-imaging python-argparse
    $INSTALL python-multiprocessing python-mmap python-ndg-httpsclient python-pydoc
    $INSTALL python-xmlrpc python-certifi python-urllib3 python-chardet python-pysocks
    $INSTALL enigma2-plugin-systemplugins-serviceapp ffmpeg exteplayer3 gstplayer
    $INSTALL gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-plugins-base
    $INSTALL gstreamer1.0-plugins-bad
fi

echo ""
sync
echo ""
echo "#         Enigma TOOLS INSTALLED SUCCESSFULLY              #"
echo "**************************************************************"
echo "#              Your device will restart now                  #"
echo "**************************************************************"
reboot
wait
sleep 2
exit 0

