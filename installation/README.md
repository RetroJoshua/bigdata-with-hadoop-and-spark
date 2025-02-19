## install_hadoop.sh
`chmod +x install_hadoop.sh`

Run it with sudo:

`sudo ./install_hadoop.sh`

Features of this script:

- Performs all installation steps automatically.
- Creates backups of modified files.
- Includes error checking for root privileges.
- Uses variables for easier version management.
- Provides clear progress indicators
- Includes cleanup of downloaded files
- Maintains proper file ownership
- Provides instructions for final steps

Important Notes:
- The script must be run with sudo privileges
- It automatically detects the actual username even when run with sudo
- Creates a backup of .bashrc before modification
- After running the script, you need to:
  - Log out and log back in, or
  - Source the .bashrc file: source ~/.bashrc
- Test the installation using the commands shown in the final output

Error Handling:
- Checks for root privileges
- Uses variables to prevent typos
- Maintains original user permissions

Remember to verify all paths and versions match your system requirements before running the script. You may need to modify the Hadoop version number if a newer version is available.

## verify_hadoop.sh

To use this script:
- Save it as `verify_hadoop.sh`
- Make it executable:
`chmod +x verify_hadoop.sh`
- Run it:
`./verify_hadoop.sh`

Features of this script:
- Color-coded output for better readability
- Comprehensive checks of all major components
- Step-by-step verification process
- Error handling and status reporting
- Optional cleanup of test files
- Detailed output for troubleshooting

The script checks:
- Java installation
- Environment variables
- Hadoop version
- Configuration files
- WordCount functionality
- Log files
- Provides a summary of all checks

Note:
- The script assumes default installation paths
- It requires appropriate permissions to run
- It creates test files in the user's home directory
- It includes cleanup option for test files
- Color coding helps identify success/failure quickly

Make sure to review any error messages if they appear during the verification process.
