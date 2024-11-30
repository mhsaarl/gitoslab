#!/bin/bash

# Function to display menu
show_menu() {
    echo "==========================="
    echo "       Main Menu           "
    echo "==========================="
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
    echo "==========================="
    echo -n "Please choose an option: "
}

# Function to create groups and users
create_groups_and_users() {
    read -p "Enter the first group name (default frontend): " group1
    read -p "Enter the second group name (default backend): " group2
    group1=${group1:-frontend}
    group2=${group2:-backend}

    sudo groupadd $group1
    sudo groupadd $group2
    echo "Groups created."

    for i in {1..10}; do
        sudo useradd -m -G $group1 -p $(openssl passwd -1 123SecurePass) user${i}_$group1
    done
    for i in {11..20}; do
        sudo useradd -m -G $group2 -p $(openssl passwd -1 123SecurePass) user${i}_$group2
    done
    echo "Users created."
}

# Function to create directories and set permissions
create_directories_and_set_permissions() {
    sudo mkdir -p /var/www/frontend
    sudo mkdir -p /var/www/backend
    sudo chown :frontend /var/www/frontend
    sudo chown :backend /var/www/backend
    sudo chmod 770 /var/www/frontend
    sudo chmod 770 /var/www/backend
    echo "Directories created and permissions set."
}

# Function to change group IDs and check
change_group_ids() {
    sudo groupmod -g 1002 frontend
    sudo groupmod -g 1003 backend
    echo "Group IDs changed."
    getent group frontend
    getent group backend
}

# Function to display user groups
display_user_groups() {
    for i in {1..20}; do
        groups user${i}_frontend || groups user${i}_backend
    done
}

# Function to rename a user
rename_user() {
    read -p "Would you like to rename a user? (y/n): " response
    if [[ $response == "y" || $response == "Y" ]]; then
        read -p "Enter a new username (default admin_network): " new_name
        new_name=${new_name:-admin_network}
        sudo usermod -l $new_name user1_frontend
        echo "User renamed."
    else
        echo "No changes made to the username."
    fi
}

# Function to show hashed passwords file
show_password_hashes() {
    sudo cat /etc/shadow | grep user
}

# Function to switch to a different user
switch_to_user() {
    sudo su - user1_frontend -c 'echo "Welcome!"; exec bash'
}

# Function to install and configure Apache
install_and_configure_apache() {
    if ! command -v apache2 &> /dev/null; then
        echo "Apache is not installed, installing..."
        sudo apt update && sudo apt install apache2 -y
    fi

    sudo mkdir -p /var/www/frontend /var/www/backend
    echo "<h1>Welcome to frontend group site</h1>" | sudo tee /var/www/frontend/index.html
    echo "<h1>Welcome to backend group site</h1>" | sudo tee /var/www/backend/index.html

    sudo bash -c 'cat > /etc/apache2/sites-available/frontend.conf' <<EOF
<VirtualHost *:80>
    ServerName local.frontend
    DocumentRoot /var/www/frontend
</VirtualHost>
EOF

    sudo bash -c 'cat > /etc/apache2/sites-available/backend.conf' <<EOF
<VirtualHost *:80>
    ServerName local.backend
    DocumentRoot /var/www/backend
</VirtualHost>
EOF

    sudo a2ensite frontend.conf backend.conf
    sudo systemctl reload apache2
    echo "Apache installed and configured."
}

# Function to change directory ownership
change_directory_ownership() {
    sudo chown -R :frontend /var/www/frontend
    sudo chown -R :backend /var/www/backend
    echo "Directory ownership changed."
}

# Function for network configuration
configure_network() {
    read -p "Would you like to assign a static IP? (y/n): " response
    if [[ $response == "y" || $response == "Y" ]]; then
        read -p "Enter the IP address: " ip
        read -p "Enter the DNS address: " dns
        sudo bash -c "echo -e 'interface enp0s3\nstatic ip_address=$ip\nstatic dns_nameservers=$dns' >> /etc/dhcpcd.conf"
        sudo systemctl restart dhcpcd
        echo "Network configured."
    else
        echo "Network configuration canceled."
    fi
}

# Function to delete users and groups
delete_users_and_groups() {
    echo "Delete options:"
    echo "a. Delete a user"
    echo "b. Delete a group"
    echo "c. Delete all users"
    echo "d. Delete all groups"
    echo "e. Delete all users and groups"
    read -p "Please choose an option: " option

    case $option in
        a)
            read -p "Enter the username: " username
            sudo userdel -r $username
            echo "User $username deleted."
            ;;
        b)
            read -p "Enter the group name: " groupname
            sudo groupdel $groupname
            echo "Group $groupname deleted."
            ;;
        c)
            sudo deluser --remove-home user
            echo "All users deleted."
            ;;
        d)
            sudo delgroup frontend backend
            echo "All groups deleted."
            ;;
        e)
            sudo deluser --remove-home user && sudo delgroup frontend backend
            echo "All users and groups deleted."
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
}

# Display menu and execute options
while true; do
    show_menu
    read choice
    case $choice in
        1) create_groups_and_users ;;
        2) create_directories_and_set_permissions ;;
        3) change_group_ids ;;
        4) display_user_groups ;;
        5) rename_user ;;
        6) show_password_hashes ;;
        7) switch_to_user ;;
        8) install_and_configure_apache ;;
        9) change_directory_ownership ;;
        10) configure_network ;;
        11) delete_users_and_groups ;;
        12) echo "Exiting..."; exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done
