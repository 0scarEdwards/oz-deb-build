# Oz Debian Build Script

A comprehensive Debian system build tool for configuring fresh installations and joining Active Directory environments. This script automates the complete process of setting up a Debian system with proper user management, SSH access, and domain integration.

## Overview

The Oz Debian Build Script automates the complex process of configuring a fresh Debian installation for enterprise use. It handles all necessary steps including hostname configuration, package installation, SSH server setup, domain joining, user permission management, and additional software installation.

## Features

- **Emergency Access**: Creates OZBACKUP account for emergency system access
- **Hostname Configuration**: Sets up the PC's hostname as specified
- **Sudo Installation**: Installs and configures sudo package
- **SSH Server Setup**: Installs and enables SSH for remote access
- **Domain Integration**: Joins system to Active Directory using realm
- **User Management**: Configures IT admin and main user accounts as sudoers
- **Home Directory Creation**: Automatic home directory setup for all users
- **Additional Software**: Support for installing .sh and .deb packages
- **Comprehensive Logging**: Detailed logging with automatic log file opening on failure
- **Demo Mode**: Dry-run mode to preview changes without making them
- **Visual Theming**: Uses figlet and lolcat for enhanced display

## Requirements

- **Root privileges (MANDATORY)** - Script must be run with `sudo`
- Debian-based system (tested with Debian, may work with Ubuntu)
- Active Directory domain access
- Admin credentials for the target domain
- Network connectivity to domain controllers

## Installation

1. Download the script to your system
2. Make it executable:
   ```bash
   chmod +x oz-deb-build.sh
   ```
3. **Run as root (REQUIRED)**:
   ```bash
   sudo ./oz-deb-build.sh
   ```
   
   **Note**: The script will automatically check for root privileges and exit if not run with sudo.

## Usage

### Standard Build Process
```bash
sudo ./oz-deb-build.sh
```
The script will prompt for:
- OZBACKUP account password (emergency access)
- PC hostname
- Domain admin account
- Domain name to join
- IT admin usernames (multiple can be added)
- Main end user account

### Demo Mode
```bash
sudo ./oz-deb-build.sh --demo
```
Shows what would happen without making any changes. No permanent changes will be made to the system.

### Help
```bash
sudo ./oz-deb-build.sh --help
```
Displays usage information and options.

## Project Structure

```
Oz-Deb-Build/
├── oz-deb-build.sh        # Main build script
├── README.md              # This documentation file
└── LICENSE                # MIT License
```

## Code Analysis

### File Breakdown
- **Main Script**: `oz-deb-build.sh` (941 lines)
- **Documentation**: `README.md`, `LICENSE`

### Function Breakdown

#### Core Functions
- `main()`: Entry point and overall script flow control
- `parse_arguments()`: Command line argument processing
- `check_root()`: Root privilege verification

#### Logging and Error Handling
- `init_logging()`: Log file initialization and setup
- `log_message()`: Structured message logging
- `log_command()`: Command execution logging
- `handle_failure()`: Comprehensive error handling and recovery guidance

#### Display and User Interface
- `display_banner()`: Script banner with figlet/lolcat theming
- `display_step()`: Step header display
- `show_help()`: Help information display

#### System Operations
- `get_user_input()`: User input collection for system configuration
- `set_hostname()`: Hostname configuration
- `install_sudo()`: Sudo package installation
- `install_ssh_server()`: SSH server installation and configuration
- `configure_system_services()`: System service configuration

#### Domain Operations
- `install_domain_packages()`: Domain-related package installation
- `join_domain()`: Domain join process using realm
- `configure_mkhomedir()`: Automatic home directory creation setup

#### User Management
- `configure_domain_users()`: Domain user configuration and sudo setup

#### Additional Features
- `install_additional_software()`: Additional software installation support
- `final_setup()`: Final configuration and reboot prompt

### Key Features Explained

#### Automated Package Installation
The script automatically installs required packages including sudo, SSH server, and domain integration tools without requiring manual intervention.

#### Domain Join Process
The script uses the `realm join` command to integrate the system with Active Directory, handling all necessary configuration automatically.

#### User Configuration
- IT admin users are configured as sudoers with full administrative privileges
- Main user is configured as a sudoer for regular administrative tasks
- All users get home directories created automatically

#### SSH Server Setup
The script installs and enables SSH server for remote access, making the system accessible for remote administration.

#### Additional Software Support
The script supports installation of additional software packages:
- **Shell Scripts (.sh)**: Made executable and run automatically
- **Debian Packages (.deb)**: Installed with dependency resolution

## Build Process

1. **User Input Collection**: Gathers OZBACKUP password, hostname, domain details, and user information
2. **Emergency Account Creation**: Creates OZBACKUP account for emergency access
3. **Hostname Configuration**: Sets the PC's hostname as specified
4. **Sudo Installation**: Installs sudo package for administrative access
5. **SSH Server Setup**: Installs and enables SSH for remote access
6. **System Services**: Configures system services and masks sleep targets
7. **Domain Packages**: Installs required packages for domain integration
8. **Domain Join**: Joins the system to the specified domain
9. **Mkhomedir Configuration**: Sets up automatic home directory creation
10. **User Configuration**: Configures all users as sudoers with home directories
11. **Additional Software**: Optional installation of additional packages
12. **Final Setup**: Completes configuration and prompts for reboot

## Safety Features

- **Emergency Access**: OZBACKUP account for emergency system access
- **Demo Mode**: Test the build process without making changes
- **Comprehensive Logging**: All operations are logged for troubleshooting
- **Error Handling**: Detailed error messages and recovery guidance
- **User Confirmation**: Prompts for critical operations like reboot
- **Progress Tracking**: Clear indication of each step being performed

## Logging

The script creates detailed logs in `/root/build_log_YYYYMMDD_HHMMSS.log` including:
- All command executions and their output
- Error messages and warnings
- User configuration details
- System setup information

Log files are automatically opened in a text editor if the script fails, providing immediate access to troubleshooting information.

## Dependencies

The script automatically installs these packages:
- `sudo` - Administrative privileges
- `openssh-server` - SSH server for remote access
- `libnss-sss` - System Security Services
- `libpam-sss` - PAM modules for SSS
- `sssd` - System Security Services Daemon
- `sssd-tools` - SSSD management tools
- `adcli` - Active Directory command line interface
- `samba-common-bin` - Samba utilities
- `figlet` - ASCII art display
- `lolcat` - Coloured output

## Version History

- **v2.0.0**: Complete rewrite with domain join functionality, SSH server setup, and enhanced user management
- **v1.0.0**: Initial release with basic domain setup features

## Troubleshooting

Common issues and solutions:

1. **Domain Join Failures**: Verify domain admin credentials and network connectivity
2. **SSH Connection Issues**: Check firewall settings and SSH service status
3. **Sudo Permission Problems**: Reboot may be required for sudo permissions to take effect
4. **Package Installation Errors**: Ensure internet connectivity and package repository access

## Support

For issues and questions:
1. Check the log files in `/root/build_log_*.log`
2. Ensure all requirements are met before running the script
3. Use demo mode to test the process without making changes

The script includes comprehensive error handling and will provide specific guidance based on the type of failure encountered.

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.

---

<!--
⢀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⣠⣤⣶⣶
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⢰⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣀⣀⣾⣿⣿⣿⣿
⣿⣿⣿⣿⣿⡏⠉⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿
⣿⣿⣿⣿⣿⣿⠀⠀⠀⠈⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⠁⠀⣿
⣿⣿⣿⣿⣿⣿⣧⡀⠀⠀⠀⠀⠙⠿⠿⠿⠻⠿⠿⠟⠿⠛⠉⠀⠀⠀⠀⠀⣸⣿
⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣴⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⢰⣹⡆⠀⠀⠀⠀⠀⠀⣭⣷⠀⠀⠀⠸⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠈⠉⠀⠀⠤⠄⠀⠀⠀⠉⠁⠀⠀⠀⠀⢿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⢾⣿⣷⠀⠀⠀⠀⡠⠤⢄⠀⠀⠀⠠⣿⣿⣷⠀⢸⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⡀⠉⠀⠀⠀⠀⠀⢄⠀⢀⠀⠀⠀⠀⠉⠉⠁⠀⠀⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿
Coded By Oscar
-->
