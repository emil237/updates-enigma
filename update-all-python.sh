#!/bin/sh

echo "Uploaded by Emil Nabil"
sleep 4

# 
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

# 
if command -v apt-get >/dev/null 2>&1; then
    INSTALL="apt-get install -y"
    CHECK_INSTALLED="dpkg -l"
    OS='DreamOS'
    apt-get update
elif command -v opkg >/dev/null 2>&1; then
    INSTALL="opkg install --force-reinstall --force-depends"
    CHECK_INSTALLED="opkg list-installed"
    OS='Opensource'
else
    echo "Unsupported OS"
    exit 1
fi

# 
declare -A packages
  if [ "$PYTHON" = 'PY3' ]; then
    packages=(
      ["p7zip"]=1 ["libavformat58"]=1 ["libavcodec58"]=1 ["python3-cryptography"]=1 ["libgcc1"]=1 ["libc6"]=1 ["libavcodec61"]=1 ["libavformat61"]=1 ["libasound2"]=1 ["enigma2"]=1 ["alsa-plugins"]=1 ["tar"]=1 ["wget"]=1 ["zip"]=1 ["ar"]=1 ["curl"]=1 ["python3-lxml"]=1 ["python3-requests"]=1
      ["python3-beautifulsoup4"]=1 ["python3-cfscrape"]=1 ["livestreamersrv"]=1
      ["python3-six"]=1 ["python3-sqlite3"]=1 ["python3-pycrypto"]=1 ["f4mdump"]=1
      ["python3-image"]=1 ["python3-imaging"]=1 ["python3-argparse"]=1
      ["python3-multiprocessing"]=1 ["python3-mmap"]=1 ["python3-ndg-httpsclient"]=1
      ["python3-pydoc"]=1 ["python3-xmlrpc"]=1 ["python3-certifi"]=1 ["python3-urllib3"]=1
      ["python3-chardet"]=1 ["python3-pysocks"]=1 ["python3-js2py"]=1 ["python3-pillow"]=1
      ["enigma2-plugin-systemplugins-serviceapp"]=1 ["ffmpeg"]=1 ["exteplayer3"]=1
      ["gstplayer"]=1 ["gstreamer1.0-plugins-good"]=1 ["gstreamer1.0-plugins-ugly"]=1
      ["gstreamer1.0-plugins-base"]=1 ["gstreamer1.0-plugins-bad"]=1
    )
  elif [ "$PYTHON" = 'PY2' ]; then
    packages=(
      ["wget"]=1 ["tar"]=1 ["zip"]=1 ["ar"]=1 ["curl"]=1 ["hlsdl"]=1 ["python-lxml"]=1 ["python-requests"]=1
      ["python-beautifulsoup4"]=1 ["python-cfscrape"]=1 ["livestreamer"]=1
      ["python-six"]=1 ["python-sqlite3"]=1 ["python-pycrypto"]=1
      ["f4mdump"]=1 ["python-image"]=1 ["python-imaging"]=1 ["python-argparse"]=1
      ["python-multiprocessing"]=1 ["python-mmap"]=1 ["python-ndg-httpsclient"]=1
      ["python-pydoc"]=1 ["python-xmlrpc"]=1 ["python-certifi"]=1 ["python-urllib3"]=1
      ["python-chardet"]=1 ["python-pysocks"]=1 ["enigma2-plugin-systemplugins-serviceapp"]=1
      ["ffmpeg"]=1 ["exteplayer3"]=1 ["gstplayer"]=1 ["gstreamer1.0-plugins-good"]=1
      ["gstreamer1.0-plugins-ugly"]=1 ["gstreamer1.0-plugins-base"]=1 ["gstreamer1.0-plugins-bad"]=1
    )
  else
    echo "Python 2 or 3 is required." >/dev/null 2>&1
  fi

#
for package in "${!packages[@]}"; do
    if ! $CHECK_INSTALLED | grep -qw "$package"; then
        echo "Installing $package..."
        $INSTALL "$package" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "$package installed successfully."
        else
            echo "Failed to install $package."
        fi
    else
        echo "$package is already installed or up to date. Ok"
    fi
done



