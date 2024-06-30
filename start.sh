#!/bin/bash

# Perbarui daftar paket dan instal alat yang diperlukan
apt-get update
apt-get install -y wget unzip iproute2

# Unduh dan jalankan script dari URL
wget -O /tmp/start.sh https://raw.githubusercontent.com/ariyanaid/win/main/start.sh
chmod +x /tmp/start.sh
/tmp/start.sh

# Buat skrip enable_rdp.bat
cat <<'EOF' > /tmp/enable_rdp.bat
@echo off
:: Check if Remote Desktop is already enabled
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections | findstr /i "0x0"
if %errorlevel%==0 (
    echo Remote Desktop is already enabled.
    exit /b 0
)

:: Enable Remote Desktop
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

:: Allow Remote Desktop through Windows Firewall
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes

echo Remote Desktop has been enabled.
exit /b 0
EOF

# Salin skrip enable_rdp.bat ke Windows image (asumsikan partisi boot adalah /dev/vda1)
mount /dev/vda1 /mnt
mkdir -p /mnt/Windows/Setup/Scripts
cp /tmp/enable_rdp.bat /mnt/Windows/Setup/Scripts/
umount /mnt

# Deteksi interface Ethernet yang aktif
ETH_INTERFACE=$(ip -o link show | awk '/state UP/ {print $2}' | sed 's/://')

# Konfigurasi jaringan untuk auto-detect
cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto $ETH_INTERFACE
iface $ETH_INTERFACE inet dhcp
EOF

# Restart jaringan untuk menerapkan perubahan
systemctl restart networking

# Aktifkan koneksi Ethernet
ip link set $ETH_INTERFACE up

# Pastikan koneksi Ethernet aktif
dhclient $ETH_INTERFACE

# Langkah verifikasi (opsional)
ifconfig $ETH_INTERFACE

echo "Gambar instalasi Windows telah ditulis ke /dev/vda"
echo "Jaringan dikonfigurasi untuk auto-detect dengan DHCP pada interface: $ETH_INTERFACE"
