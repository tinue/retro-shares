# Ansible Role: retro_shares

Deploys and configures the Retro Shares Samba server using Docker.

## Requirements

On the target server:
- Docker (with Docker Compose v2) must be installed
- Docker service must be running

The role will install `git` and `acl` packages if not present.

## Role Variables

All variables are defined in `defaults/main.yml` and can be overridden.

### Repository Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `github_repo` | `https://github.com/tinue/retro-shares.git` | GitHub repository URL to clone |
| `github_branch` | `main` | Branch to checkout |

### System Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_user` | `docker-admin` | System user to run Docker containers (created if not exists) |
| `install_path` | `/home/{{ docker_user }}/docker/retro-shares` | Installation directory on target server |

### SMB Credentials

| Variable | Default | Description |
|----------|---------|-------------|
| `smb_user` | `retroadmin` | Admin username with read-write access |
| `smb_password` | `retroadmin` | Admin password |
| `smb_ro_user` | `retro` | Read-only username (optional, leave empty to disable) |
| `smb_ro_password` | `retro` | Read-only user password |

**Security Note:** The SMB protocol used for retro computers transmits passwords in plain text. The default credentials are intentionally simple since the distinction between read-only and read-write access is primarily to prevent accidental modifications, not for security. If desired, you can encrypt these variables using Ansible Vault.

## What This Role Does

1. Checks that Docker and Docker Compose v2 are installed and running
2. Installs `git` package if not present
3. Creates the docker user and adds it to the docker group
4. Creates the project directory with correct ownership
5. Installs `acl` package (required for Ansible's `become_user`)
6. Clones or updates the repository from GitHub
7. Creates the data directory for shared files
8. Creates `.env` file with SMB credentials
9. Builds and starts the Docker container
10. Displays connection information

## Dependencies

None.

## Example Playbook

### Basic usage

```yaml
- hosts: retro_servers
  become: yes
  roles:
    - retro_shares
```

### With custom variables

```yaml
- hosts: retro_servers
  become: yes
  roles:
    - role: retro_shares
      vars:
        docker_user: "myuser"
        smb_user: "admin"
        smb_password: "secretpassword"
        smb_ro_user: ""  # Disable authenticated read-only access
```

### Including the role from another project

If you want to include this role in your own Ansible project, add it to your `requirements.yml`:

```yaml
roles:
  - src: https://github.com/tinue/retro-shares.git
    scm: git
    version: main
    name: retro_shares
```

Then install with:

```bash
ansible-galaxy install -r requirements.yml -p roles/
```

## License

See repository license.

## Author

See repository contributors.
