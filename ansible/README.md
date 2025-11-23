# 🤖 DhakaCart Ansible Automation

Ansible playbooks and roles for automating DhakaCart infrastructure management.

## 📁 Directory Structure

```
ansible/
├── ansible.cfg               # Ansible configuration
├── inventory/
│   └── hosts.ini            # Server inventory
├── playbooks/
│   ├── provision.yml        # Server provisioning
│   ├── deploy.yml           # Application deployment
│   ├── backup.yml           # Database backups
│   └── rollback.yml         # Version rollback
├── roles/
│   ├── common/              # Common tasks
│   ├── docker/              # Docker installation
│   ├── monitoring/          # Monitoring setup
│   └── backup/              # Backup configuration
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites

```bash
# Install Ansible
sudo apt update
sudo apt install -y ansible

# Verify installation
ansible --version

# Install required collections
ansible-galaxy collection install community.docker
ansible-galaxy collection install amazon.aws
```

### Configure Inventory

Edit `inventory/hosts.ini` with your server information:

```ini
[production]
prod-web-1 ansible_host=YOUR_SERVER_IP ansible_user=ubuntu

[databases]
prod-db-1 ansible_host=YOUR_DB_IP ansible_user=ubuntu
```

### Test Connection

```bash
cd /home/arif/DhakaCart-03/ansible/

# Ping all servers
ansible all -m ping

# Check connectivity
ansible all -m command -a "hostname"
```

---

## 📋 Playbooks

### 1. Provision Servers

Sets up new servers with required software.

**What it does:**
- Updates system packages
- Installs Docker and Docker Compose
- Configures firewall (UFW)
- Sets up fail2ban
- Creates application directories
- Configures security settings

**Usage:**
```bash
# Provision all servers
ansible-playbook playbooks/provision.yml

# Provision specific group
ansible-playbook playbooks/provision.yml --limit webservers

# Provision single host
ansible-playbook playbooks/provision.yml --limit prod-web-1

# Dry run (check mode)
ansible-playbook playbooks/provision.yml --check
```

**Time:** ~10-15 minutes per server

---

### 2. Deploy Application

Deploys or updates DhakaCart application.

**What it does:**
- Pulls latest code from Git
- Copies environment configuration
- Pulls Docker images
- Stops old containers
- Starts new containers
- Verifies deployment

**Usage:**
```bash
# Deploy to production
ansible-playbook playbooks/deploy.yml --limit production

# Deploy to staging
ansible-playbook playbooks/deploy.yml --limit staging

# Deploy with tags (only specific tasks)
ansible-playbook playbooks/deploy.yml --tags "update"

# Deploy and verify
ansible-playbook playbooks/deploy.yml --tags "deploy,verify"
```

**Time:** ~5-10 minutes

**Environment Variables:**
```bash
# Set environment
ansible-playbook playbooks/deploy.yml -e "env=production"

# Set branch
ansible-playbook playbooks/deploy.yml -e "branch=develop"
```

---

### 3. Backup Databases

Runs database backup scripts.

**What it does:**
- Backs up PostgreSQL database
- Backs up Redis data
- Uploads to S3 (optional)
- Cleans old backups
- Sends notifications

**Usage:**
```bash
# Backup all databases
ansible-playbook playbooks/backup.yml

# Backup only PostgreSQL
ansible-playbook playbooks/backup.yml --tags postgres

# Backup only Redis
ansible-playbook playbooks/backup.yml --tags redis

# Backup with S3 upload
ansible-playbook playbooks/backup.yml --tags "postgres,s3"
```

**Schedule with Cron:**
```bash
# Add to crontab
0 2 * * * cd /home/arif/DhakaCart-03/ansible && ansible-playbook playbooks/backup.yml
```

**Time:** ~5-10 minutes

---

### 4. Rollback Application

Reverts to previous version if deployment fails.

**What it does:**
- Stops current version
- Restores previous code
- Pulls previous Docker images
- Restarts application
- Verifies rollback
- Logs rollback event

**Usage:**
```bash
# Rollback production (with confirmation)
ansible-playbook playbooks/rollback.yml --limit production

# Auto rollback (no confirmation)
ansible-playbook playbooks/rollback.yml -e "auto_rollback=true"

# Rollback specific host
ansible-playbook playbooks/rollback.yml --limit prod-web-1
```

**Time:** ~3-5 minutes

---

## 🎯 Common Tasks

### Update All Servers

```bash
# Update system packages
ansible all -m apt -a "upgrade=dist update_cache=yes" -b

# Reboot servers
ansible all -m reboot -b

# Check uptime
ansible all -m command -a "uptime"
```

### Manage Docker Containers

```bash
# Check container status
ansible webservers -m command -a "docker ps"

# Restart containers
ansible webservers -m command -a "docker-compose -f /opt/dhakacart/docker-compose.prod.yml restart"

# View logs
ansible webservers -m command -a "docker logs dhakacart-backend --tail 50"
```

### File Operations

```bash
# Copy file to all servers
ansible all -m copy -a "src=./config.yml dest=/opt/dhakacart/config.yml"

# Create directory
ansible all -m file -a "path=/opt/dhakacart/logs state=directory mode=0755"

# Delete file
ansible all -m file -a "path=/tmp/old-file.txt state=absent"
```

### Service Management

```bash
# Restart nginx
ansible webservers -m systemd -a "name=nginx state=restarted" -b

# Check service status
ansible all -m systemd -a "name=docker"

# Enable service
ansible all -m systemd -a "name=docker enabled=yes" -b
```

---

## 🔐 Ansible Vault (Secrets Management)

### Create Encrypted Variables

```bash
# Create vault file
ansible-vault create group_vars/production/vault.yml

# Edit vault file
ansible-vault edit group_vars/production/vault.yml

# View vault file
ansible-vault view group_vars/production/vault.yml
```

### Vault Content Example

```yaml
# group_vars/production/vault.yml
vault_db_password: "super-secure-password"
vault_jwt_secret: "jwt-secret-key"
vault_aws_access_key: "AKIAIOSFODNN7EXAMPLE"
vault_aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

### Use Encrypted Variables

```yaml
# In playbook
- name: Set database password
  set_fact:
    db_password: "{{ vault_db_password }}"
```

### Run Playbook with Vault

```bash
# Prompt for vault password
ansible-playbook playbooks/deploy.yml --ask-vault-pass

# Use password file
ansible-playbook playbooks/deploy.yml --vault-password-file ~/.vault_pass

# Use multiple vaults
ansible-playbook playbooks/deploy.yml --vault-id prod@~/.vault_pass_prod
```

---

## 📊 Advanced Usage

### Parallel Execution

```bash
# Run on 10 hosts simultaneously
ansible-playbook playbooks/deploy.yml -f 10

# Serial execution (one at a time)
ansible-playbook playbooks/deploy.yml --serial 1
```

### Tags

```bash
# List available tags
ansible-playbook playbooks/deploy.yml --list-tags

# Run only specific tags
ansible-playbook playbooks/deploy.yml --tags "config,restart"

# Skip specific tags
ansible-playbook playbooks/deploy.yml --skip-tags "docker"
```

### Debugging

```bash
# Verbose output
ansible-playbook playbooks/deploy.yml -v    # Level 1
ansible-playbook playbooks/deploy.yml -vv   # Level 2
ansible-playbook playbooks/deploy.yml -vvv  # Level 3

# Step-by-step execution
ansible-playbook playbooks/deploy.yml --step

# Start at specific task
ansible-playbook playbooks/deploy.yml --start-at-task="Copy environment file"
```

### Dry Run

```bash
# Check mode (no changes)
ansible-playbook playbooks/deploy.yml --check

# Diff mode (show changes)
ansible-playbook playbooks/deploy.yml --check --diff
```

---

## 🎭 Roles

### Using Roles

```yaml
# In playbook
- hosts: webservers
  roles:
    - common
    - docker
    - monitoring
```

### Available Roles

#### common
- Basic server setup
- User management
- Security hardening

#### docker
- Docker installation
- Docker Compose setup
- Container management

#### monitoring
- Prometheus installation
- Grafana setup
- Exporter configuration

#### backup
- Backup script installation
- Cron job configuration
- S3 sync setup

---

## 📝 Best Practices

### 1. Use Variables

```yaml
# Don't hardcode values
- name: Bad
  command: docker pull arifhossaincse22/dhakacart-backend:latest

# Use variables
- name: Good
  command: docker pull {{ docker_registry }}/{{ app_name }}-backend:{{ version }}
```

### 2. Use Handlers

```yaml
tasks:
  - name: Update nginx config
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: reload nginx

handlers:
  - name: reload nginx
    systemd:
      name: nginx
      state: reloaded
```

### 3. Idempotency

```yaml
# Ensure tasks can run multiple times safely
- name: Create directory
  file:
    path: /opt/app
    state: directory  # Won't fail if already exists
```

### 4. Error Handling

```yaml
- name: Task that might fail
  command: /some/command
  ignore_errors: yes
  register: result

- name: Handle failure
  debug:
    msg: "Command failed: {{ result.stderr }}"
  when: result.failed
```

---

## 🔍 Troubleshooting

### Connection Issues

```bash
# Test SSH connection
ssh -i ~/.ssh/id_rsa ubuntu@YOUR_SERVER_IP

# Check Ansible can reach host
ansible prod-web-1 -m ping

# Use different user
ansible prod-web-1 -m ping -u root

# Use different SSH key
ansible prod-web-1 -m ping --private-key ~/.ssh/other_key
```

### Permission Issues

```bash
# Run with sudo
ansible webservers -m command -a "systemctl status nginx" -b

# Specify sudo user
ansible webservers -m command -a "whoami" -b --become-user=root

# Ask for sudo password
ansible-playbook playbooks/provision.yml --ask-become-pass
```

### Slow Execution

```bash
# Enable SSH pipelining (in ansible.cfg)
[ssh_connection]
pipelining = True

# Increase forks
ansible-playbook playbooks/deploy.yml -f 20

# Use strategy
- hosts: webservers
  strategy: free  # Don't wait for all hosts
```

---

## 📚 Additional Resources

- **Ansible Documentation**: https://docs.ansible.com/
- **Best Practices**: https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html
- **Galaxy (Roles)**: https://galaxy.ansible.com/
- **Examples**: https://github.com/ansible/ansible-examples

---

**🤖 Automate everything! Let Ansible handle repetitive tasks while you focus on building features.**

