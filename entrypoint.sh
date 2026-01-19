#!/bin/sh
set -e

# Create required Samba directories
mkdir -p /var/log/samba
mkdir -p /var/lib/samba/private
mkdir -p /var/cache/samba
mkdir -p /var/run/samba


# Validate environment variables
if [ -z "$SMB_USER" ]; then
    echo "ERROR: SMB_USER environment variable is not set"
    exit 1
fi

if [ -z "$SMB_PASSWORD" ]; then
    echo "ERROR: SMB_PASSWORD environment variable is not set"
    exit 1
fi

# Use PUID/PGID from environment, defaulting to 1000
PUID=${PUID:-1000}
PGID=${PGID:-1000}
echo "Using PUID=$PUID and PGID=$PGID"

# Create smbusers group with specific GID if it doesn't exist
if ! getent group smbusers >/dev/null 2>&1; then
    addgroup -g "$PGID" smbusers 2>/dev/null || addgroup -S smbusers
fi

# Create the system user with specific UID if it doesn't exist
if ! id "$SMB_USER" >/dev/null 2>&1; then
    echo "Creating system user: $SMB_USER (UID=$PUID)"
    adduser -u "$PUID" -G smbusers -H -s /sbin/nologin -D "$SMB_USER" 2>/dev/null || \
        adduser -S -G smbusers -H -s /sbin/nologin "$SMB_USER"
else
    echo "User $SMB_USER already exists"
    # Ensure user is in smbusers group
    addgroup "$SMB_USER" smbusers 2>/dev/null || true
fi

# Set ownership of share directory
chown -R "$SMB_USER":smbusers /srv/retro
chmod 775 /srv/retro

# Create/update Samba password for the user
echo "Setting Samba password for user: $SMB_USER"
printf "%s\n%s\n" "$SMB_PASSWORD" "$SMB_PASSWORD" | smbpasswd -a -s "$SMB_USER"
smbpasswd -e "$SMB_USER"

# Create read-only user if specified
if [ -n "$SMB_RO_USER" ] && [ -n "$SMB_RO_PASSWORD" ]; then
    # Create the read-only system user if it doesn't exist (not in smbusers group)
    if ! id "$SMB_RO_USER" >/dev/null 2>&1; then
        echo "Creating read-only system user: $SMB_RO_USER"
        adduser -S -H -s /sbin/nologin "$SMB_RO_USER"
    else
        echo "Read-only user $SMB_RO_USER already exists"
    fi

    # Create/update Samba password for the read-only user
    echo "Setting Samba password for read-only user: $SMB_RO_USER"
    printf "%s\n%s\n" "$SMB_RO_PASSWORD" "$SMB_RO_PASSWORD" | smbpasswd -a -s "$SMB_RO_USER"
    smbpasswd -e "$SMB_RO_USER"
fi

echo "Starting Samba services..."
echo "NetBIOS name: RETRO"
echo "Share: \\\\RETRO\\retro"
echo "Anonymous access: read-only"
echo "Authenticated user ($SMB_USER): read-write"
if [ -n "$SMB_RO_USER" ] && [ -n "$SMB_RO_PASSWORD" ]; then
    echo "Authenticated user ($SMB_RO_USER): read-only"
fi

# Verify nmbd exists
if ! command -v nmbd >/dev/null 2>&1; then
    echo "ERROR: nmbd not found. NetBIOS will not work."
    exit 1
fi

# Start nmbd (NetBIOS name service) in background
echo "Starting nmbd (NetBIOS Name Service)..."
nmbd --foreground --no-process-group --debug-stdout &
NMBD_PID=$!
sleep 1

# Verify nmbd started
if ! kill -0 $NMBD_PID 2>/dev/null; then
    echo "ERROR: nmbd failed to start"
    exit 1
fi
echo "nmbd started successfully (PID: $NMBD_PID)"

# Start cleanup job in background (runs every 60 seconds)
echo "Starting Mac file cleanup job (every 60 seconds)..."
(
    while true; do
        cd /srv/retro && /clean.sh 2>/dev/null
        sleep 60
    done
) &
echo "Cleanup job started"

# Start smbd (file sharing service) in foreground
echo "Starting smbd (SMB File Service)..."
exec smbd --foreground --no-process-group --debug-stdout
