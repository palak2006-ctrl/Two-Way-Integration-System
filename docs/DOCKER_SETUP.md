# 🐳 Docker Setup Guide

This guide will help you install Docker on your system, which is required for running Kafka in the Zenskar Integration System.

## 📋 Prerequisites

- **Windows 10/11** (Pro, Enterprise, or Education) with WSL2
- **macOS 10.15+** (Catalina or later)
- **Linux** (Ubuntu 20.04+, CentOS 7+, or similar)

## 🪟 Windows Setup

### **Step 1: Enable WSL2**

1. **Open PowerShell as Administrator** and run:
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

2. **Restart your computer**

3. **Set WSL2 as default**:
   ```powershell
   wsl --set-default-version 2
   ```

### **Step 2: Install Docker Desktop**

1. **Download Docker Desktop** from: https://www.docker.com/products/docker-desktop/
2. **Run the installer** and follow the setup wizard
3. **Enable WSL2 integration** during installation
4. **Restart your computer** if prompted

### **Step 3: Verify Installation**

1. **Open Command Prompt** or PowerShell
2. **Run these commands**:
   ```cmd
   docker --version
   docker-compose --version
   ```
3. **Expected output**:
   ```
   Docker version 24.0.0, build 1234567
   Docker Compose version v2.20.0
   ```

### **Step 4: Start Docker Desktop**

1. **Launch Docker Desktop** from Start Menu
2. **Wait for Docker to start** (whale icon in system tray)
3. **Verify it's running**:
   ```cmd
   docker ps
   ```

## 🍎 macOS Setup

### **Step 1: Install Docker Desktop**

1. **Download Docker Desktop** from: https://www.docker.com/products/docker-desktop/
2. **Drag Docker.app** to Applications folder
3. **Launch Docker Desktop** from Applications
4. **Follow the setup wizard**

### **Step 2: Verify Installation**

1. **Open Terminal**
2. **Run these commands**:
   ```bash
   docker --version
   docker-compose --version
   ```
3. **Expected output**:
   ```
   Docker version 24.0.0, build 1234567
   Docker Compose version v2.20.0
   ```

### **Step 3: Start Docker Desktop**

1. **Launch Docker Desktop** from Applications
2. **Wait for Docker to start** (whale icon in menu bar)
3. **Verify it's running**:
   ```bash
   docker ps
   ```

## 🐧 Linux Setup

### **Ubuntu/Debian**

1. **Update package index**:
   ```bash
   sudo apt-get update
   ```

2. **Install required packages**:
   ```bash
   sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
   ```

3. **Add Docker's official GPG key**:
   ```bash
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   ```

4. **Add Docker repository**:
   ```bash
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

5. **Install Docker Engine**:
   ```bash
   sudo apt-get update
   sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
   ```

6. **Add user to docker group**:
   ```bash
   sudo usermod -aG docker $USER
   ```

7. **Log out and log back in** to apply group changes

### **CentOS/RHEL**

1. **Install required packages**:
   ```bash
   sudo yum install -y yum-utils
   ```

2. **Add Docker repository**:
   ```bash
   sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
   ```

3. **Install Docker Engine**:
   ```bash
   sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
   ```

4. **Start and enable Docker**:
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

5. **Add user to docker group**:
   ```bash
   sudo usermod -aG docker $USER
   ```

## ✅ Verification

### **Test Docker Installation**

Run these commands to verify everything is working:

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker-compose --version

# Test Docker with hello-world
docker run hello-world

# Check if Docker daemon is running
docker ps
```

### **Expected Output**

```
Docker version 24.0.0, build 1234567
Docker Compose version v2.20.0
Hello from Docker!
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS   NAMES
```

## 🚨 Troubleshooting

### **Common Issues**

#### **1. Docker Desktop Won't Start (Windows)**
- **Enable Hyper-V**: Go to Windows Features → Enable Hyper-V
- **Enable Virtual Machine Platform**: Go to Windows Features → Enable Virtual Machine Platform
- **Restart computer** after enabling features

#### **2. WSL2 Issues (Windows)**
```cmd
# Update WSL2
wsl --update

# Set WSL2 as default
wsl --set-default-version 2

# Restart WSL
wsl --shutdown
```

#### **3. Permission Denied (Linux)**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
# Or run: newgrp docker
```

#### **4. Docker Daemon Not Running**
```bash
# Start Docker service (Linux)
sudo systemctl start docker

# Check Docker status
sudo systemctl status docker
```

#### **5. Port Conflicts**
```bash
# Check what's using port 9092 (Kafka)
netstat -tulpn | grep 9092

# Kill process using port
sudo kill -9 $(lsof -ti:9092)
```

## 🔧 Docker Configuration

### **Resource Allocation (Docker Desktop)**

1. **Open Docker Desktop**
2. **Go to Settings** → **Resources**
3. **Recommended settings**:
   - **Memory**: 4GB minimum (8GB recommended)
   - **CPUs**: 2 minimum (4 recommended)
   - **Disk**: 20GB minimum

### **Enable WSL2 Integration (Windows)**

1. **Open Docker Desktop**
2. **Go to Settings** → **Resources** → **WSL Integration**
3. **Enable integration** with your WSL2 distro

## 📚 Additional Resources

- **Docker Documentation**: https://docs.docker.com/
- **Docker Compose Documentation**: https://docs.docker.com/compose/
- **WSL2 Documentation**: https://docs.microsoft.com/en-us/windows/wsl/
- **Docker Desktop for Windows**: https://docs.docker.com/desktop/windows/
- **Docker Desktop for Mac**: https://docs.docker.com/desktop/mac/

## ✅ Next Steps

Once Docker is installed and running:

1. **Verify installation** with the commands above
2. **Proceed with Zenskar setup**:
   - **Windows**: Run `setup_windows.bat`
   - **macOS/Linux**: Run `./start.sh`

## 🆘 Getting Help

If you encounter issues:

1. **Check Docker status**: `docker ps`
2. **View Docker logs**: `docker-compose logs`
3. **Restart Docker Desktop**
4. **Check system requirements**
5. **Search Docker documentation** for specific error messages

---

**🎉 Congratulations!** You now have Docker installed and ready for the Zenskar Integration System!
