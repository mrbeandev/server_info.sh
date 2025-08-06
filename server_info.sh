#!/bin/bash
# Interactive Linux Server Information Menu
# Compatible with all major Linux distributions
# Author: t.me/mrbeandev
# License: MIT

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print colored headers
print_header() {
    echo -e "${CYAN}${BOLD}$1${NC}"
    echo "======================================="
}

# Function to print subheaders
print_subheader() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to pause and wait for user input
pause() {
    echo
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
}

# Function to safely get command output
safe_command() {
    if command -v $1 >/dev/null 2>&1; then
        eval $2
    else
        echo "Command '$1' not available"
    fi
}

# Function to get distro info
get_distro_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$PRETTY_NAME"
    elif [ -f /etc/redhat-release ]; then
        cat /etc/redhat-release
    elif [ -f /etc/debian_version ]; then
        echo "Debian $(cat /etc/debian_version)"
    elif [ -f /etc/arch-release ]; then
        echo "Arch Linux"
    else
        echo "Unknown Linux Distribution"
    fi
}

# Function to show system information
show_system_info() {
    clear
    print_header "📋 SYSTEM INFORMATION"
    echo "Distribution: $(get_distro_info)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Hostname: $(hostname)"
    echo "Current User: $(whoami)"
    echo "Date: $(date)"
    echo "System Uptime: $(uptime -p 2>/dev/null || uptime)"
    
    # Virtualization info
    echo
    print_subheader "🖥️  VIRTUALIZATION TYPE:"
    local virt_type="Physical/Unknown"
    
    if [ -f /proc/cpuinfo ] && grep -qi "hypervisor" /proc/cpuinfo; then
        virt_type="Virtual Machine"
    fi
    
    if [ -d /proc/xen ]; then
        virt_type="Xen VM"
    elif [ -f /proc/modules ] && grep -q "virtio" /proc/modules; then
        virt_type="KVM/QEMU VM"
    elif [ -f /sys/class/dmi/id/product_name ]; then
        product_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
        case "$product_name" in
            *"VMware"*) virt_type="VMware VM" ;;
            *"VirtualBox"*) virt_type="VirtualBox VM" ;;
            *"KVM"*) virt_type="KVM VM" ;;
            *"QEMU"*) virt_type="QEMU VM" ;;
        esac
    fi
    
    echo "Type: $virt_type"
    
    if [ -f /.dockerenv ]; then
        echo "Container: Docker"
    elif [ -f /run/.containerenv ]; then
        echo "Container: Podman"
    elif grep -q container=lxc /proc/1/environ 2>/dev/null; then
        echo "Container: LXC"
    fi
    
    pause
}

# Function to show CPU information
show_cpu_info() {
    clear
    print_header "🔥 CPU SPECIFICATIONS"
    
    if [ -f /proc/cpuinfo ]; then
        local cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d':' -f2 | sed 's/^[ \t]*//')
        local cpu_cores=$(grep -c ^processor /proc/cpuinfo)
        local cpu_mhz=$(grep -m1 "cpu MHz" /proc/cpuinfo | cut -d':' -f2 | sed 's/^[ \t]*//')
        
        echo "Model: ${cpu_model:-Unknown}"
        echo "Cores/Threads: $cpu_cores"
        echo "Current MHz: ${cpu_mhz:-Unknown}"
        echo "Architecture: $(uname -m)"
        
        if [ -f /proc/loadavg ]; then
            local load=$(cat /proc/loadavg | awk '{print $1"/"$2"/"$3}')
            echo "Load Average (1m/5m/15m): $load"
        fi
    fi
    
    if command -v lscpu >/dev/null 2>&1; then
        echo
        print_subheader "📊 DETAILED CPU INFO:"
        lscpu 2>/dev/null | grep -E "(CPU\(s\)|Thread|Core|Socket|Cache|Virtualization)" | head -10
    fi
    
    pause
}

# Function to show memory information
show_memory_info() {
    clear
    print_header "💾 MEMORY SPECIFICATIONS"
    
    if [ -f /proc/meminfo ]; then
        local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local available_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}' 2>/dev/null)
        local free_kb=$(grep MemFree /proc/meminfo | awk '{print $2}')
        
        if [ -z "$available_kb" ]; then
            available_kb=$free_kb
        fi
        
        echo "Total RAM: $((total_kb / 1024))MB ($(awk "BEGIN {printf \"%.1f\", $total_kb/1024/1024}")GB)"
        echo "Available RAM: $((available_kb / 1024))MB ($(awk "BEGIN {printf \"%.1f\", $available_kb/1024/1024}")GB)"
        echo "Free RAM: $((free_kb / 1024))MB ($(awk "BEGIN {printf \"%.1f\", $free_kb/1024/1024}")GB)"
        
        local used_kb=$((total_kb - available_kb))
        local usage_percent=$(awk "BEGIN {printf \"%.1f\", ($used_kb * 100) / $total_kb}")
        echo "Memory Usage: ${usage_percent}%"
    fi
    
    if command -v free >/dev/null 2>&1; then
        echo
        print_subheader "📊 MEMORY BREAKDOWN:"
        free -h 2>/dev/null || free
    fi
    
    if [ -f /proc/meminfo ]; then
        echo
        print_subheader "🔍 DETAILED MEMORY INFO:"
        grep -E "(MemTotal|MemFree|MemAvailable|Cached|Buffers|SwapTotal|SwapFree)" /proc/meminfo | column -t 2>/dev/null || grep -E "(MemTotal|MemFree|MemAvailable|Cached|Buffers|SwapTotal|SwapFree)" /proc/meminfo
    fi
    
    pause
}

# Function to show storage information
show_storage_info() {
    clear
    print_header "💿 STORAGE SPECIFICATIONS"
    
    print_subheader "💿 DISK USAGE:"
    if command -v df >/dev/null 2>&1; then
        df -h 2>/dev/null | grep -E "(Filesystem|/dev/|tmpfs)" | head -15
    fi
    
    echo
    print_subheader "🗂️  BLOCK DEVICES:"
    if command -v lsblk >/dev/null 2>&1; then
        lsblk 2>/dev/null | head -15
    elif [ -d /sys/block ]; then
        echo "Available block devices:"
        ls /sys/block/ | grep -E '^(sd|hd|nvme|vd|xvd)' | while read device; do
            if [ -f /sys/block/$device/size ]; then
                size_sectors=$(cat /sys/block/$device/size)
                size_gb=$((size_sectors * 512 / 1024 / 1024 / 1024))
                echo "  $device: ${size_gb}GB"
            fi
        done
    fi
    
    echo
    print_subheader "⚡ STORAGE TYPE DETECTION:"
    if [ -d /sys/block ]; then
        for device in $(ls /sys/block/ | grep -E '^(sd|hd|nvme|vd|xvd)'); do
            if [ -f /sys/block/$device/queue/rotational ]; then
                rotational=$(cat /sys/block/$device/queue/rotational 2>/dev/null)
                if [ "$rotational" = "0" ]; then
                    storage_type="SSD/NVMe"
                else
                    storage_type="HDD (Rotational)"
                fi
            else
                storage_type="Unknown"
            fi
            
            if [ -f /sys/block/$device/size ]; then
                size_sectors=$(cat /sys/block/$device/size)
                size_gb=$((size_sectors * 512 / 1024 / 1024 / 1024))
                echo "  /dev/$device: ${size_gb}GB - $storage_type"
            fi
        done
    fi
    
    pause
}

# Function to show network information
show_network_info() {
    clear
    print_header "🌐 NETWORK SPECIFICATIONS"
    
    print_subheader "🌐 NETWORK INTERFACES:"
    if command -v ip >/dev/null 2>&1; then
        ip addr show 2>/dev/null | grep -E "(inet |link/)" | grep -v "127.0.0.1" | head -10
    elif command -v ifconfig >/dev/null 2>&1; then
        ifconfig 2>/dev/null | grep -E "(inet |Link )" | head -8
    fi
    
    echo
    print_subheader "🔗 ROUTING INFO:"
    if command -v ip >/dev/null 2>&1; then
        echo "Default route:"
        ip route show default 2>/dev/null | head -3
    elif command -v route >/dev/null 2>&1; then
        echo "Default route:"
        route -n 2>/dev/null | head -3
    fi
    
    echo
    print_subheader "🌍 CONNECTIVITY TEST:"
    if command -v ping >/dev/null 2>&1; then
        echo -n "Testing internet connectivity... "
        if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Connected${NC}"
        else
            echo -e "${RED}❌ No connection${NC}"
        fi
    fi
    
    pause
}

# Function to show performance metrics
show_performance_info() {
    clear
    print_header "📈 PERFORMANCE & SYSTEM STATUS"
    
    echo "Active Processes: $(ps aux 2>/dev/null | wc -l || echo 'Unknown')"
    
    if [ -f /proc/loadavg ]; then
        echo "Load Average: $(cat /proc/loadavg)"
    fi
    
    # CPU usage (if top is available)
    if command -v top >/dev/null 2>&1; then
        echo
        print_subheader "🔥 CPU USAGE (Top 5 Processes):"
        top -bn1 | head -12 | tail -5
    fi
    
    # Memory usage
    if [ -f /proc/meminfo ]; then
        local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local available_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}' 2>/dev/null)
        local free_kb=$(grep MemFree /proc/meminfo | awk '{print $2}')
        
        if [ -z "$available_kb" ]; then
            available_kb=$free_kb
        fi
        
        local used_kb=$((total_kb - available_kb))
        local usage_percent=$(awk "BEGIN {printf \"%.1f\", ($used_kb * 100) / $total_kb}")
        echo
        echo "Memory Usage: ${usage_percent}%"
    fi
    
    # Disk I/O (if iostat is available)
    if command -v iostat >/dev/null 2>&1; then
        echo
        print_subheader "💿 DISK I/O:"
        iostat -d 1 1 2>/dev/null | tail -5 || echo "I/O stats not available"
    fi
    
    pause
}

# Function to show system limits
show_system_limits() {
    clear
    print_header "🔒 SYSTEM LIMITS & CONFIGURATION"
    
    print_subheader "🔒 ULIMITS (Current User):"
    echo "Max open files: $(ulimit -n 2>/dev/null || echo 'Unknown')"
    echo "Max processes: $(ulimit -u 2>/dev/null || echo 'Unknown')"
    echo "Max file size: $(ulimit -f 2>/dev/null || echo 'Unknown')"
    echo "Max memory size: $(ulimit -m 2>/dev/null || echo 'Unknown')"
    echo "Max stack size: $(ulimit -s 2>/dev/null || echo 'Unknown')"
    
    echo
    print_subheader "🌐 SYSTEM WIDE LIMITS:"
    if [ -f /proc/sys/fs/file-max ]; then
        echo "System max open files: $(cat /proc/sys/fs/file-max)"
    fi
    
    if [ -f /proc/sys/kernel/threads-max ]; then
        echo "System max threads: $(cat /proc/sys/kernel/threads-max)"
    fi
    
    if [ -f /proc/sys/kernel/pid_max ]; then
        echo "System max PIDs: $(cat /proc/sys/kernel/pid_max)"
    fi
    
    if [ -f /proc/sys/vm/swappiness ]; then
        echo "Swappiness: $(cat /proc/sys/vm/swappiness)"
    fi
    
    pause
}

# Function to show software information
show_software_info() {
    clear
    print_header "📦 SOFTWARE ENVIRONMENT"
    
    print_subheader "📦 PACKAGE MANAGEMENT:"
    if command -v apt >/dev/null 2>&1; then
        echo "Package Manager: APT (Debian/Ubuntu)"
        echo "Installed packages: $(dpkg -l 2>/dev/null | grep -c '^ii' || echo 'Unknown')"
    elif command -v yum >/dev/null 2>&1; then
        echo "Package Manager: YUM (RedHat/CentOS)"
        echo "Installed packages: $(yum list installed 2>/dev/null | wc -l || echo 'Unknown')"
    elif command -v dnf >/dev/null 2>&1; then
        echo "Package Manager: DNF (Fedora)"
        echo "Installed packages: $(dnf list installed 2>/dev/null | wc -l || echo 'Unknown')"
    elif command -v pacman >/dev/null 2>&1; then
        echo "Package Manager: Pacman (Arch)"
        echo "Installed packages: $(pacman -Q 2>/dev/null | wc -l || echo 'Unknown')"
    elif command -v zypper >/dev/null 2>&1; then
        echo "Package Manager: Zypper (openSUSE)"
        echo "Installed packages: $(zypper search --installed-only 2>/dev/null | wc -l || echo 'Unknown')"
    else
        echo "Package Manager: Unknown/Not detected"
    fi
    
    echo
    print_subheader "🐳 CONTAINERIZATION:"
    if command -v docker >/dev/null 2>&1; then
        echo "Docker: $(docker --version 2>/dev/null | cut -d',' -f1)"
        if docker ps >/dev/null 2>&1; then
            echo "Running containers: $(docker ps -q 2>/dev/null | wc -l)"
        fi
    fi
    
    if command -v podman >/dev/null 2>&1; then
        echo "Podman: $(podman --version 2>/dev/null)"
        if podman ps >/dev/null 2>&1; then
            echo "Running containers: $(podman ps -q 2>/dev/null | wc -l)"
        fi
    fi
    
    if ! command -v docker >/dev/null 2>&1 && ! command -v podman >/dev/null 2>&1; then
        echo "No container runtime detected"
    fi
    
    echo
    print_subheader "🔧 DEVELOPMENT TOOLS:"
    for tool in git gcc python python3 nodejs npm java go rust; do
        if command -v $tool >/dev/null 2>&1; then
            version=$($tool --version 2>/dev/null | head -1 || echo "installed")
            echo "$tool: $version"
        fi
    done
    
    pause
}

# Function to show complete overview
show_complete_overview() {
    clear
    print_header "📋 COMPLETE SERVER OVERVIEW"
    
    # System basics
    echo -e "${BOLD}🖥️  SYSTEM:${NC} $(get_distro_info) | $(uname -r) | $(uname -m)"
    
    # CPU
    if [ -f /proc/cpuinfo ]; then
        cpu_cores=$(grep -c ^processor /proc/cpuinfo)
        cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d':' -f2 | sed 's/^[ \t]*//' | cut -c1-50)
        echo -e "${BOLD}⚡ CPU:${NC} $cpu_cores cores | $cpu_model"
    fi
    
    # Memory
    if [ -f /proc/meminfo ]; then
        total_ram_gb=$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
        available_ram_gb=$(awk '/MemAvailable/ {printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null || awk '/MemFree/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
        echo -e "${BOLD}💾 RAM:${NC} ${total_ram_gb}GB total | ${available_ram_gb}GB available"
    fi
    
    # Storage
    if command -v df >/dev/null 2>&1; then
        root_usage=$(df -h / 2>/dev/null | tail -1 | awk '{print $2 " total, " $4 " free (" $5 " used)"}')
        echo -e "${BOLD}💿 STORAGE:${NC} $root_usage"
    fi
    
    # Network
    if command -v ip >/dev/null 2>&1; then
        main_ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7}' | head -1)
        echo -e "${BOLD}🌐 NETWORK:${NC} Primary IP: ${main_ip:-Unknown}"
    fi
    
    # Load
    if [ -f /proc/loadavg ]; then
        load=$(cat /proc/loadavg | awk '{print $1"/"$2"/"$3}')
        echo -e "${BOLD}📈 LOAD:${NC} $load (1m/5m/15m)"
    fi
    
    # Uptime
    echo -e "${BOLD}⏰ UPTIME:${NC} $(uptime -p 2>/dev/null || uptime | cut -d',' -f1 | cut -d' ' -f4-)"
    
    echo
    print_subheader "🔧 QUICK HEALTH CHECK:"
    
    # Memory check
    if [ -f /proc/meminfo ]; then
        total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        available_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}' 2>/dev/null || grep MemFree /proc/meminfo | awk '{print $2}')
        used_kb=$((total_kb - available_kb))
        usage_percent=$(awk "BEGIN {printf \"%.0f\", ($used_kb * 100) / $total_kb}")
        
        if [ "$usage_percent" -lt 80 ]; then
            echo -e "Memory Usage: ${GREEN}✅ $usage_percent% (Healthy)${NC}"
        elif [ "$usage_percent" -lt 90 ]; then
            echo -e "Memory Usage: ${YELLOW}⚠️  $usage_percent% (Warning)${NC}"
        else
            echo -e "Memory Usage: ${RED}🚨 $usage_percent% (Critical)${NC}"
        fi
    fi
    
    # Load check
    if [ -f /proc/loadavg ] && [ -f /proc/cpuinfo ]; then
        load_1m=$(cat /proc/loadavg | awk '{print $1}')
        cpu_cores=$(grep -c ^processor /proc/cpuinfo)
        load_percent=$(awk "BEGIN {printf \"%.0f\", ($load_1m * 100) / $cpu_cores}")
        
        if [ "$load_percent" -lt 70 ]; then
            echo -e "CPU Load: ${GREEN}✅ $load_1m/$cpu_cores cores (${load_percent}% - Healthy)${NC}"
        elif [ "$load_percent" -lt 90 ]; then
            echo -e "CPU Load: ${YELLOW}⚠️  $load_1m/$cpu_cores cores (${load_percent}% - High)${NC}"
        else
            echo -e "CPU Load: ${RED}🚨 $load_1m/$cpu_cores cores (${load_percent}% - Critical)${NC}"
        fi
    fi
    
    # Disk space check
    if command -v df >/dev/null 2>&1; then
        root_usage_num=$(df / 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
        if [ "$root_usage_num" -lt 80 ]; then
            echo -e "Root Disk Usage: ${GREEN}✅ $root_usage_num% (Healthy)${NC}"
        elif [ "$root_usage_num" -lt 90 ]; then
            echo -e "Root Disk Usage: ${YELLOW}⚠️  $root_usage_num% (Warning)${NC}"
        else
            echo -e "Root Disk Usage: ${RED}🚨 $root_usage_num% (Critical)${NC}"
        fi
    fi
    
    pause
}

# Function to display the main menu
show_menu() {
    clear
    echo -e "${WHITE}"
    echo "██╗   ██╗███╗   ██╗██╗██╗   ██╗███████╗██████╗ ███████╗ █████╗ ██╗"
    echo "██║   ██║████╗  ██║██║██║   ██║██╔════╝██╔══██╗██╔════╝██╔══██╗██║"
    echo "██║   ██║██╔██╗ ██║██║██║   ██║█████╗  ██████╔╝███████╗███████║██║"
    echo "██║   ██║██║╚██╗██║██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══██║██║"
    echo "╚██████╔╝██║ ╚████║██║ ╚████╔╝ ███████╗██║  ██║███████║██║  ██║███████╗"
    echo " ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝"
    echo -e "${NC}"
    echo -e "${CYAN}${BOLD}Interactive Linux Server Information Tool${NC}"
    echo "======================================="
    echo -e "${PURPLE}Author: t.me/mrbeandev 💖${NC}"
    echo "======================================="
    echo -e "${YELLOW}Compatible with all major Linux distributions${NC}"
    echo "======================================="
    echo
    echo -e "${BOLD}📋 SELECT AN OPTION:${NC}"
    echo
    echo -e "${GREEN} 1.${NC} 📋 System Information & Virtualization"
    echo -e "${GREEN} 2.${NC} 🔥 CPU Specifications & Performance"
    echo -e "${GREEN} 3.${NC} 💾 Memory Information & Usage"
    echo -e "${GREEN} 4.${NC} 💿 Storage & Disk Information"
    echo -e "${GREEN} 5.${NC} 🌐 Network Configuration & Status"
    echo -e "${GREEN} 6.${NC} 📈 Performance Metrics & Monitoring"
    echo -e "${GREEN} 7.${NC} 🔒 System Limits & Configuration"
    echo -e "${GREEN} 8.${NC} 📦 Software Environment & Packages"
    echo -e "${GREEN} 9.${NC} 🚀 Complete Overview & Health Check"
    echo
    echo -e "${RED} 0.${NC} 🚪 Exit"
    echo
    echo -e "${BLUE}=======================================${NC}"
    echo -n -e "${BOLD}Enter your choice [1-9, 0]: ${NC}"
}

# Main execution loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            show_system_info
            ;;
        2)
            show_cpu_info
            ;;
        3)
            show_memory_info
            ;;
        4)
            show_storage_info
            ;;
        5)
            show_network_info
            ;;
        6)
            show_performance_info
            ;;
        7)
            show_system_limits
            ;;
        8)
            show_software_info
            ;;
        9)
            show_complete_overview
            ;;
        99|q|Q|exit|quit|0)
            clear
            echo -e "${GREEN}${BOLD}"
            echo -e "🚀 Thank you for using Universal Server Info Tool! ${NC}"
            echo -e "${WHITE}======================================="
            echo -e "For more tools and updates, visit: t.me/mrbeandev"
            echo "======================================="
            echo -e "${CYAN} • Cross-platform • ${NC}"
            echo "======================================="
            exit 0
            ;;
        *)
            clear
            echo -e "${RED}❌ Invalid option. Please select 1-9 or 99 to exit.${NC}"
            echo
            pause
            ;;
    esac
done
