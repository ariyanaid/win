#!/bin/bash

# Unduh gambar Windows, ekstrak, dan tulis ke disk
wget -O- http://159.65.136.1/shiro22.gz | gunzip | dd of=/dev/vda bs=4M status=progress

# Buat skrip enable_rdp.bat
cat <<'EOF' > /mnt/Windows/Setup/Scripts/enable_rdp.bat
@echo off
:: Cek apakah Remote Desktop sudah diaktifkan
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections | findstr /i "0x0"
if %errorlevel%==0 (
    echo Remote Desktop sudah diaktifkan.
    exit /b 0
)

:: Aktifkan Remote Desktop
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

:: Izinkan Remote Desktop melalui Windows Firewall
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes

echo Remote Desktop telah diaktifkan.
exit /b 0
EOF

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
