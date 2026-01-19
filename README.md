# Retro Shares

A Dockerized Samba file server designed for legacy/retro clients including DOS, OS/2, Windows 3.x, Windows 9x, and Windows NT.

> **Note:** This project was generated with the assistance of AI (Claude by Anthropic).

## Features

- **Samba 4.16** last version to still include LANMAN authentication support, required for OS/2
- **Anonymous read-only access** for retro clients
- **Authenticated read-only access** (optional) for controlled guest access
- **Authenticated read-write access** for administration
- **NetBIOS support** for network browsing on legacy systems
- **Legacy protocol support** (SMB1, LANMAN1)
- **DOS character encoding** (CP850)
- **Automatic Mac file cleanup** (removes `.DS_Store`, `._*`, etc.)

## Security Warning

**This server intentionally uses insecure, outdated protocols to support legacy systems. DO NOT expose this server to the internet or untrusted networks.**

The following insecure configurations are enabled:

| Setting | Risk |
|---------|------|
| LANMAN authentication | Passwords can be easily cracked |
| SMB1 protocol | Known vulnerabilities (EternalBlue, WannaCry) |
| No SMB signing | Susceptible to man-in-the-middle attacks |
| No encryption | All traffic is transmitted in plaintext |
| Anonymous access | Anyone on the network can read shared files |

**Recommendations:**
- Due to the insecure nature of the server, don't bother with changing / encrypting the passwords for the two authenticated users
  "retro" and "retroadmin". The distinction between these users is to prevent accidential file modification on the share, not to
  make this secure in any way!
- Run this server only on isolated networks
- Use a dedicated VLAN for retro computing
- Never store sensitive data on this share
- Consider firewall rules to restrict access to known MAC addresses
- Monitor access logs regularly

## Requirements

- Docker
- Docker Compose
- Ansible 2.9+ (for automated deployment)

## Installation

### Option A: Manual Installation

### Step 1: Clone or download the project

```bash
git clone https://github.com/tinue/retro-shares.git
cd retro-shares
```

### Step 2: Create the data directory

Create a directory for the files you want to share:

```bash
mkdir -p data
```

Place your retro software, drivers, games, etc. in the `data` directory.

### Step 3: Configure environment variables

Create a `.env` file with your credentials:

```bash
# Create .env file
cat > .env << EOF
SMB_USER=retroadmin
SMB_PASSWORD=retroadmin
EOF
```

Optionally, add an authenticated read-only user:

```bash
# Create .env file with read-only user
cat > .env << EOF
SMB_USER=retroadmin
SMB_PASSWORD=retroadmin
SMB_RO_USER=retro
SMB_RO_PASSWORD=retro
EOF
```

Or export them directly:

```bash
export SMB_USER=retroadmin
export SMB_PASSWORD=retroadmin
# Optional read-only user
export SMB_RO_USER=retro
export SMB_RO_PASSWORD=retro
```

### Step 4: Build and start the server

```bash
docker compose up -d --build
```

### Step 5: Verify the server is running

```bash
docker compose logs -f
```

You should see output indicating Samba services have started.

### Autostart on Server Reboot

The container is configured with `restart: unless-stopped`, which means it will automatically restart after a server reboot as long as:

1. **Docker is configured to start on boot.** On most Linux distributions with systemd, enable this with:
   ```bash
   sudo systemctl enable docker
   ```

2. **The container was not manually stopped** before the reboot. If you run `docker compose down`, the container will not restart automatically until you start it again with `docker compose up -d`.

To verify autostart is working after a reboot:
```bash
docker compose ps
```

If you prefer the container to always restart (even after manual stops), edit `docker-compose.yml` and change `restart: unless-stopped` to `restart: always`.

### Option B: Ansible Deployment

For automated deployment to remote servers, use the included Ansible playbook.

#### Prerequisites

- Ansible 2.9+ on your control machine
- Docker and Docker Compose already installed on target server
- SSH access to target server with sudo privileges

#### Quick Start

1. Edit `ansible/inventory.yml` with your server:
   ```yaml
   all:
     children:
       retro_servers:
         hosts:
           my-server:
             ansible_host: 192.168.1.100
             ansible_user: admin
   ```

2. (Optional) Override default variables via inventory, command line, or vars file.
   See `ansible/roles/retro_shares/README.md` for all available variables.

3. Run the playbook:
   ```bash
   cd ansible
   ansible-playbook -i inventory.yml playbook.yml --ask-become-pass
   ```

See `ansible/README.md` for detailed instructions and advanced options.

## Connecting from Clients

### Server Details

| Setting | Value |
|---------|-------|
| NetBIOS Name | `RETRO` |
| Share Name | `retro` |
| UNC Path | `\\RETRO\retro` |

### DOS

Using the Microsoft Network Client for DOS 3.0:

```
net use r: \\RETRO\retro
```

### Windows 95/98/ME

1. Open **Network Neighborhood**
2. Look for **RETRO** in the workgroup
3. Double-click to browse the share

Or use **Map Network Drive**:
- Path: `\\RETRO\retro`

### Windows NT 4.0

```cmd
net use R: \\RETRO\retro
```

### OS/2
Before trying to mount a share, a user must be defined locally: 
* Start -> OS/2 System -> System Setup -> UPM Services -> User Account Management.
* The user is defined locally, i.e. "Local workstation".
* Username and password must match one of the users on the file server

Once a user is defined, use the command line:

```
net use r: \\RETRO\retro
```

If not already logged in, a pop-up will ask you to log in now.

Or use the **Connections** folder in the WPS.

### Modern Systems (for administration)

On Linux:

```bash
# Authenticated read-write access
smbclient //RETRO/retro -U retroadmin

# Authenticated read-only access (if configured)
smbclient //RETRO/retro -U retro
```

On Windows 10/11 (may require enabling SMB1):

```powershell
# Connect
net use R: \\RETRO\retro
```

## Administration

### Viewing logs

```bash
docker compose logs -f
```

### Stopping the server

```bash
docker compose down
```

### Restarting after configuration changes

```bash
docker compose down
docker compose up -d --build
```

### Checking connected users

```bash
docker compose exec retro-shares smbstatus
```

## Mac File Cleanup

When managing the share from a Mac, macOS creates metadata files that can clutter the share and confuse retro clients. The `clean.sh` script automatically removes these files every 60 seconds.

### Files removed

| Pattern | Description |
|---------|-------------|
| `.DS_Store` | Finder folder settings |
| `._*` | AppleDouble resource forks |
| `.AppleDouble` | AppleDouble directories |
| `.localized` | Localization files |
| `Network Trash Folder` | Network trash |
| `Temporary Items` | Temporary files |

### Manual cleanup

To run the cleanup manually:

```bash
docker compose exec retro-shares /clean.sh
```

### Customizing cleanup

To add or remove patterns, edit `clean.sh` and rebuild:

```bash
docker compose up -d --build
```

## Troubleshooting

### Clients cannot find the server

1. Ensure the server and client are on the same network/subnet
2. Verify NetBIOS is working: `nmblookup RETRO` from a Linux host
3. Try connecting by IP address: `\\192.168.x.x\retro`
4. Check if ports 137-139 and 445 are not blocked by a firewall

### Authentication fails

1. Verify the SMB_USER and SMB_PASSWORD environment variables are set correctly
2. For read-only users, verify SMB_RO_USER and SMB_RO_PASSWORD are both set
3. Rebuild the container: `docker compose up -d --build`
4. Check logs for errors: `docker compose logs`

### Permission denied when writing

1. Ensure you're connecting with the admin user (SMB_USER), not the read-only user or guest
2. The read-only user (SMB_RO_USER) can authenticate but cannot write files
3. Verify the admin user is in the `smbusers` group (handled automatically)

### DOS client hangs or times out

1. Try reducing the packet size on the DOS client
2. Ensure you're using the correct network driver for your NIC
3. Some DOS network stacks require specific MTU settings

## File Structure

```
retro-shares/
├── Dockerfile          # Container image definition
├── docker-compose.yml  # Service orchestration
├── smb.conf            # Samba configuration
├── entrypoint.sh       # Startup script
├── clean.sh            # Mac metadata cleanup script
├── data/               # Shared files (create this)
├── ansible/            # Ansible deployment files
│   ├── playbook.yml    # Main deployment playbook
│   ├── inventory.yml   # Target server inventory
│   ├── README.md       # Ansible documentation
│   └── roles/
│       └── retro_shares/
│           ├── defaults/
│           │   └── main.yml   # Default variables
│           ├── tasks/
│           │   └── main.yml   # Deployment tasks
│           └── README.md      # Role documentation
└── README.md           # This file
```


## Clients

Testing is limited, as I don't have the full range of legacy machines available.
The tests were performed on an IBM Thinkpad T40 or T42p. This machine supports a wide range of
old operating systems: PC DOS 2000, Windows 98SE / ME; Windows NT 4.0 up to XP. In addition,
OS/2 Warp 4.52 works fine on this hardware.

* PC DOS 2000, MS Network Client 3.0: Anonymous not tested, authenticated ok 
* OS/2 Warp 4.52: Anonymous not tested, authenticated ok
* Windows 98 SE: Anonymous ok, authenticated not tested
* Windows NT Workstation 4.0: Anonymous ok, authenticated not tested
* Windows 2000: Anonymous ok, authenticated not tested
* Windows XP SP3: Anonymous not ok, authenticated ok

## License

This project is provided as-is for educational and hobbyist purposes. Use at your own risk.
