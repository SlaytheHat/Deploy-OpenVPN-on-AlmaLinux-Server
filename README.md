# Deploy-OpenVPN-on-AlmaLinux-Server
Bash script to deploy and configure OpenVPN on an AlmaLinux server.

### **Usage Instructions**

1. **Prepare the Server**
   - Deploy an AlmaLinux server with a public IP.

2. **Download and Execute the Script**
   - Save the script as `deploy_openvpn_with_client.sh`.
   - Make it executable:
     ```bash
     chmod +x deploy_openvpn_with_client.sh
     ```
   - Run the script with root privileges:
     ```bash
     sudo ./deploy_openvpn_with_client.sh
     ```

3. **Update the Client Configuration**
   - Replace `<SERVER_IP>` in the `.ovpn` file with your server's public IP.

4. **Distribute the `.ovpn` File**
   - The generated `.ovpn` file will be located at `/etc/openvpn/client-configs/client.ovpn`.
   - Provide this file to users.

5. **Connect Clients**
   - Clients can use the `.ovpn` file with an OpenVPN client to connect to the server.
