#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

LOG_FILE="/tmp/emil_packages_install.log"
PROTECT_LOG="/tmp/emil_protect.log"
OS_TYPE=""
PKG_INSTALL=""
PKG_CHECK=""
PKG_UPDATE=""
PKG_STATUS=""
AUTO_RESTART=1
SKIP_UPGRADE=0
PYTHON_VERSION=""
PYTHON_SUBVERSION=""

INTER_PACKAGE_DELAY=2
NETWORK_PACKAGE_DELAY=4
NETWORK_CHECK_RETRIES=3
NETWORK_CHECK_TIMEOUT=3

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
export APT_LISTCHANGES_FRONTEND=none
export UCF_FORCE_CONFFOLD=1
export NEEDRESTART_MODE=a

DPKG_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confmiss"
APT_OPTS="-y -qq $DPKG_OPTS -o Acquire::ForceIPv4=true -o APT::Get::Assume-Yes=true -o APT::Get::AllowUnauthenticated=true -o Acquire::Check-Valid-Until=false"

mkdir -p /etc/needrestart/conf.d 2>/dev/null
echo '$nrconf{restart} = "a";' > /etc/needrestart/conf.d/99-emil-autorestart.conf 2>/dev/null
rm -f /etc/apt/apt.conf.d/*needrestart* 2>/dev/null
rm -f /etc/apt/apt.conf.d/*ucf* 2>/dev/null

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE"
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
    echo -e "${BLUE}[INFO]${NC} $1"
}

show_header() {
    clear
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}   Emil Package Installer v6.1${NC}"
    echo -e "${CYAN}   Smart Scan + Final Upgrade Edition${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
}

show_separator() {
    echo -e "${CYAN}---------------------------------------------------------${NC}"
}

show_big_separator() {
    echo -e "${CYAN}-------------------------------------------------------------------------------------${NC}"
}

is_network_package() {
    case "$1" in
        openvpn|networkmanager|connman|connman-*|wpa-supplicant|wpa-supplicant-*|wireless-tools|wirelesslan|iw|rfkill|hostapd|dhcpcd|udhcpc|dhcp-client|kernel-module-*|firmware-*|libusb-1.0-0|libssl*|openssl*|libcrypto*|ca-certificates|certifi|cryptography|pyopenssl|pycurl|curl|wget|nfs-utils|rpcbind|portmap|packagegroup-base-nfs|nandsim)
            return 0
            ;;
    esac
    return 1
}

check_network() {
    local i=0
    while [ $i -lt $NETWORK_CHECK_RETRIES ]; do
        if ping -c 1 -W $NETWORK_CHECK_TIMEOUT 8.8.8.8 > /dev/null 2>&1; then
            return 0
        fi
        i=$((i + 1))
        sleep 2
    done
    return 1
}

wait_for_network() {
    local wait_count=0
    local max_wait=15
    while [ $wait_count -lt $max_wait ]; do
        if check_network; then
            return 0
        fi
        wait_count=$((wait_count + 2))
        sleep 2
    done
    return 1
}

safe_sleep() {
    local seconds="$1"
    local elapsed=0
    while [ $elapsed -lt $seconds ]; do
        sleep 1
        elapsed=$((elapsed + 1))
    done
}

check_python_version() {
    info "Detecting Python version..."
    
    if python --version 2>&1 | grep -q '^Python 3\.'; then
        PYTHON_VERSION="PY3"
        success "Python 3 detected"
    elif python --version 2>&1 | grep -q '^Python 2\.'; then
        PYTHON_VERSION="PY2"
        success "Python 2 detected"
    else
        PYTHON_VERSION="UNKNOWN"
        warning "Python not detected"
    fi
    
    PYTHON_SUBVERSION=$(python -c "import platform; print(platform.python_version())" 2>/dev/null || python --version 2>&1 | awk '{print $2}')
    info "Python version: $PYTHON_SUBVERSION"
}

BASE_PACKAGES="
wget
alsa-plugins
alsa-utils
bzip2
curl
duktape
dvbsnoop
libusb-1.0-0
libxml2
libxslt
p7zip
rtmpdump
unrar
zip
xz
zstd
astra-sm
gstplayer
mtd-utils-jffs2
lzo
util-linux-sfdisk
ofgwrite
mtd-utils
mtd-utils-ubifs
"

IMPORTANT_PACKAGES="
ffmpeg
gstreamer1.0-plugins-good
gstreamer1.0-plugins-base
gstreamer1.0-plugins-bad
gstreamer1.0-plugins-ugly
exteplayer3
"

E2_IMPORTANT_PLUGINS="
enigma2-plugin-systemplugins-commoninterfaceassignment
enigma2-plugin-systemplugins-serviceapp
enigma2-plugin-systemplugins-networkbrowser
enigma2-plugin-systemplugins-videomode
enigma2-plugin-systemplugins-videotune
enigma2-plugin-systemplugins-positionersetup
enigma2-plugin-systemplugins-satfinder
enigma2-plugin-systemplugins-skinselector
enigma2-plugin-systemplugins-softwaremanager
enigma2-plugin-systemplugins-tempfancontrol
enigma2-plugin-systemplugins-grab
enigma2-plugin-extensions-mediascanner
enigma2-plugin-extensions-weatherplugin
enigma2-plugin-extensions-audiosync
enigma2-plugin-extensions-cutlisteditor
enigma2-plugin-extensions-filebrowser
enigma2-plugin-extensions-graphmultiepg
enigma2-plugin-extensions-imdb
enigma2-plugin-extensions-pictureplayer
enigma2-plugin-extensions-zaphistory
enigma2-plugin-extensions-openwebif
enigma2-plugin-extensions-rssreader
enigma2-plugin-extensions-e2iplayer-deps
"

PACKAGES_PY3="
python3-requests
python3-imaging
python3-pillow
python3-lxml
python3-multiprocessing
python3-pyexecjs
python3-sqlite3
python3-six
python3-codecs
python3-compression
python3-difflib
python3-xmlrpc
python3-html
python3-misc
python3-shell
python3-twisted-web
python3-unixadmin
python3-treq
python3-core
python3-json
python3-netclient
python3-futures3
python3-backports-lzma
python3-beautifulsoup4
python3-chardet
python3-dateutil
python3-fuzzywuzzy
python3-future
python3-levenshtein
python3-mmap
python3-mechanize
python3-netserver
python3-rarfile
python3-pysocks
python3-requests-cache
python3-urllib3
python3-zoneinfo
python3-setuptools
python3-idna
python3-threading
python3-email
python3-xml
python3-zlib
python3-distutils
"

PACKAGES_PY2="
python-requests
python-imaging
python-pillow
python-lxml
python-pyexecjs
python-sqlite3
python-six
python-codecs
python-compression
python-difflib
python-xmlrpc
python-html
python-misc
python-shell
python-subprocess
python-twisted-web
python-unixadmin
python-json
python-netclient
python-futures
python-lzma
python-beautifulsoup4
python-chardet
python-mechanize
python-mmap
python-pycrypto
python-pydoc
python-robotparser
python-urllib3
python-setuptools
python-argparse
python-idna
python-threading
python-email
python-xml
python-zlib
python-distutils
"

check_package_manager() {
    info "Checking package manager..."
    
    if command -v apt-get > /dev/null 2>&1; then
        OS_TYPE="DreamOS"
        PKG_INSTALL="apt-get $APT_OPTS install"
        PKG_CHECK="dpkg -l"
        PKG_UPDATE="apt-get $APT_OPTS update"
        PKG_STATUS="/var/lib/dpkg/status"
        success "apt-get detected (DreamOS)"
        return 0
    elif command -v opkg > /dev/null 2>&1; then
        OS_TYPE="OpenSource"
        PKG_INSTALL="opkg install --force-overwrite --force-reinstall"
        PKG_CHECK="opkg list-installed"
        PKG_UPDATE="opkg update"
        PKG_STATUS="/var/lib/opkg/status"
        success "opkg detected (OpenSource)"
        return 0
    else
        error "No supported package manager found"
        return 1
    fi
}

update_package_list() {
    info "Checking package list freshness..."
    
    if [ "$OS_TYPE" = "OpenSource" ]; then
        rm -f /run/opkg.lock 2>/dev/null
        local age=999999
        [ -f /var/lib/opkg/status ] && age=$(( $(date +%s) - $(stat -c %Y /var/lib/opkg/status 2>/dev/null || echo 0) ))
        if [ "$age" -lt 86400 ]; then
            success "Package list is fresh (${age}s old)"
            return 0
        fi
        opkg update >> "$LOG_FILE" 2>&1 && success "Package list updated" || warning "Update failed"
        return 0
    fi
    
    dpkg --configure -a $DPKG_OPTS >> "$LOG_FILE" 2>&1
    
    local age=999999
    local lists_dir="/var/lib/apt/lists"
    if [ -d "$lists_dir" ]; then
        local latest=$(find "$lists_dir" -type f -name "*Packages*" -printf '%T@\n' 2>/dev/null | sort -n | tail -1 | cut -d. -f1)
        [ -n "$latest" ] && age=$(( $(date +%s) - latest ))
    fi
    
    if [ "$age" -lt 86400 ]; then
        success "APT lists are fresh (updated $(( age / 3600 ))h ago) - skipping update"
        return 0
    fi
    
    info "APT lists are old - updating..."
    if apt-get $APT_OPTS update >> "$LOG_FILE" 2>&1; then
        success "Package list updated"
    else
        warning "apt update failed (continuing)"
    fi
    return 0
}

is_package_installed() {
    local pkg="$1"
    if [ "$OS_TYPE" = "OpenSource" ]; then
        if opkg list-installed 2>/dev/null | grep -q "^$pkg[[:space:]]"; then
            return 0
        fi
        return 1
    else
        if dpkg-query -W -f='${Status}\n' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            return 0
        fi
        return 1
    fi
}

get_packages_list() {
    local all_packages="$BASE_PACKAGES $IMPORTANT_PACKAGES $E2_IMPORTANT_PLUGINS"
    
    if [ "$PYTHON_VERSION" = "PY3" ]; then
        all_packages="$all_packages $PACKAGES_PY3"
    elif [ "$PYTHON_VERSION" = "PY2" ]; then
        all_packages="$all_packages $PACKAGES_PY2"
    fi
    
    echo "$all_packages" | tr ' ' '\n' | sort -u | grep -v '^$'
}

install_version_specific_libs() {
    info "Installing Python version-specific libraries..."
    
    local py_ver="$PYTHON_SUBVERSION"
    local libs=""
    
    case $py_ver in
        2.7*) libs="libavcodec58 libavformat58 libpython2.7-1.0" ;;
        3.9*) libs="libavcodec58 libavformat58 libpython3.9-1.0" ;;
        3.10*) libs="libavcodec60 libavformat60 libpython3.10-1.0" ;;
        3.11*) libs="libavcodec60 libavformat60 libpython3.11-1.0" ;;
        3.12*) libs="libavcodec60 libavformat60 libpython3.12-1.0" ;;
        3.13*) libs="libavcodec60 libavformat60 libpython3.13-1.0" ;;
        3.14*) libs="libavcodec61 libavformat61 libpython3.14-1.0" ;;
        *)
            warning "No specific libraries for Python version $py_ver"
            return 0
            ;;
    esac
    
    local needed=""
    for lib in $libs; do
        if ! is_package_installed "$lib"; then
            needed="$needed $lib"
        fi
    done
    
    if [ -z "$needed" ]; then
        success "Python libraries already installed"
        return 0
    fi
    
    info "Installing:$needed"
    if [ "$OS_TYPE" = "DreamOS" ]; then
        dpkg --configure -a $DPKG_OPTS >> "$LOG_FILE" 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS install $needed >> "$LOG_FILE" 2>&1
    else
        opkg install --force-overwrite $needed >> "$LOG_FILE" 2>&1
    fi
}

install_packages() {
    local packages_list=$(get_packages_list)
    local total_packages=$(echo "$packages_list" | wc -l)
    
    info "Fast-scanning $total_packages packages..."
    
    local installed_db=""
    local available_db=""
    
    if [ "$OS_TYPE" = "OpenSource" ]; then
        installed_db=$(opkg list-installed 2>/dev/null | awk '{print $1}')
        available_db=$(opkg list 2>/dev/null | awk '{print $1}' | sort -u)
    else
        installed_db=$(dpkg-query -W -f='${Package}\n' 2>/dev/null)
        available_db=$(apt-cache pkgnames 2>/dev/null | sort -u)
    fi
    
    local missing_packages=""
    local installed_count=0
    local not_available_count=0
    local not_available_list=""
    
    for pkg in $packages_list; do
        if echo "$installed_db" | grep -qx "$pkg"; then
            installed_count=$((installed_count + 1))
        elif echo "$available_db" | grep -qx "$pkg"; then
            missing_packages="$missing_packages $pkg"
        else
            not_available_count=$((not_available_count + 1))
            not_available_list="$not_available_list $pkg"
            log "Not in feeds: $pkg"
        fi
    done
    
    local missing_count=0
    [ -n "$missing_packages" ] && missing_count=$(echo "$missing_packages" | wc -w)
    
    echo ""
    show_big_separator
    echo -e "${CYAN}       SMART SCAN SUMMARY${NC}"
    show_big_separator
    echo -e "${YELLOW}Package Manager:${NC} $OS_TYPE"
    echo -e "${YELLOW}Python Version:${NC} $PYTHON_SUBVERSION"
    echo -e "${YELLOW}Total packages:${NC} $total_packages"
    echo -e "${GREEN}Already installed:${NC} $installed_count"
    echo -e "${BLUE}To install now:${NC} $missing_count"
    echo -e "${YELLOW}Not in feeds:${NC} $not_available_count"
    show_big_separator
    echo ""
    
    if [ "$missing_count" -eq 0 ]; then
        success "Nothing to install - all available packages are present!"
        return 0
    fi
    
    info "Installing $missing_count package(s)..."
    echo ""
    
    local success_count=0
    local failed_count=0
    local failed_list=""
    
    for pkg in $missing_packages; do
        echo -e "${CYAN}→ Installing:${NC} ${YELLOW}$pkg${NC}"
        
        if [ "$OS_TYPE" = "DreamOS" ]; then
            dpkg --configure -a $DPKG_OPTS >> "$LOG_FILE" 2>&1
            DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS install "$pkg" >> "$LOG_FILE" 2>&1
            if ! is_package_installed "$pkg"; then
                DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS --fix-broken install "$pkg" >> "$LOG_FILE" 2>&1
            fi
        else
            opkg install --force-overwrite --force-reinstall "$pkg" >> "$LOG_FILE" 2>&1
        fi
        
        if is_package_installed "$pkg"; then
            echo -e "  ${GREEN}✓ Installed${NC}"
            success_count=$((success_count + 1))
        else
            echo -e "  ${RED}✗ Failed${NC}"
            failed_count=$((failed_count + 1))
            failed_list="$failed_list $pkg"
        fi
        
        if is_network_package "$pkg"; then
            safe_sleep $NETWORK_PACKAGE_DELAY
            wait_for_network
        else
            safe_sleep $INTER_PACKAGE_DELAY
        fi
    done
    
    echo ""
    show_big_separator
    echo -e "${CYAN}       INSTALLATION FINAL REPORT${NC}"
    show_big_separator
    echo -e "${GREEN}Successfully installed:${NC} $success_count"
    echo -e "${YELLOW}Already present:${NC} $installed_count"
    echo -e "${YELLOW}Not in feeds:${NC} $not_available_count"
    if [ $failed_count -gt 0 ]; then
        echo -e "${RED}Failed:${NC} $failed_count"
        echo -e "${RED}Failed packages:$NC$failed_list"
    fi
    show_big_separator
    echo ""
}

cleanup_cache() {
    info "Cleaning package cache..."
    
    if [ "$OS_TYPE" = "OpenSource" ]; then
        rm -f /run/opkg.lock 2>/dev/null
        success "OpenSource lock cleaned"
    else
        dpkg --configure -a $DPKG_OPTS >> "$LOG_FILE" 2>&1
        apt-get clean 2>/dev/null
        success "DreamOS cache cleaned"
    fi
}

final_apt_upgrade() {
    if [ "$OS_TYPE" != "DreamOS" ]; then
        warning "Skipping final upgrade (not DreamOS)"
        return 0
    fi
    
    if [ "$SKIP_UPGRADE" = "1" ]; then
        info "Final upgrade skipped (SKIP_UPGRADE=1)"
        return 0
    fi
    
    info "Running final system upgrade (apt update && apt upgrade)..."
    
    dpkg --configure -a $DPKG_OPTS >> "$LOG_FILE" 2>&1
    
    echo -e "${CYAN}[FINAL] Running: apt update${NC}"
    if DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS update >> "$LOG_FILE" 2>&1; then
        success "apt update completed"
    else
        warning "apt update had errors (continuing anyway)"
    fi
    
    echo -e "${CYAN}[FINAL] Running: apt upgrade (non-interactive)${NC}"
    if DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS upgrade >> "$LOG_FILE" 2>&1; then
        success "apt upgrade completed"
    else
        warning "First upgrade attempt failed, retrying with --fix-broken..."
        DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS --fix-broken upgrade >> "$LOG_FILE" 2>&1 \
            && success "apt upgrade completed (fix-broken)" \
            || warning "apt upgrade failed (continuing anyway)"
    fi
    
    dpkg --configure -a $DPKG_OPTS >> "$LOG_FILE" 2>&1
    
    success "Final system upgrade finished"
}

show_report() {
    echo ""
    show_big_separator
    echo -e "${CYAN}       INSTALLATION REPORT${NC}"
    show_big_separator
    echo -e "${YELLOW}System Type:${NC} $OS_TYPE"
    echo -e "${YELLOW}Python Version:${NC} $PYTHON_SUBVERSION"
    echo -e "${YELLOW}Log file:${NC} $LOG_FILE"
    echo ""
    
    echo -e "${BLUE}Last 15 lines of log:${NC}"
    show_separator
    tail -n 15 "$LOG_FILE"
    show_separator
    
    echo ""
    echo -e "${YELLOW}To view full log:${NC} cat $LOG_FILE"
    show_big_separator
}

restart_enigma2() {
    if [ "$AUTO_RESTART" = "1" ]; then
        echo ""
        echo -e "${YELLOW}Restarting Enigma2 in 3 seconds...${NC}"
        sleep 3
        info "Restarting Enigma2"
        echo -e "${GREEN}Restarting Enigma2...${NC}"
        killall -9 enigma2 2>/dev/null
        echo -e "${GREEN}Enigma2 restarted successfully!${NC}"
    else
        echo ""
        echo -e "${YELLOW}Auto-restart disabled. Please restart manually.${NC}"
        echo -e "${YELLOW}Command: killall -9 enigma2${NC}"
    fi
}

main() {
    show_header
    
    echo "Starting installation at $(date)" > "$LOG_FILE"
    log "========================================="
    log "Emil Package Installer v6.1 Started"
    log "========================================="
    
    if [ "$(id -u)" != "0" ]; then
        error "This script must be run as root"
        exit 1
    fi
    
    info "Checking internet connection..."
    if ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1; then
        success "Internet connection available"
    else
        warning "No internet connection detected"
    fi
    
    check_package_manager || exit 1
    
    update_package_list
    
    check_python_version
    
    install_version_specific_libs
    
    echo ""
    show_separator
    echo -e "${BLUE}Smart scan and install missing packages...${NC}"
    show_separator
    echo ""
    
    install_packages
    
    cleanup_cache
    
    show_separator
    echo -e "${BLUE}Running final system upgrade (update + upgrade)...${NC}"
    echo -e "${YELLOW}This may take several minutes, please wait...${NC}"
    show_separator
    final_apt_upgrade
    
    show_report
    
    restart_enigma2
    
    echo ""
    echo -e "${GREEN}Process completed successfully!${NC}"
    echo -e "${YELLOW}You can now use your system normally.${NC}"
    echo ""
    
    log "========================================="
    log "Emil Package Installer v6.1 Finished"
    log "========================================="
}

main

exit 0
