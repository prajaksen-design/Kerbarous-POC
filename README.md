

````markdown
# Kerberos NFS POC

This project demonstrates how to configure **Kerberos-secured NFS (Network File System)**. It ensures secure authentication and encrypted communication between NFS clients and servers.

## Prerequisites
- Linux environment (Ubuntu/CentOS/RHEL recommended)
- Kerberos server (KDC) installed and configured
- NFS server packages installed
- Proper DNS resolution between client and server

## Setup

### 1. Install Required Packages
```bash
sudo apt update
sudo apt install krb5-user nfs-kernel-server nfs-common -y
````

### 2. Configure Kerberos

* Edit `/etc/krb5.conf` with realm and KDC details.
* Create service principal for NFS:

```bash
kadmin.local -q "addprinc -randkey nfs/hostname@YOUR.REALM"
kadmin.local -q "ktadd -k /etc/krb5.keytab nfs/hostname@YOUR.REALM"
```

### 3. Configure NFS Server

* Edit `/etc/exports`:

```
/srv/nfs    *(rw,sec=krb5p)
```

* Restart services:

```bash
sudo systemctl restart nfs-server
```

### 4. Configure NFS Client

* Obtain Kerberos ticket:

```bash
kinit user@YOUR.REALM
```

* Mount NFS share:

```bash
sudo mount -t nfs4 -o sec=krb5p server:/srv/nfs /mnt
```

### 5. Verify

* Run `mount` to check mounted share.
* Test file operations inside `/mnt`.

## Security Levels

* `sec=krb5` → Authentication only
* `sec=krb5i` → Authentication + Integrity
* `sec=krb5p` → Authentication + Integrity + Privacy (encryption)

