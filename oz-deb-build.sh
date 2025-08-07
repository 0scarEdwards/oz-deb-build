#!/bin/bash
# =============================================================================
# Oz's Debian Domain Build Script
# Version: 2.0.0
# =============================================================================
#
# This script automates the domain setup process after a fresh Debian installation.
# It configures users, sudoers, SSH server, and joins the system to a domain.
#
# Features:
# - Hostname configuration
# - Sudo installation and configuration
# - SSH server installation and setup
# - Domain join with realm
# - IT admin user management with sudoer privileges
# - Main user setup and configuration
# - Home directory creation and management
# - Additional software installation
# - Automatic reboot handling
# - Comprehensive logging and error handling
#
# =============================================================================

# Global variables
SCRIPT_NAME="oz-deb-build.sh"
SCRIPT_VERSION="2.0.0"
DEMO_MODE=false
HOSTNAME=""
DOMAIN_ADMIN=""
DOMAIN_NAME=""
IT_ADMINS=()
MAIN_USER=""
OZBACKUP_PASSWORD=""
LOG_FILE=""

# Quick root check before any operations
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (use sudo)"
    echo "Usage: sudo $SCRIPT_NAME [OPTIONS]"
    echo ""
    echo "Examples:"
    echo "  sudo $SCRIPT_NAME                    # Standard build process"
    echo "  sudo $SCRIPT_NAME --demo            # Demo mode"
    echo "  sudo $SCRIPT_NAME --help            # Show help"
    exit 1
fi

# Function: Initialize logging
init_logging() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="/root/build_log_${timestamp}.log"
    
    # Initialize log file
    cat > "$LOG_FILE" << EOF
=== Oz Debian Build Log ===
Script: $SCRIPT_NAME
Version: $SCRIPT_VERSION
Started: $(date)
User: $(whoami)
Hostname: $(hostname)
================================

EOF
    
    echo "Log file initialized: $LOG_FILE"
}

# Function: Log message
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also echo to console for user feedback
    case "$level" in
        "ERROR")
            echo "ERROR: $message" >&2
            ;;
        "WARNING")
            echo "WARNING: $message"
            ;;
        "INFO")
            echo "INFO: $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Function: Log command execution
log_command() {
    local command="$1"
    local description="$2"
    
    log_message "INFO" "Executing: $description"
    log_message "INFO" "Command: $command"
    
    if [[ "$DEMO_MODE" == true ]]; then
        log_message "INFO" "Demo Mode: Command would be executed"
        echo "  [DEMO] Would execute: $description"
        return 0
    fi
    
    # Execute command and capture output
    local output
    local exit_code
    
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    # Log the output
    if [[ -n "$output" ]]; then
        log_message "INFO" "Output: $output"
    fi
    
    # Log the exit code
    log_message "INFO" "Exit code: $exit_code"
    
    return $exit_code
}

# Function: Handle script failure
handle_failure() {
    local exit_code=$?
    local line_number=$1
    local command="$2"
    
    log_message "ERROR" "Script failed at line $line_number"
    log_message "ERROR" "Failed command: $command"
    log_message "ERROR" "Exit code: $exit_code"
    
    echo ""
    echo "=========================================="
    echo "SCRIPT FAILED - TROUBLESHOOTING REQUIRED"
    echo "=========================================="
    echo ""
    echo "A detailed log has been created: $LOG_FILE"
    echo ""
    echo "Opening log file in GNOME text editor for troubleshooting..."
    
    # Try to open the log file in GNOME text editor
    if command -v gedit >/dev/null 2>&1; then
        gedit "$LOG_FILE" &
        log_message "INFO" "Opened log file in gedit"
    elif command -v gnome-text-editor >/dev/null 2>&1; then
        gnome-text-editor "$LOG_FILE" &
        log_message "INFO" "Opened log file in gnome-text-editor"
    else
        echo "GNOME text editor not found. Please manually open: $LOG_FILE"
        log_message "WARNING" "GNOME text editor not found, manual log review required"
    fi
    
    echo ""
    echo "Please review the log file for detailed error information."
    echo "Common troubleshooting steps:"
    echo "1. Check if running as root (use sudo)"
    echo "2. Verify internet connection for package installation"
    echo "3. Ensure all required packages are available"
    echo "4. Check disk space availability"
    echo "5. Verify user account permissions"
    echo ""
    
    exit $exit_code
}

# Set up error handling
trap 'handle_failure ${LINENO} "$BASH_COMMAND"' ERR

# Function: Display script banner
display_banner() {
    if command -v figlet >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
        if [[ "$DEMO_MODE" == true ]]; then
            echo "DEMO MODE" | figlet -f slant | lolcat
            echo "No changes will be made to the system" | figlet -f small | lolcat
        else
            echo "Oz Debian Build" | figlet -f slant | lolcat
            echo "Domain Setup Script" | figlet -f small | lolcat
        fi
    else
        if [[ "$DEMO_MODE" == true ]]; then
            echo "=== DEMO MODE ==="
            echo "No changes will be made to the system"
        else
            echo "=== Oz Debian Build Script ==="
        fi
        echo "Note: Install 'figlet' and 'lolcat' for enhanced banner display"
        echo "      sudo apt install figlet lolcat"
    fi
    echo ""
}

# =============================================================================
# Watermark
# =============================================================================
# ⢀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⣠⣤⣶⣶
# ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⢰⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣀⣀⣾⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⡏⠉⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿
# ⣿⣿⣿⣿⣿⣿⠀⠀⠀⠈⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⠁⠀⣿
# ⣿⣿⣿⣿⣿⣿⣧⡀⠀⠀⠀⠀⠙⠿⠿⠿⠻⠿⠿⠟⠿⠛⠉⠀⠀⠀⠀⠀⣸⣿
# ⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣴⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⢰⣹⡆⠀⠀⠀⠀⠀⠀⣭⣷⠀⠀⠀⠸⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠈⠉⠀⠀⠤⠄⠀⠀⠀⠉⠁⠀⠀⠀⠀⢿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⢾⣿⣷⠀⠀⠀⠀⡠⠤⢄⠀⠀⠀⠠⣿⣿⣷⠀⢸⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⡀⠉⠀⠀⠀⠀⠀⢄⠀⢀⠀⠀⠀⠀⠉⠉⠁⠀⠀⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿
# Coded By Oscar
# =============================================================================


# Function: Display step header
display_step() {
    local step="$1"
    if command -v figlet >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
        echo "$step" | figlet -f mini | lolcat
    else
        echo "=== $step ==="
    fi
    echo ""
}

# Function: Display help information
show_help() {
    display_banner
    echo "Usage: $SCRIPT_NAME [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --demo          Demo mode - show what would happen without making changes"
    echo "  --help          Show this help message"
    echo ""
    echo "Standard Usage:"
    echo "  sudo $SCRIPT_NAME"
    echo "  The script will prompt for:"
    echo "    - OZBACKUP account password (emergency access)"
    echo "    - PC hostname"
    echo "    - Domain admin account"
    echo "    - Domain name to join"
    echo "    - IT admin usernames (multiple can be added)"
    echo "    - Main end user account"
    echo ""
    echo "Examples:"
    echo "  sudo $SCRIPT_NAME                    # Standard build process"
    echo "  sudo $SCRIPT_NAME --demo            # Demo mode"
    echo ""
    echo "Features:"
    echo "  - Configures hostname"
    echo "  - Installs and configures sudo"
    echo "  - Installs and enables SSH server"
    echo "  - Joins system to domain using realm"
    echo "  - Configures IT admin users as sudoers"
    echo "  - Configures main user as sudoer"
    echo "  - Creates home directories for all users"
    echo "  - Installs additional software"
    echo "  - Handles automatic reboot after setup"
    echo "  - Comprehensive logging and error handling"
    echo "  - Automatic log file opening on failure"
    echo ""
    echo "Requirements:"
    echo "  - Must be run as root (sudo)"
    echo "  - Fresh Debian installation"
    echo "  - Internet connection for package installation"
    echo "  - Domain admin credentials"
    echo ""
}

# Function: Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root (use sudo)"
        echo "Usage: sudo $SCRIPT_NAME [OPTIONS]"
        echo ""
        echo "Examples:"
        echo "  sudo $SCRIPT_NAME                    # Standard build process"
        echo "  sudo $SCRIPT_NAME --demo            # Demo mode"
        echo "  sudo $SCRIPT_NAME --help            # Show help"
        exit 1
    fi
    
    # Additional check to ensure we have root privileges
    if ! sudo -n true 2>/dev/null; then
        echo "Error: Root privileges required but not available"
        echo "Please run with: sudo $SCRIPT_NAME [OPTIONS]"
        exit 1
    fi
    
    log_message "INFO" "Root privileges verified"
}

# Function: Get user input
get_user_input() {
    display_step "User Configuration"
    
    log_message "INFO" "Starting user configuration"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Prompting for user information (no changes will be made)"
        echo ""
    fi
    
    echo "Please provide the following information:"
    echo ""
    
    # Get hostname
    if [[ "$DEMO_MODE" == true ]]; then
        read -p "What should the PC's hostname be set to? (demo mode): " HOSTNAME
    else
        read -p "What should the PC's hostname be set to? " HOSTNAME
    fi
    log_message "INFO" "Hostname: $HOSTNAME"
    
    if [[ -z "$HOSTNAME" ]]; then
        log_message "ERROR" "Hostname is required"
        echo "Error: Hostname is required"
        exit 1
    fi
    
    # Get domain admin account
    if [[ "$DEMO_MODE" == true ]]; then
        read -p "Domain admin account (e.g. admin@domain.com) (demo mode): " DOMAIN_ADMIN
    else
        read -p "Domain admin account (e.g. admin@domain.com): " DOMAIN_ADMIN
    fi
    log_message "INFO" "Domain admin: $DOMAIN_ADMIN"
    
    if [[ -z "$DOMAIN_ADMIN" ]]; then
        log_message "ERROR" "Domain admin account is required"
        echo "Error: Domain admin account is required"
        exit 1
    fi
    
    # Get domain name
    if [[ "$DEMO_MODE" == true ]]; then
        read -p "Domain name to join (e.g. domain.com) (demo mode): " DOMAIN_NAME
    else
        read -p "Domain name to join (e.g. domain.com): " DOMAIN_NAME
    fi
    log_message "INFO" "Domain name: $DOMAIN_NAME"
    
    if [[ -z "$DOMAIN_NAME" ]]; then
        log_message "ERROR" "Domain name is required"
        echo "Error: Domain name is required"
        exit 1
    fi
    
    echo ""
    echo "Adding IT admin users..."
    echo "Enter IT admin usernames (e.g. ITADMIN@domain.com)"
    echo "Type one username and press Enter, then type another and press Enter"
    echo "When you are finished, just press Enter with no text"
    echo ""
    
    local admin_count=0
    while true; do
        if [[ "$DEMO_MODE" == true ]]; then
            read -p "IT Admin username (e.g. ITADMIN@domain.com, or press Enter to finish) (demo mode): " admin_user
        else
            read -p "IT Admin username (e.g. ITADMIN@domain.com, or press Enter to finish): " admin_user
        fi
        
        if [[ -z "$admin_user" ]]; then
            break
        fi
        
        IT_ADMINS+=("$admin_user")
        ((admin_count++))
        echo "Added: $admin_user (Total: $admin_count)"
        log_message "INFO" "Added IT admin: $admin_user"
    done
    
    if [[ ${#IT_ADMINS[@]} -eq 0 ]]; then
        echo "Warning: No IT admin users were added"
        log_message "WARNING" "No IT admin users were added"
    fi
    
    # Get main end user account
    echo ""
    if [[ "$DEMO_MODE" == true ]]; then
        read -p "Main end user account (e.g. user@domain.com) (demo mode): " MAIN_USER
    else
        read -p "Main end user account (e.g. user@domain.com): " MAIN_USER
    fi
    log_message "INFO" "Main user: $MAIN_USER"
    
    if [[ -z "$MAIN_USER" ]]; then
        log_message "ERROR" "Main end user account is required"
        echo "Error: Main end user account is required"
        exit 1
    fi
    
    echo ""
    echo "Configuration Summary:"
    echo "  Hostname: $HOSTNAME"
    echo "  Domain Admin: $DOMAIN_ADMIN"
    echo "  Domain: $DOMAIN_NAME"
    echo "  IT Admins: ${IT_ADMINS[*]}"
    echo "  Main User: $MAIN_USER"
    echo ""
    
    if [[ "$DEMO_MODE" == true ]]; then
        read -p "Proceed with demo configuration? (y/N): " confirm
    else
        read -p "Proceed with configuration? (y/N): " confirm
    fi
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_message "INFO" "Configuration cancelled by user"
        echo "Configuration cancelled"
        exit 0
    fi
    
    log_message "INFO" "User configuration completed"
    echo ""
}

# =============================================================================
# Watermark
# =============================================================================
# ⢀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⣠⣤⣶⣶
# ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⢰⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣀⣀⣾⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⡏⠉⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿
# ⣿⣿⣿⣿⣿⣿⠀⠀⠀⠈⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⠁⠀⣿
# ⣿⣿⣿⣿⣿⣿⣧⡀⠀⠀⠀⠀⠙⠿⠿⠿⠻⠿⠿⠟⠿⠛⠉⠀⠀⠀⠀⠀⣸⣿
# ⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣴⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⢰⣹⡆⠀⠀⠀⠀⠀⠀⣭⣷⠀⠀⠀⠸⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠈⠉⠀⠀⠤⠄⠀⠀⠀⠉⠁⠀⠀⠀⠀⢿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⢾⣿⣷⠀⠀⠀⠀⡠⠤⢄⠀⠀⠀⠠⣿⣿⣷⠀⢸⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⡀⠉⠀⠀⠀⠀⠀⢄⠀⢀⠀⠀⠀⠀⠉⠉⠁⠀⠀⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿
# Coded By Oscar
# =============================================================================


# Function: Create OZBACKUP account
create_ozbackup_account() {
    display_step "Creating OZBACKUP Account"
    
    log_message "INFO" "Starting OZBACKUP account creation"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would prompt for OZBACKUP password"
        log_message "INFO" "Demo Mode: OZBACKUP account creation skipped"
        return 0
    fi
    
    echo "Creating OZBACKUP emergency account..."
    echo "This account should only be used in emergency situations."
    echo ""
    
    # Check if OZBACKUP user already exists
    if id "OZBACKUP" &>/dev/null; then
        echo "OZBACKUP account already exists. Skipping creation."
        log_message "INFO" "OZBACKUP account already exists, skipping creation"
        return 0
    fi
    
    # Get password for OZBACKUP account
    while true; do
        if [[ "$DEMO_MODE" == true ]]; then
            read -s -p "Enter password for OZBACKUP account (demo mode): " OZBACKUP_PASSWORD
            echo ""
            read -s -p "Confirm password for OZBACKUP account (demo mode): " confirm_password
            echo ""
        else
            read -s -p "Enter password for OZBACKUP account: " OZBACKUP_PASSWORD
            echo ""
            read -s -p "Confirm password for OZBACKUP account: " confirm_password
            echo ""
        fi
        
        if [[ "$OZBACKUP_PASSWORD" == "$confirm_password" ]]; then
            break
        else
            echo "Passwords do not match. Please try again."
            log_message "WARNING" "OZBACKUP password confirmation failed"
        fi
    done
    
    # Create OZBACKUP user
    log_command "useradd -m -s /bin/bash -G sudo OZBACKUP" "Create OZBACKUP user"
    log_command "echo 'OZBACKUP:$OZBACKUP_PASSWORD' | chpasswd" "Set OZBACKUP password"
    
    # Create sudoers entry for OZBACKUP
    echo "OZBACKUP ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/ozbackup
    log_message "INFO" "Created sudoers entry for OZBACKUP"
    
    echo "OZBACKUP account created successfully"
    echo "Username: OZBACKUP"
    echo "Password: [set by user]"
    log_message "INFO" "OZBACKUP account created successfully"
    echo ""
    echo "IMPORTANT: This account is for emergency access only!"
    echo "Do not use for regular operations."
    echo ""
}

# Function: Set hostname
set_hostname() {
    display_step "Setting Hostname"
    
    log_message "INFO" "Starting hostname configuration"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would set hostname to $HOSTNAME"
        log_message "INFO" "Demo Mode: Hostname configuration skipped"
        return 0
    fi
    
    echo "Setting hostname to: $HOSTNAME"
    
    # Set hostname
    log_command "hostnamectl set-hostname '$HOSTNAME'" "Set system hostname"
    
    # Update /etc/hosts
    log_command "sed -i 's/127.0.1.1.*/127.0.1.1\t$HOSTNAME/' /etc/hosts" "Update /etc/hosts"
    
    echo "Hostname configured successfully"
    log_message "INFO" "Hostname configuration completed successfully"
    echo ""
}

# Function: Install sudo
install_sudo() {
    display_step "Installing Sudo"
    
    log_message "INFO" "Starting sudo installation"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would install sudo package"
        log_message "INFO" "Demo Mode: Sudo installation skipped"
        return 0
    fi
    
    echo "Installing sudo package..."
    
    # Install sudo
    log_command "apt-get update -qq >/dev/null 2>&1" "Update package lists"
    log_command "apt-get install -y sudo" "Install sudo package"
    
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to install sudo"
        echo "Error: Failed to install sudo"
        exit 1
    fi
    
    echo "Sudo installed successfully"
    log_message "INFO" "Sudo installation completed successfully"
    echo ""
}

# Function: Install and configure SSH server
install_ssh_server() {
    display_step "Installing SSH Server"
    
    log_message "INFO" "Starting SSH server installation"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would install and configure SSH server"
        log_message "INFO" "Demo Mode: SSH server installation skipped"
        return 0
    fi
    
    echo "Installing SSH server..."
    
    # Install SSH server
    log_command "apt-get install -y openssh-server" "Install SSH server"
    
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to install SSH server"
        echo "Error: Failed to install SSH server"
        exit 1
    fi
    
    echo "Enabling and starting SSH service..."
    
    # Enable and start SSH service
    log_command "systemctl enable ssh --now" "Enable and start SSH service"
    log_command "systemctl daemon-reload" "Reload systemd daemon"
    
    echo "SSH server installed and configured successfully"
    log_message "INFO" "SSH server installation completed successfully"
    echo ""
}

# Function: Configure system services
configure_system_services() {
    display_step "Configuring System Services"
    
    log_message "INFO" "Starting system service configuration"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would configure system services"
        log_message "INFO" "Demo Mode: System service configuration skipped"
        return 0
    fi
    
    echo "Configuring system services..."
    
    # Enable and start acc service
    log_command "systemctl enable acc" "Enable acc service"
    log_command "systemctl start acc" "Start acc service"
    
    # Mask sleep targets
    log_command "systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target" "Mask sleep targets"
    
    echo "System services configured successfully"
    log_message "INFO" "System service configuration completed successfully"
    echo ""
}

# Function: Install domain packages
install_domain_packages() {
    display_step "Installing Domain Packages"
    
    log_message "INFO" "Starting domain package installation"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would install domain packages"
        log_message "INFO" "Demo Mode: Domain package installation skipped"
        return 0
    fi
    
    echo "Installing domain packages..."
    
    # Install domain packages
    local packages="libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin"
    log_command "apt-get install -y $packages" "Install domain packages"
    
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to install domain packages"
        echo "Error: Failed to install domain packages"
        exit 1
    fi
    
    echo "Domain packages installed successfully"
    log_message "INFO" "Domain package installation completed successfully"
    echo ""
}

# Function: Join domain
join_domain() {
    display_step "Joining Domain"
    
    log_message "INFO" "Starting domain join process"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would join domain $DOMAIN_NAME using $DOMAIN_ADMIN"
        log_message "INFO" "Demo Mode: Domain join skipped"
        return 0
    fi
    
    echo "Joining domain: $DOMAIN_NAME"
    echo "Using admin account: $DOMAIN_ADMIN"
    echo ""
    
    # Join domain using realm
    log_command "realm join -U '$DOMAIN_ADMIN' --install=/ -v '$DOMAIN_NAME'" "Join domain using realm"
    
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to join domain"
        echo "Error: Failed to join domain"
        echo "Please check your domain admin credentials and domain name"
        exit 1
    fi
    
    echo "Domain join completed successfully"
    log_message "INFO" "Domain join completed successfully"
    echo ""
}

# Function: Configure mkhomedir
configure_mkhomedir() {
    display_step "Configuring Mkhomedir"
    
    log_message "INFO" "Starting mkhomedir configuration"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would configure mkhomedir"
        log_message "INFO" "Demo Mode: Mkhomedir configuration skipped"
        return 0
    fi
    
    echo "Configuring mkhomedir for automatic home directory creation..."
    
    # Create mkhomedir configuration
    cat > /usr/share/pam-configs/mkhomedir << EOF
Name: activate mkhomedir
Default: yes
Priority: 900
Session-Type: Additional
Session:
        required pam_mkhomedir.so umask=0022 skel=/etc/skel
EOF
    
    log_message "INFO" "Created mkhomedir configuration"
    
    # Update PAM configuration
    log_command "pam-auth-update --package" "Update PAM configuration"
    
    echo "Mkhomedir configuration completed successfully"
    log_message "INFO" "Mkhomedir configuration completed successfully"
    echo ""
}

# Function: Configure domain users
configure_domain_users() {
    display_step "Configuring Domain Users"
    
    log_message "INFO" "Starting domain user configuration"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would configure domain users"
        log_message "INFO" "Demo Mode: Domain user configuration skipped"
        return 0
    fi
    
    echo "Configuring domain users..."
    echo ""
    
    # Configure IT admin users
    for admin in "${IT_ADMINS[@]}"; do
        echo "Configuring IT admin: $admin"
        log_message "INFO" "Configuring IT admin: $admin"
        
        # Permit logon
        log_command "realm permit '$admin'" "Permit logon for IT admin"
        
        # Add to sudo group
        log_command "adduser '$admin' sudo" "Add IT admin to sudo group"
        log_command "usermod -aG sudo '$admin'" "Add IT admin to sudo group (alternative method)"
        
        # Create home directory
        log_command "mkhomedir_helper '$admin'" "Create home directory for IT admin"
        
        echo "  Configured: $admin"
    done
    
    # Configure main user
    echo ""
    echo "Configuring main user: $MAIN_USER"
    log_message "INFO" "Configuring main user: $MAIN_USER"
    
    # Permit logon
    log_command "realm permit '$MAIN_USER'" "Permit logon for main user"
    
    # Add to sudo group
    log_command "adduser '$MAIN_USER' sudo" "Add main user to sudo group"
    log_command "usermod -aG sudo '$MAIN_USER'" "Add main user to sudo group (alternative method)"
    
    # Create home directory
    log_command "mkhomedir_helper '$MAIN_USER'" "Create home directory for main user"
    
    echo "  Configured: $MAIN_USER"
    
    # Display current sudoers
    echo ""
    echo "Current sudoers:"
    log_command "getent group sudo" "Display current sudoers"
    
    echo ""
    echo "Note: A reboot may be required for sudo permissions to take full effect"
    log_message "INFO" "Domain user configuration completed successfully"
    echo ""
}

# Function: Install additional software
install_additional_software() {
    display_step "Additional Software Installation"
    
    log_message "INFO" "Starting additional software installation"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would prompt for additional software installation"
        log_message "INFO" "Demo Mode: Additional software installation skipped"
        return 0
    fi
    
    echo "Additional software installation"
    echo "You can now install additional software packages."
    echo ""
    
    if [[ "$DEMO_MODE" == true ]]; then
        read -p "Do you have additional software to install? (y/N) (demo mode): " install_software
    else
        read -p "Do you have additional software to install? (y/N): " install_software
    fi
    if [[ ! "$install_software" =~ ^[Yy]$ ]]; then
        echo "Skipping additional software installation"
        log_message "INFO" "Additional software installation skipped by user"
        echo ""
        return 0
    fi
    
    echo ""
    echo "Supported file types:"
    echo "- .sh files (will be made executable and run)"
    echo "- .deb files (will be installed)"
    echo ""
    
    local software_count=0
    while true; do
        if [[ "$DEMO_MODE" == true ]]; then
            read -p "Enter path to software file (or press Enter to finish) (demo mode): " software_path
        else
            read -p "Enter path to software file (or press Enter to finish): " software_path
        fi
        
        if [[ -z "$software_path" ]]; then
            break
        fi
        
        if [[ ! -f "$software_path" ]]; then
            echo "Error: File not found: $software_path"
            log_message "ERROR" "Software file not found: $software_path"
            continue
        fi
        
        local file_extension="${software_path##*.}"
        local file_name=$(basename "$software_path")
        
        echo ""
        echo "Processing: $file_name"
        log_message "INFO" "Processing software file: $file_name"
        
        case "$file_extension" in
            "sh")
                echo "Detected shell script: $file_name"
                echo -n "Making executable and running... "
                
                # Make executable
                log_command "chmod +x '$software_path'" "Make script executable"
                
                # Run the script
                if "$software_path"; then
                    echo "Success"
                    log_message "INFO" "Successfully executed script: $file_name"
                else
                    echo "Failed"
                    echo "Check the script output for errors"
                    log_message "ERROR" "Failed to execute script: $file_name"
                fi
                ;;
                
            "deb")
                echo "Detected Debian package: $file_name"
                echo -n "Installing package... "
                
                # Install the package
                if dpkg -i "$software_path"; then
                    echo "Success"
                    log_message "INFO" "Successfully installed package: $file_name"
                    # Fix any dependency issues
                    apt-get install -f -qq >/dev/null 2>&1
                else
                    echo "Failed"
                    echo "Check the installation output for errors"
                    log_message "ERROR" "Failed to install package: $file_name"
                fi
                ;;
                
            *)
                echo "Unsupported file type: $file_extension"
                echo "Supported types: .sh, .deb"
                log_message "WARNING" "Unsupported file type: $file_extension"
                continue
                ;;
        esac
        
        ((software_count++))
        echo ""
    done
    
    if [[ $software_count -gt 0 ]]; then
        echo "Additional software installation completed"
        echo "Installed/processed $software_count software package(s)"
        log_message "INFO" "Additional software installation completed: $software_count packages"
    else
        echo "No additional software was installed"
        log_message "INFO" "No additional software was installed"
    fi
    
    echo ""
    
    # Ask about inventory management or anti-virus software
    echo "Additional software categories:"
    if [[ "$DEMO_MODE" == true ]]; then
        read -p "Do you need to install inventory management software? (y/N) (demo mode): " install_inventory
    else
        read -p "Do you need to install inventory management software? (y/N): " install_inventory
    fi
    if [[ "$install_inventory" =~ ^[Yy]$ ]]; then
        echo "Please provide the path to your inventory management software installer"
        log_message "INFO" "User requested inventory management software installation"
    fi
    
    if [[ "$DEMO_MODE" == true ]]; then
        read -p "Do you need to install anti-virus software? (y/N) (demo mode): " install_antivirus
    else
        read -p "Do you need to install anti-virus software? (y/N): " install_antivirus
    fi
    if [[ "$install_antivirus" =~ ^[Yy]$ ]]; then
        echo "Please provide the path to your anti-virus software installer"
        log_message "INFO" "User requested anti-virus software installation"
    fi
    
    echo ""
}

# Function: Final setup and reboot
final_setup() {
    display_step "Final Setup"
    
    log_message "INFO" "Starting final setup"
    
    if [[ "$DEMO_MODE" == true ]]; then
        echo "Demo Mode: Would complete final setup and prompt for reboot"
        log_message "INFO" "Demo Mode: Final setup skipped"
        return 0
    fi
    
    echo "Completing final setup..."
    
    # Update package lists
    echo -n "Updating package lists... "
    log_command "apt-get update -qq >/dev/null 2>&1" "Update package lists"
    echo "Done"
    
    # Install additional useful packages
    echo -n "Installing additional packages... "
    local additional_packages="curl wget vim nano htop"
    log_command "apt-get install -y $additional_packages -qq >/dev/null 2>&1" "Install additional packages"
    echo "Done"
    
    echo "Additional packages installed"
    log_message "INFO" "Additional packages installed successfully"
    echo ""
    
    # Install additional software if requested
    install_additional_software
    
    # Display completion message
    display_step "Setup Complete"
    echo "Your Debian machine is now configured and joined to $DOMAIN_NAME!"
    log_message "INFO" "Setup completed successfully for domain: $DOMAIN_NAME"
    echo ""
    echo "Configuration Summary:"
    echo "  Hostname: $HOSTNAME"
    echo "  Domain: $DOMAIN_NAME"
    echo "  IT Admins: ${IT_ADMINS[*]} (sudo access configured)"
    echo "  Main User: $MAIN_USER (sudo access configured)"
    echo "  OZBACKUP emergency account: Created with sudo access"
    echo "  SSH Server: Installed and enabled"
    echo "  Domain Join: Completed successfully"
    echo "  Home directories: Created for all users"
    echo ""
    echo "Next steps:"
    echo "1. Test user logins and sudo access"
    echo "2. Verify SSH connectivity"
    echo "3. Test domain authentication"
    echo "4. Verify all software installations"
    echo ""
    
    echo "A reboot is recommended to ensure all changes take effect properly."
    echo "This is especially important for sudo permissions to take effect immediately."
    echo ""
    
    if [[ "$DEMO_MODE" == true ]]; then
        read -p "Would you like to reboot now so that sudoer permissions take effect? (Y/n) (demo mode): " reboot_confirm
        if [[ "$reboot_confirm" =~ ^[Nn]$ ]]; then
            echo "Demo Mode: Would skip reboot"
            log_message "INFO" "Demo Mode: Reboot skipped by user"
            exit 0
        fi
        
        log_message "INFO" "Demo Mode: Would initiate system reboot"
        echo "Demo Mode: Would reboot in 10 seconds..."
        echo "Demo Mode: No actual reboot will occur"
        exit 0
    else
        read -p "Would you like to reboot now so that sudoer permissions take effect? (Y/n): " reboot_confirm
        if [[ "$reboot_confirm" =~ ^[Nn]$ ]]; then
            echo "Please reboot manually when convenient to ensure sudo permissions take effect"
            log_message "INFO" "Manual reboot requested by user"
            exit 0
        fi
        
        log_message "INFO" "Initiating system reboot"
        echo "Rebooting in 10 seconds..."
        echo "Press Ctrl+C to cancel"
        sleep 10
        reboot
    fi
}

# Function: Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --demo)
                DEMO_MODE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Function: Main execution
main() {
    # Initialize logging
    init_logging
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Check if running as root
    check_root
    
    # Execute build process
    display_banner
    get_user_input
    create_ozbackup_account
    set_hostname
    install_sudo
    install_ssh_server
    configure_system_services
    install_domain_packages
    join_domain
    configure_mkhomedir
    configure_domain_users
    final_setup
    
    log_message "INFO" "Script execution completed successfully"
}

# Run main function with all arguments
main "$@"
