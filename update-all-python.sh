#!/bin/sh
##

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/tmp/emil_packages_install.log"
OS_TYPE=""
PKG_INSTALL=""
PKG_CHECK=""
PKG_UPDATE=""
PKG_STATUS=""

# Store skipped packages
SKIPPED_PACKAGES=""

# Auto-restart flag
AUTO_RESTART=1

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

check_python_version() {
    if python --version 2>&1 | grep -q '^Python 3\.'; then
        echo "PY3"
    elif python --version 2>&1 | grep -q '^Python 2\.'; then
        echo "PY2"
    else
        echo "UNKNOWN"
    fi
}

get_python_subversion() {
    python -c "import platform; print(platform.python_version())" 2>/dev/null || python --version 2>&1 | awk '{print $2}'
}

# حزم أساسية
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
openvpn
rtmpdump
unrar
zip
xz
zstd
astra-sm
gstplayer
mtd-utils
util-linux-sfdisk
ofgwrite
"

# حزم اختيارية - سيتم تخطيها إذا لم تكن متوفرة
OPTIONAL_PACKAGES="
p7zip
kernel-module-nandsim
mtd-utils-jffs2
lzo
mtd-utils-ubifs
packagegroup-base-nfs
"

PACKAGES_PY3="
python3-requests
python3-pillow
python3-six
python3-certifi
python3-chardet
python3-idna
python3-urllib3
python3-beautifulsoup4
python3-lxml
python3-sqlite3
python3-misc
python3-compression
python3-codecs
python3-json
python3-html
python3-difflib
python3-unixadmin
python3-shell
python3-threading
python3-email
python3-xml
python3-multiprocessing
python3-pyexecjs
python3-xmlrpc
python3-twisted-web
python3-treq
python3-core
python3-cryptography
python3-netclient
python3-pyopenssl
python3-futures3
python3-backports-lzma
python3-cfscrape
python3-dateutil
python3-fuzzywuzzy
python3-future
python3-levenshtein
python3-mmap
python3-mechanize
python3-netserver
python3-pkgutil
python3-pycurl
python3-pycryptodome
python3-pydoc
python3-rarfile
python3-pysocks
python3-requests-cache
python3-transmission-rpc
python3-zoneinfo
python3-setuptools
"

PACKAGES_PY2="
python-requests
python-pillow
python-six
python-certifi
python-chardet
python-idna
python-urllib3
python-beautifulsoup4
python-lxml
python-sqlite3
python-misc
python-compression
python-codecs
python-json
python-subprocess
python-html
python-difflib
python-distutils
python-unixadmin
python-shell
python-threading
python-email
python-xml
python-zlib
python-pyexecjs
python-xmlrpc
python-twisted-web
python-cryptography
python-netclient
python-pyopenssl
python-futures
python-lzma
python-argparse
python-mechanize
python-mmap
python-ndg-httpsclient
python-pycrypto
python-pydoc
python-robotparser
python-setuptools
"

COMMON_PACKAGES="
enigma2-plugin-extensions-weatherplugin
enigma2-plugin-extensions-mediascanner
enigma2-plugin-systemplugins-commoninterfaceassignment
enigma2-plugin-systemplugins-serviceapp
enigma2-plugin-extensions-e2iplayer-deps
ffmpeg
gstplayer
exteplayer3
gstreamer1.0-plugins-good
gstreamer1.0-plugins-base
gstreamer1.0-plugins-bad
gstreamer1.0-plugins-ugly
transmission
transmission-client
livestreamersrv
"

check_package_manager() {
    info "Checking package manager..."
    
    if command -v apt-get > /dev/null 2>&1; then
        OS_TYPE="DreamOS"
        PKG_INSTALL="apt-get install -y"
        PKG_CHECK="dpkg -l"
        PKG_UPDATE="apt-get update"
        PKG_STATUS="/var/lib/dpkg/status"
        success "apt-get detected (DreamOS)"
        return 0
    elif command -v opkg > /dev/null 2>&1; then
        OS_TYPE="OpenSource"
        PKG_INSTALL="opkg install"
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
    info "Updating package list..."
    
    if [ "$OS_TYPE" = "OpenSource" ]; then
        rm -f /run/opkg.lock 2>/dev/null
        rm -rf /var/cache/opkg/* 2>/dev/null
    fi
    
    if $PKG_UPDATE >> "$LOG_FILE" 2>&1; then
        success "Package list updated successfully"
        return 0
    else
        error "Failed to update package list"
        return 1
    fi
}

# Check if package exists in feeds
package_exists() {
    local pkg="$1"
    if [ "$OS_TYPE" = "OpenSource" ]; then
        opkg info "$pkg" 2>/dev/null | grep -q "^Package:"
        return $?
    else
        apt-cache show "$pkg" 2>/dev/null | grep -q "^Package:"
        return $?
    fi
}

is_package_installed() {
    local pkg="$1"
    
    if [ "$OS_TYPE" = "OpenSource" ]; then
        if opkg list-installed 2>/dev/null | grep -q "^$pkg "; then
            return 0
        fi
        return 1
    else
        dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
        return $?
    fi
}

get_packages_list() {
    local py_version=$(check_python_version)
    local all_packages="$BASE_PACKAGES $COMMON_PACKAGES"
    
    if [ "$py_version" = "PY3" ]; then
        all_packages="$all_packages $PACKAGES_PY3"
    elif [ "$py_version" = "PY2" ]; then
        all_packages="$all_packages $PACKAGES_PY2"
    fi
    
    # Add optional packages
    all_packages="$all_packages $OPTIONAL_PACKAGES"
    
    echo "$all_packages" | tr ' ' '\n' | sort -u | grep -v '^$'
}

get_missing_packages() {
    local missing_list=""
    local packages_list=$(get_packages_list)
    
    for pkg in $packages_list; do
        if ! is_package_installed "$pkg"; then
            missing_list="$missing_list $pkg"
        fi
    done
    
    echo "$missing_list"
}

install_package() {
    local pkg="$1"
    local count="$2"
    local total="$3"
    
    echo ""
    echo -e "${CYAN}[$count/$total]${NC} Installing: ${YELLOW}$pkg${NC}"
    
    # Check if package exists in feeds first
    if ! package_exists "$pkg"; then
        warning "Package $pkg not found in feeds - skipping"
        log "Package $pkg not found in feeds - skipping"
        echo -e "${YELLOW}⚠ Package not available in feeds: $pkg${NC}"
        # Add to skipped packages list
        SKIPPED_PACKAGES="$SKIPPED_PACKAGES $pkg"
        return 2  # Return 2 for "skipped"
    fi
    
    # Install package
    if [ "$OS_TYPE" = "DreamOS" ]; then
        apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1
    else
        opkg install "$pkg" >> "$LOG_FILE" 2>&1
    fi
    
    local install_status=$?
    
    # Verify installation immediately
    sleep 1
    if is_package_installed "$pkg"; then
        echo -e "${GREEN}✓ Successfully installed: $pkg${NC}"
        log "Successfully installed: $pkg"
        return 0
    else
        echo -e "${RED}✗ Failed to install: $pkg${NC}"
        error "Failed to install: $pkg"
        return 1
    fi
}

install_packages() {
    local missing_packages="$1"
    local total_packages=$(get_packages_list | wc -l)
    local missing_count=$(echo "$missing_packages" | wc -w)
    local installed_count=$((total_packages - missing_count))
    
    echo ""
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}       PACKAGE INSTALLATION STATUS${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${YELLOW}Package Manager:${NC} $OS_TYPE"
    echo -e "${YELLOW}Total packages in list:${NC} $total_packages"
    echo -e "${GREEN}Already installed:${NC} $installed_count"
    echo -e "${BLUE}Packages to install:${NC} $missing_count"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    
    if [ -z "$missing_packages" ]; then
        success "All required packages are already installed"
        return 0
    fi
    
    local count=0
    local success_count=0
    local failed_count=0
    local skipped_count=0
    local failed_packages=""
    local skipped_packages_list=""
    
    for pkg in $missing_packages; do
        count=$((count + 1))
        install_package "$pkg" "$count" "$missing_count"
        local result=$?
        case $result in
            0) success_count=$((success_count + 1)) ;;
            1) 
                failed_count=$((failed_count + 1))
                failed_packages="$failed_packages $pkg"
                ;;
            2)
                skipped_count=$((skipped_count + 1))
                skipped_packages_list="$skipped_packages_list $pkg"
                ;;
        esac
    done
    
    echo ""
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}       INSTALLATION SUMMARY${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${GREEN}Successfully installed:${NC} $success_count"
    if [ $skipped_count -gt 0 ]; then
        echo -e "${YELLOW}Skipped (not in feeds):${NC} $skipped_count"
        echo -e "${YELLOW}Skipped packages:${NC} $skipped_packages_list"
    fi
    if [ $failed_count -gt 0 ]; then
        echo -e "${RED}Failed to install:${NC} $failed_count"
        echo -e "${RED}Failed packages:${NC} $failed_packages"
    fi
    echo -e "${CYAN}=========================================${NC}"
    echo ""
}

install_python_specific_libraries() {
    info "Installing Python version specific libraries..."
    
    local python_ver=$(get_python_subversion)
    info "Detected Python version: $python_ver"
    
    case "$python_ver" in
        3.13.*)
            warning "Python 3.13 detected - skipping specific libraries as they are not available in feeds"
            warning "This is normal and will not affect functionality"
            return 0
            ;;
        2.7.*)
            info "Installing Python 2.7 specific libraries..."
            if [ "$OS_TYPE" = "DreamOS" ]; then
                apt-get install -y libavcodec58 libavformat58 libpython2.7-1.0 >> "$LOG_FILE" 2>&1
            else
                opkg install libavcodec58 libavformat58 libpython2.7-1.0 >> "$LOG_FILE" 2>&1 2>/dev/null
            fi
            ;;
        3.9.*|3.10.*|3.11.*|3.12.*)
            info "Installing Python libraries for version $python_ver..."
            if [ "$OS_TYPE" = "DreamOS" ]; then
                apt-get install -y libavcodec60 libavformat60 >> "$LOG_FILE" 2>&1
            else
                opkg install libavcodec60 libavformat60 >> "$LOG_FILE" 2>&1 2>/dev/null
            fi
            ;;
        *)
            warning "No specific libraries for Python version $python_ver"
            ;;
    esac
}

verify_installation() {
    info "Verifying installation..."
    
    local packages_list=$(get_packages_list)
    
    echo ""
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}       VERIFICATION REPORT${NC}"
    echo -e "${CYAN}=========================================${NC}"
    
    local missing_count=0
    local verified_count=0
    local missing_packages=""
    local optional_missing=""
    
    for pkg in $packages_list; do
        if is_package_installed "$pkg"; then
            echo -e "${GREEN}✓ Verified: $pkg${NC}"
            verified_count=$((verified_count + 1))
        else
            # Check if this is an optional package that was skipped
            echo "$OPTIONAL_PACKAGES" | grep -q "$pkg"
            if [ $? -eq 0 ]; then
                # This is an optional package, show as optional missing
                echo -e "${YELLOW}○ Optional (not available): $pkg${NC}"
                optional_missing="$optional_missing $pkg"
            else
                echo -e "${RED}✗ Missing: $pkg${NC}"
                missing_count=$((missing_count + 1))
                missing_packages="$missing_packages $pkg"
                log "Missing: $pkg"
            fi
        fi
    done
    
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${GREEN}Total verified:${NC} $verified_count"
    if [ -n "$optional_missing" ]; then
        echo -e "${YELLOW}Optional (not in feeds):${NC} $(echo "$optional_missing" | wc -w)"
    fi
    if [ $missing_count -gt 0 ]; then
        echo -e "${RED}Required missing packages:${NC} $missing_count"
        echo -e "${RED}Missing list:${NC} $missing_packages"
    fi
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    
    if [ $missing_count -eq 0 ]; then
        if [ -n "$optional_missing" ]; then
            success "All required packages installed! Optional packages not available in feeds."
        else
            success "All packages verified successfully!"
        fi
    else
        warning "$missing_count required packages could not be verified."
        warning "These packages may be critical for functionality."
    fi
}

cleanup() {
    info "Cleaning up temporary files and cache..."
    
    rm -f /tmp/installed_packages.tmp
    
    if [ "$OS_TYPE" = "OpenSource" ]; then
        rm -rf /var/cache/opkg/* 2>/dev/null
        rm -rf /var/lib/opkg/lists/* 2>/dev/null
        rm -f /run/opkg.lock 2>/dev/null
        info "opkg cache cleaned"
    else
        apt-get clean >> "$LOG_FILE" 2>&1
        info "apt-get cache cleaned"
    fi
    
    success "Cleanup completed"
}

show_report() {
    echo ""
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}       INSTALLATION REPORT${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${YELLOW}System Type:${NC} $OS_TYPE"
    echo -e "${YELLOW}Python Version:${NC} $(get_python_subversion)"
    echo -e "${YELLOW}Log file:${NC} $LOG_FILE"
    echo ""
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "${BLUE}Last 15 lines of log:${NC}"
        echo -e "${CYAN}-----------------------------------------${NC}"
        tail -n 15 "$LOG_FILE"
        echo -e "${CYAN}-----------------------------------------${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}To view full log:${NC} cat $LOG_FILE"
    echo -e "${CYAN}=========================================${NC}"
}

restart_enigma2() {
    if [ "$AUTO_RESTART" = "1" ]; then
        echo ""
        echo -e "${YELLOW}Restarting Enigma2 in 3 seconds...${NC}"
        sleep 3
        info "Restarting Enigma2"
        echo -e "${GREEN}Restarting Enigma2...${NC}"
        killall -9 enigma2 2>/dev/null
    else
        echo ""
        echo -e "${YELLOW}Auto-restart is disabled. Please restart Enigma2 manually.${NC}"
    fi
}

main() {
    clear
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}   Emil Package Installer v2.5${NC}"
    echo -e "${CYAN}   Complete Package Management${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    
    echo "Starting installation at $(date)" > "$LOG_FILE"
    
    # Check root
    if [ "$(id -u)" != "0" ]; then
        error "This script must be run as root"
        exit 1
    fi
    
    # Check internet
    info "Checking internet connection..."
    if ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1; then
        success "Internet connection is available"
    else
        error "No internet connection detected"
        exit 1
    fi
    
    # Check package manager
    check_package_manager || exit 1
    
    # Update package list
    update_package_list || exit 1
    
    # Check Python version
    local py_version=$(check_python_version)
    local py_subversion=$(get_python_subversion)
    if [ "$py_version" = "PY3" ]; then
        info "Python 3 detected ($py_subversion)"
    elif [ "$py_version" = "PY2" ]; then
        info "Python 2 detected ($py_subversion)"
    else
        warning "Python version not detected"
    fi
    
    # Install main packages
    MISSING=$(get_missing_packages)
    install_packages "$MISSING"
    
    # Install Python-specific libraries
    install_python_specific_libraries
    
    # Verify installation
    verify_installation
    
    # Cleanup
    cleanup
    
    # Show report
    show_report
    
    # Auto restart
    restart_enigma2
}

main
