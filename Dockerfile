FROM alpine:3.17

# Alpine 3.17 ships with Samba 4.16.x (4.16.11 as of January 2026) which still supports LANMAN authentication
# Required for DOS, Windows 3.x, Windows 9x, and OS/2 clients

RUN apk add --no-cache \
    samba \
    samba-common \
    samba-common-tools \
    samba-server \
    samba-client \
    && rm -rf /var/cache/apk/*

# Create share directory
RUN mkdir -p /srv/retro && chmod 755 /srv/retro

# Copy configuration files
COPY smb.conf /etc/samba/smb.conf
COPY entrypoint.sh /entrypoint.sh
COPY clean.sh /clean.sh
RUN chmod +x /entrypoint.sh /clean.sh

# Expose SMB ports
# 137/udp - NetBIOS Name Service
# 138/udp - NetBIOS Datagram Service
# 139/tcp - NetBIOS Session Service (required for legacy clients)
# 445/tcp - Microsoft-DS (modern SMB)
EXPOSE 137/udp 138/udp 139/tcp 445/tcp

ENTRYPOINT ["/entrypoint.sh"]
