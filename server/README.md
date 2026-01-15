# Server Provisioning & Configuration

This directory contains the infrastructure-as-code (Ansible) and configuration files needed to set up and maintain my Ubuntu VPS from scratch.

It automates the installation of system packages, Docker, Neovim (via Bob), Go, Node.js, and creates a fully configured user environment with my dotfiles.

## 📂 Directory Structure

- **`ansible/`**: The core automation logic.
  - `setup.yml`: The main playbook.
  - `inventory`: Server IP and connection details.
  - `tasks/`: Broken-down tasks for security, docker, neovim, etc.

- **`dotfiles/`**: Server-specific configuration files (minimal `.bashrc`, `init.lua`) that get symlinked during setup.
- **`cloud_init/`**: (Optional) Cloud-init scripts for initial VPS booting.

## 🚀 Usage

### Prerequisites

- **Ansible** installed on your local machine (`brew install ansible`).

## 🔑 Handling Secrets

The `secrets.yml` file is encrypted with my personal key. To use this setup yourself, you must **delete my `secrets.yml` and create your own.**

1. **Delete:** rm `server/ansible/group_vars/all/secrets.yml`
2. **Create:** Create a new file at that same location with your own secrets:

```bash
# server/ansible/group_vars/all/secrets.yml
sudo_password_hash: "your_hashed_password"
# Add any other secrets needed by the playbook
```

3. **Encrypt (Optional):** You can use `ansible-vault encrypt` to secure your new file.

### 1. First Run (Fresh Server)

On a brand new server (where only `root` exists), run this command to create the user, secure SSH, and set everything up.

```bash
cd ansible
ansible-playbook -i inventory setup.yml -e "ansible_user=root" --ask-vault-pass
```

> [!Note]
> If the server was rebuilt, you might need to clear the old SSH fingerprint first:

```bash
ssh-keygen -R <ip>
```

### 2. Subsequent Runs (Updates & Maintenance)

Once the user is created and keys are set up, run this for all future updates (installing new tools, updating dotfiles, etc.):

```bash
cd ansible
ansible-playbook -i inventory setup.yml --ask-vault-pass --ask-become-pass
```

## ✅ Post-Installation Checks

After the playbook finishes, log in and verify the environment:

```bash
ssh <user>@<ip>
```

- Neovim: nvim --version (Should be latest stable via Bob)

- Node: node -v (Should be installed via NVM)

- Go: go version

- Docker: docker ps (Should run without sudo)
