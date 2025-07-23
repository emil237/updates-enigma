#!/bin/sh

version="Emil PANEL"

if python --version 2>&1 | grep -q '^Python 3\.'; then
    PYTHON="PY3"
    echo "✅ You have Python3 image"
elif python --version 2>&1 | grep -q '^Python 2\.'; then
    PYTHON="PY2"
    echo "✅ You have Python2 image"
else
    echo "❌ Python not detected"
    exit 1
fi

if command -v apt-get >/dev/null 2>&1; then
    INSTALL="apt-get install -y"
    CHECK_INSTALLED="dpkg -l"
    OS='DreamOS'
    echo "📦 Package Manager: apt-get (DreamOS)"
    apt-get update >/dev/null 2>&1
elif command -v opkg >/dev/null 2>&1; then
    INSTALL="opkg install"
    CHECK_INSTALLED="opkg list-installed"
    OS='OpenSource'
    echo "📦 Package Manager: opkg (OpenSource)"
    rm -f /run/opkg.lock
    rm -rf /var/cache/opkg/*
    opkg update >/dev/null 2>&1
else
    echo "❌ No supported package manager found"
    exit 1
fi

is_installed_opkg() {
    grep -q "Package: $1" /var/lib/opkg/status && grep -A1 "Package: $1" /var/lib/opkg/status | grep -q "Status: install ok installed"
}

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
"gstreamer1.0-plugins-ugly" "alsa-utils" "openvpn"
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
"alsa-plugins" "alsa-utils" "openvpn"
)

if [ "$PYTHON" = "PY3" ]; then
    PACKAGES=("${PACKAGESPY3[@]}")
else
    PACKAGES=("${PACKAGESPY2[@]}")
fi

echo ""
echo "🔧 Installing Required Packages..."
for PACKAGE in "${PACKAGES[@]}"; do
    if [ "$OS" = "OpenSource" ]; then
        if is_installed_opkg "$PACKAGE"; then
            echo "✅ $PACKAGE already installed"
        else
            echo "➡ Installing $PACKAGE..."
            $INSTALL "$PACKAGE" >/dev/null 2>&1
        fi
    else
        if $CHECK_INSTALLED | grep -qw "$PACKAGE"; then
            echo "✅ $PACKAGE already installed"
        else
            echo "➡ Installing $PACKAGE..."
            $INSTALL "$PACKAGE" >/dev/null 2>&1
        fi
    fi
done

echo ""
echo "🧹 Cleaning Cache..."
rm -rf /var/cache/opkg/* >/dev/null 2>&1
rm -rf /var/volatile/tmp/opkg* >/dev/null 2>&1

echo ""
echo "✅✅✅ All dependencies installed successfully ✅✅✅"
echo ""
sleep 2
exit 0



