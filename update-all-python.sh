#!/bin/bash

version="Emil PANEL"

left=">>>>"
right="<<<<"
LINE1="---------------------------------------------------------"
LINE2="-------------------------------------------------------------------------------------"

echo "$LINE1"
echo "> Installing dependencies be patient ... > it takes 2 to 15 minutes please wait..."
echo "$LINE1"
sleep 2
echo "> start of process ..."
sleep 1

if python --version 2>&1 | grep -q '^Python 3\.'; then
    PYTHON="PY3"
    echo "You have Python3 image"
elif python --version 2>&1 | grep -q '^Python 2\.'; then
    PYTHON="PY2"
    echo "You have Python2 image"
else
    echo "Python not detected"
    exit 1
fi

if command -v apt-get >/dev/null 2>&1; then
    INSTALL="apt-get install -y"
    CHECK_INSTALLED="dpkg -l"
    UPDATE="apt-get update"
    OS='DreamOS'
    STATUS='/var/lib/dpkg/status'
    echo "Package Manager: apt-get (DreamOS)"
    $UPDATE >/dev/null 2>&1
elif command -v opkg >/dev/null 2>&1; then
    INSTALL="opkg install"
    CHECK_INSTALLED="opkg list-installed"
    UPDATE="opkg update"
    OS='OpenSource'
    STATUS='/var/lib/opkg/status'
    echo "Package Manager: opkg (OpenSource)"
    rm -f /run/opkg.lock
    rm -rf /var/cache/opkg/*
    $UPDATE >/dev/null 2>&1
else
    echo "No supported package manager found"
    exit 1
fi

is_installed_opkg() {
    grep -q "Package: $1" "$STATUS" && grep -A1 "Package: $1" "$STATUS" | grep -q "Status: install ok installed"
}

install_package() {
    local pkg=$1
    echo "$LINE2"
    sleep 0.5
    
    if [ "$OS" = "OpenSource" ]; then
        if is_installed_opkg "$pkg"; then
            echo "$pkg already installed"
        else
            echo -e "> Need to install ${left} $pkg ${right} please wait..."
            $INSTALL "$pkg" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "✓ $pkg installed successfully"
            else
                echo "✗ Failed to install $pkg"
            fi
        fi
    else
        if $CHECK_INSTALLED | grep -qw "^ii.*$pkg"; then
            echo "$pkg already installed"
        else
            echo -e "> Need to install ${left} $pkg ${right} please wait..."
            $INSTALL "$pkg" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "✓ $pkg installed successfully"
            else
                echo "✗ Failed to install $pkg"
            fi
        fi
    fi
}

BASE_PACKAGES=(
    "wget" "alsa-plugins" "alsa-utils" "bzip2" "curl" 
    "duktape" "dvbsnoop" "libusb-1.0-0" "libxml2" 
    "libxslt" "openvpn" "p7zip" "rtmpdump" "unrar" 
    "zip" "xz" "zstd" "astra-sm" "gstplayer"
)

PACKAGESPY3=(
    "alsa-plugins" "p7zip" "wget" "python3-requests" "python3-imaging"
    "python3-lxml" "python3-multiprocessing" "python3-pyexecjs"
    "python3-sqlite3" "python3-six" "python3-codecs" "python3-compression"
    "python3-difflib" "python3-xmlrpc" "python3-html" "python3-misc"
    "python3-shell" "python3-twisted-web" "python3-unixadmin" "python3-treq"
    "python3-core" "python3-cryptography" "python3-json" "python3-netclient"
    "python3-pyopenssl" "python3-futures3" "libusb-1.0-0" "unrar" "curl"
    "libxml2" "libxslt" "enigma2-plugin-systemplugins-serviceapp" "rtmpdump"
    "duktape" "astra-sm" "gstplayer" "gstreamer1.0-plugins-good"
    "gstreamer1.0-plugins-base" "gstreamer1.0-plugins-bad"
    "gstreamer1.0-plugins-ugly" "alsa-utils" "openvpn" "apt-transport-https"
    "enigma2" "enigma2-plugin-extensions-e2iplayer-deps"
    "exteplayer3" "ffmpeg" "transmission" "transmission-client"
    "livestreamersrv" "python3-backports-lzma" "python3-beautifulsoup4"
    "python3-certifi" "python3-chardet" "python3-cfscrape"
    "python3-dateutil" "python3-fuzzywuzzy" "python3-future"
    "python3-levenshtein" "python3-mmap" "python3-mechanize"
    "python3-ndg-httpsclient" "python3-netserver" "python3-pillow"
    "python3-pkgutil" "python3-pycurl" "python3-pycrypto"
    "python3-pycryptodome" "python3-pydoc" "python3-rarfile"
    "python3-pysocks" "python3-requests-cache" "python3-transmission-rpc"
    "python3-urllib3" "python3-zoneinfo" "alsa-conf" "alsa-state"
    "alsa-utils-aplay" "perl-module-io-zlib" "libasound2"
)

PACKAGESPY2=(
    "p7zip" "wget" "python-imaging" "python-lxml" "python-requests"
    "python-pyexecjs" "python-sqlite3" "python-six" "python-codecs"
    "python-compression" "python-difflib" "python-xmlrpc" "python-html"
    "python-misc" "python-shell" "python-subprocess" "python-twisted-web"
    "python-unixadmin" "python-cryptography" "python-json" "python-netclient"
    "python-pyopenssl" "python-futures" "libusb-1.0-0" "unrar" "curl"
    "libxml2" "libxslt" "enigma2-plugin-systemplugins-serviceapp"
    "python-lzma" "rtmpdump" "hlsdl" "duktape" "f4mdump" "astra-sm"
    "gstplayer" "gstreamer1.0-plugins-good" "gstreamer1.0-plugins-base"
    "gstreamer1.0-plugins-bad" "gstreamer1.0-plugins-ugly"
    "alsa-plugins" "alsa-utils" "openvpn" "apt-transport-https"
    "enigma2" "enigma2-plugin-extensions-e2iplayer-deps"
    "exteplayer3" "ffmpeg" "transmission" "transmission-client"
    "python-argparse" "python-beautifulsoup4" "python-certifi"
    "python-chardet" "python-mechanize" "python-mmap"
    "python-ndg-httpsclient" "python-pycrypto" "python-pydoc"
    "python-robotparser" "python-urllib3" "alsa-conf" "alsa-state"
    "alsa-utils-aplay" "perl-module-io-zlib" "libasound2"
)

if [ "$PYTHON" = "PY3" ]; then
    PACKAGES=("${BASE_PACKAGES[@]}" "${PACKAGESPY3[@]}")
else
    PACKAGES=("${BASE_PACKAGES[@]}" "${PACKAGESPY2[@]}")
fi

PACKAGES=($(echo "${PACKAGES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

echo ""
echo "Installing Required Packages..."
echo "$LINE1"

for PACKAGE in "${PACKAGES[@]}"; do
    install_package "$PACKAGE"
done

echo ""
echo "> Installing additional libraries based on Python version..."
sleep 1

python_version=$(python -c "import platform; print(platform.python_version())" 2>/dev/null)
if [ $? -ne 0 ]; then
    python_version=$(python --version 2>&1 | awk '{print $2}')
fi

case $python_version in
    2.7.*)
        echo "Installing Python 2.7 specific libraries..."
        $INSTALL libavcodec58 libavformat58 libpython2.7-1.0 >/dev/null 2>&1
        ;;
    3.9.*)
        echo "Installing Python 3.9 specific libraries..."
        $INSTALL libavcodec58 libavformat58 libpython3.9-1.0 >/dev/null 2>&1
        ;;
    3.10.*)
        echo "Installing Python 3.10 specific libraries..."
        $INSTALL libavcodec60 libavformat60 libpython3.10-1.0 >/dev/null 2>&1
        ;;
    3.11.*)
        echo "Installing Python 3.11 specific libraries..."
        $INSTALL libavcodec60 libavformat60 libpython3.11-1.0 >/dev/null 2>&1
        ;;
    3.12.*)
        echo "Installing Python 3.12 specific libraries..."
        $INSTALL libavcodec60 libavformat60 libpython3.12-1.0 >/dev/null 2>&1
        ;;
    3.13.*)
        echo "Installing Python 3.13 specific libraries..."
        $INSTALL libavcodec60 libavformat60 libpython3.13-1.0 >/dev/null 2>&1
        ;;
    *)
        echo "No specific libraries for Python version $python_version"
        ;;
esac

echo ""
echo "> Cleaning cache and updating feeds..."
if [ "$OS" = "OpenSource" ]; then
    rm -rf /var/cache/opkg/* >/dev/null 2>&1
    rm -rf /var/lib/opkg/lists/* >/dev/null 2>&1
    rm -rf /run/opkg.lock >/dev/null 2>&1
    echo "> cache is cleaned... updating feeds please wait..."
    opkg update >/dev/null 2>&1
else
    apt-get clean >/dev/null 2>&1
fi

echo ""
echo "$LINE1"
echo "> All dependencies installed successfully!"
echo "> Process completed successfully."
echo "$LINE1"
echo ""
sleep 3

echo "You can now use your system normally."
echo "If you need to reboot, please do it manually."
echo ""

exit 0

