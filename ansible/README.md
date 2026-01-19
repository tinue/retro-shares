# Ansible Deployment for Retro Shares

This Ansible playbook automates the deployment of Retro Shares to a remote server using the `retro_shares` role.

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
| `inventory.yml` | Target server inventory |
| `roles/retro_shares/` | Deployment role (see [role documentation](roles/retro_shares/README.md)) |

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

### 2. Override role variables (optional)

The role has sensible defaults, but you can override them in several ways:

**Option A: In the inventory file (per host or group)**

```yaml
all:
  children:
    retro_servers:
      vars:
        smb_user: "myadmin"
        smb_password: "mysecretpassword"
      hosts:
        my-retro-server:
          ansible_host: 192.168.1.100
```

**Option B: Via command line extra vars**

```bash
ansible-playbook -i inventory.yml playbook.yml -e "smb_user=myadmin smb_password=mysecret"
```

**Option C: Create a separate vars file**

```bash
ansible-playbook -i inventory.yml playbook.yml -e "@my_vars.yml"
```

See the [role documentation](roles/retro_shares/README.md) for all available variables.

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
