#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Function to display menu
show_menu() {
    echo "           Menu           "
    echo "1. Create groups and users"
    echo "2. Create directories and set permissions"
    echo "3. Change group IDs and check"
    echo "4. Display user groups"
    echo "5. Rename a user"
    echo "6. Show hashed passwords file"
    echo "7. Switch to a different user"
    echo "8. Install and configure Apache with custom pages"
    echo "9. Change group ownership of directories"
    echo "10. Network configuration"
    echo "11. Delete users and groups"
    echo "12. Exit"
    echo -n "Please choose an option: "
}

# Function to create groups and users
create-groups-users() {
    read -p "Enter the first group name (default frontend): " group1
    read -p "Enter the second group name (default backend): " group2
    group1=${group1:-frontend}
    group2=${group2:-backend}

    sudo groupadd $group1 2>/dev/null || echo "Group $group1 already exists."
    sudo groupadd $group2 2>/dev/null || echo "Group $group2 already exists."
    echo "Groups checked/created."

    for i in {1..10}; do
        if ! id "user${i}_$group1" &>/dev/null; then
            sudo useradd -m -G $group1 -p $(openssl passwd -1 SecurePass123) user${i}_$group1
        else
            echo "User user${i}_$group1 already exists."
        fi
    done
    for i in {11..20}; do
        if ! id "user${i}_$group2" &>/dev/null; then
            sudo useradd -m -G $group2 -p $(openssl passwd -1 SecurePass123) user${i}_$group2
        else
            echo "User user${i}_$group2 already exists."
        fi
    done
    echo "Users checked/created."
}

# Function to create directories and set permissions
create_directories_and_set_permissions() {
    sudo mkdir -p /var/www/frontend /var/www/backend
    sudo chown :"$group1" /var/www/frontend
    sudo chown :"$group2" /var/www/backend
    sudo chmod 775 /var/www/frontend
    sudo chmod 775 /var/www/backend
    echo "Directories created and permissions set."
}

# Function to change group IDs and check
change_group_ids() {
    if getent group "$group1"  &>/dev/null && ! getent group 1002 &>/dev/null; then
        sudo groupmod -g 1002 "$group1"
        echo "Group ID for $group1 changed to 1002."
    else
        echo "Group $group1 does not exist or ID 1002 is in use."
    fi

    if getent group "$group2" &>/dev/null && ! getent group 1003 &>/dev/null; then
        sudo groupmod -g 1003 "$group2"
        echo "Group ID for $group2 changed to 1003."
    else
        echo "Group $group2 does not exist or ID 1003 is in use."
    fi

    getent group "$group1"
    getent group "$group2"
}

# Function to display user groups
display() {
    for i in {1..20}; do
        if id "user${i}_$group1" &>/dev/null; then
            groups "user${i}_$group1"
        elif id "user${i}_$group2" &>/dev/null; then
            groups "user${i}_$group2"
        else
            echo "User user${i} does not exist in frontend or backend groups."
        fi
    done
}

# Function to rename a user
rename_user() {
    read -p "Would you like to rename a user? (y/n): " response
    if [[ $response == "y" || $response == "Y" ]]; then
        read -p "Enter a new username (default admin_network): " new_name
        new_name=${new_name:-admin_network}
        if id "user2_$group1" &>/dev/null; then
            sudo usermod -l $new_name user2_$group
            echo "User renamed to $new_name."
        else
            echo "User user2 does not exist."
        fi
    else
        echo "No changes made to the username."
    fi
}

# Function to show hashed passwords file
show_password_hashes() {
    for i in {1..20}; do

      sudo cat /etc/shadow | grep -E "user${i}_($group1|$group2)"
      done

}


# Function to switch to a different user
switch_to_user() {
     if id "user3_$group1"; then
        sudo -i -u "user3_$group1" bash -c "echo 'Welcome!' && exec bash"
    else
        echo "User does not exist."
    fi
}

# Function to install and configure Apache
install_and_configure_apache() {
    if ! command -v apache2 &>/dev/null; then
        echo "Apache is not installed, installing..."
        sudo apt update && sudo apt install apache2 -y
    fi

    sudo mkdir -p /var/www/frontend /var/www/backend
    echo "<h1>Apache Configured by script for the frontend group</h1>" | sudo tee /var/www/frontend/index.html
    echo "<h1>Apache Configured by script for the backend group</h1>" | sudo tee /var/www/backend/index.html

    sudo bash -c 'cat > /etc/apache2/sites-available/frontend.conf' <<EOF
<VirtualHost *:80>
    ServerName frontend.local
    DocumentRoot /var/www/frontend

    <Directory /var/www/frontend>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF

    sudo bash -c 'cat > /etc/apache2/sites-available/backend.conf' <<EOF
<VirtualHost *:80>
    ServerName backend.local
    DocumentRoot /var/www/backend

    <Directory /var/www/backend>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF

    sudo a2ensite frontend.conf backend.conf
    sudo systemctl reload apache2
    echo "Apache installed and configured. Add local.frontend and local.backend to /etc/hosts if necessary."
}

# Function to change directory ownership
change_directory_ownership() {
    [ -d /var/www/frontend ] && sudo chown -R :"$group1" /var/www/frontend
    [ -d /var/www/backend ] && sudo chown -R :"$group2" /var/www/backend
    echo "Directory ownership changed."
}

# Function for network configuration
configure_network() {
    read -p "Would you like to assign a static IP? (y/n): " response
    if [[ $response == "y" || $response == "Y" ]]; then
        read -p "Enter the IP address: " ip
        read -p "Enter the DNS address: " dns
        if command -v dhcpcd &>/dev/null; then
            sudo bash -c "echo -e 'interface enp0s3\nstatic ip_address=$ip\nstatic dns_nameservers=$dns' >> /etc/dhcpcd.conf"
            sudo systemctl restart dhcpcd
            echo "Network configured."
        else
            echo "dhcpcd not found."
        fi
    else
        echo "Network configuration canceled."
    fi
}

# Function to delete users and groups
delete_users_and_groups() {
    echo "Delete options:"
    echo "a. Delete a specific user"
    echo "b. Delete a specific group"
    echo "c. Delete all users created by this script"
    echo "d. Delete all groups created by this script"
    echo "e. Delete all users and groups created by this script"
    read -p "Please choose an option: " option

    case $option in
        a)
            read -p "Enter the username: " username
            sudo userdel -r "$username" && echo "User $username deleted."
            ;;
        b)
            read -p "Enter the group name: " groupname
            sudo groupdel "$groupname" && echo "Group $groupname deleted."
            ;;
        c)
            for i in {1..20}; do
                sudo userdel -r "user${i}_$group1" 2>/dev/null
                sudo userdel -r "user${i}_$group2" 2>/dev/null
            done
            echo "All script-created users deleted."
            ;;
        d)
            sudo groupdel "$group1" 2>/dev/null
            sudo groupdel "$group2" 2>/dev/null
            echo "All script-created groups deleted."
            ;;
        e)
            for i in {1..20}; do
                sudo userdel -r "user${i}_$group1" 2>/dev/null
                sudo userdel -r "user${i}_$group2" 2>/dev/null
            done
            sudo groupdel "$group1" 2>/dev/null
            sudo groupdel "$group2" 2>/dev/null
            echo "All users and groups created by this script deleted."
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
}

# Main loop
while true; do
    show_menu
    read choice
    case $choice in
        1) create-groups-users ;;
        2) create_directories_and_set_permissions ;;
        3) change_group_ids ;;
        4) display ;;
        5) rename_user ;;
        6) show_password_hashes ;;
        7) switch_to_user ;;
        8) install_and_configure_apache ;;
        9) change_directory_ownership ;;
        10) configure_network ;;
        11) delete_users_and_groups ;;
        12) echo "Exiting." ; exit 0 ;;
        *) echo "Invalid choice, try again." ;;
    esac
done
