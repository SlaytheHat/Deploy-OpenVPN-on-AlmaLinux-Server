#!/bin/bash

# A simple script to deploy and configure OpenVPN on an AlmaLinux server, including client configuration.

# Variables
VPN_PORT=1194
VPN_PROTOCOL="udp"
VPN_NET="10.8.0.0"
VPN_NETMASK="255.255.255.0"
VPN_SERVER_NAME="server"
CLIENT_NAME="client"
EASYRSA_DIR="/etc/openvpn/easy-rsa"
OUTPUT_DIR="/etc/openvpn/client-configs"

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Install necessary packages
install_packages() {
    echo "Installing OpenVPN and Easy-RSA..."
    dnf install -y epel-release
    dnf install -y openvpn easy-rsa firewalld
}

# Configure Easy-RSA
configure_easyrsa() {
    echo "Setting up Easy-RSA..."
    mkdir -p ${EASYRSA_DIR}
    cp -r /usr/share/easy-rsa/3/* ${EASYRSA_DIR}
    cd ${EASYRSA_DIR}

    echo "Initializing PKI..."
    ./easyrsa init-pki

    echo "Building the CA..."
    ./easyrsa build-ca nopass

    echo "Generating server certificate and key..."
    ./easyrsa gen-req ${VPN_SERVER_NAME} nopass
    ./easyrsa sign-req server ${VPN_SERVER_NAME}

    echo "Creating Diffie-Hellman key exchange..."
    ./easyrsa gen-dh

    echo "Generating client certificate and key..."
    ./easyrsa gen-req ${CLIENT_NAME} nopass
    ./easyrsa sign-req client ${CLIENT_NAME}
}

# Configure OpenVPN server
configure_openvpn_server() {
    echo "Configuring OpenVPN server..."
    mkdir -p /etc/openvpn/server
    cat <<EOL > /etc/openvpn/server/${VPN_SERVER_NAME}.conf
port ${VPN_PORT}
proto ${VPN_PROTOCOL}
dev tun
server ${VPN_NET} ${VPN_NETMASK}
keepalive 10 120
persist-key
persist-tun
ca ca.crt
cert ${VPN_SERVER_NAME}.crt
key ${VPN_SERVER_NAME}.key
dh dh.pem
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
user nobody
group nobody
log-append /var/log/openvpn.log
verb 3
EOL

    cp ${EASYRSA_DIR}/pki/ca.crt /etc/openvpn/server
    cp ${EASYRSA_DIR}/pki/issued/${VPN_SERVER_NAME}.crt /etc/openvpn/server
    cp ${EASYRSA_DIR}/pki/private/${VPN_SERVER_NAME}.key /etc/openvpn/server
    cp ${EASYRSA_DIR}/pki/dh.pem /etc/openvpn/server
}

# Generate client configuration
generate_client_config() {
    echo "Generating client configuration..."
    mkdir -p ${OUTPUT_DIR}

    cat <<EOL > ${OUTPUT_DIR}/${CLIENT_NAME}.ovpn
client
dev tun
proto ${VPN_PROTOCOL}
remote <SERVER_IP> ${VPN_PORT}
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
key-direction 1
verb 3

<ca>
$(cat ${EASYRSA_DIR}/pki/ca.crt)
</ca>
<cert>
$(cat ${EASYRSA_DIR}/pki/issued/${CLIENT_NAME}.crt)
</cert>
<key>
$(cat ${EASYRSA_DIR}/pki/private/${CLIENT_NAME}.key)
</key>
<tls-auth>
$(cat /etc/openvpn/server/ta.key)
</tls-auth>
EOL

    echo "Client configuration saved to ${OUTPUT_DIR}/${CLIENT_NAME}.ovpn"
}

# Set up firewall rules
setup_firewall() {
    echo "Configuring firewall rules..."
    systemctl start firewalld
    firewall-cmd --permanent --add-port=${VPN_PORT}/${VPN_PROTOCOL}
    firewall-cmd --permanent --add-masquerade
    firewall-cmd --reload
}

# Enable and start OpenVPN service
start_openvpn() {
    echo "Enabling and starting OpenVPN service..."
    systemctl enable openvpn-server@${VPN_SERVER_NAME}
    systemctl start openvpn-server@${VPN_SERVER_NAME}
    echo "OpenVPN deployed and running!"
}

# Main execution
install_packages
configure_easyrsa
configure_openvpn_server
setup_firewall
start_openvpn
generate_client_config

echo "OpenVPN deployment completed successfully!"
echo "Distribute the client configuration file: ${OUTPUT_DIR}/${CLIENT_NAME}.ovpn"
