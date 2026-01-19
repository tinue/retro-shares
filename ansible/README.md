# Ansible Deployment for Retro Shares

This Ansible playbook automates the deployment of Retro Shares to a remote server.

## Prerequisites

On the **target server**:
- Docker (with Docker Compose v2)
- Docker service running
- SSH access with sudo privileges

On the **control machine** (where you run Ansible):
- Ansible 2.9+
- SSH access to target server

## Files

| File | Description |
|------|-------------|
| `playbook.yml` | Main deployment playbook |
| `vars.yml` | Configuration variables |
| `inventory.yml` | Target server inventory |

## Configuration

### 1. Edit inventory.yml

Add your target server(s):

```yaml
all:
  children:
    retro_servers:
      hosts:
        my-retro-server:
          ansible_host: 192.168.1.100
          ansible_user: admin
```

### 2. Edit vars.yml

Configure the deployment, if necessary:

```yaml
# Your GitHub repository
github_repo: "https://github.com/tinue/retro-shares.git"
github_branch: "main"

# Docker user (will be created and added to docker group)
docker_user: "docker-admin"

# Installation path (in docker user's home directory)
install_path: "/home/{{ docker_user }}/docker/retro-shares"

# SMB admin credentials
smb_user: "retroadmin"
smb_password: "retroadmin"

# SMB read-only user credentials (optional)
# Leave empty to disable authenticated read-only access
smb_ro_user: "guest"
smb_ro_password: "guest"
```


## Deployment

### Basic deployment

```bash
cd ansible
ansible-playbook -i inventory.yml playbook.yml
```

### With password prompt (if using Vault)

```bash
ansible-playbook -i inventory.yml playbook.yml --ask-vault-pass
```

### With sudo password prompt

```bash
ansible-playbook -i inventory.yml playbook.yml --ask-become-pass
```


## What the playbook does

1. Checks if Docker and Docker Compose are installed (fails if not)
2. Verifies Docker service is running
3. Installs git if not present
4. Creates a dedicated docker user and adds it to the docker group
5. Creates the project directory with correct ownership
6. Installs acl package (required for Ansible's become_user)
7. Clones/updates the repository from GitHub as the docker user
8. Creates the data directory for shared files
9. Creates `.env` file with SMB credentials
10. Builds and starts the Docker container as the docker user
11. Displays connection information

## Post-deployment

After successful deployment (default paths assume `docker_user: docker-admin`):

1. Copy files to the share:
   ```bash
   ssh user@server "cp -r /path/to/retro/files /home/docker-admin/docker/retro-shares/data/"
   ```

2. Verify the service:
   ```bash
   ssh user@server "cd /home/docker-admin/docker/retro-shares && docker compose logs"
   ```

3. Connect from retro clients using `\\RETRO\retro`

