yum install -y dhcp* syslinux xinetd tftp-server httpd

tee /etc/dhcp/dhcpd.conf<<EOF
#host_change=server Host ip, subnet_change=subnet, netmask_change=netmask, range_start=starting ip, range_end=ending ip, 
option domain-name "host_change";
subnet subnet_change netmask netmask_change{
	range range_start range_end;
	option routers host_change;

filename "pxelinux.0";
next-server host_change;
}
EOF
read -p "enter server ip: " s_ip
read -p "enter subnet mask: " sub_ip
read -p "enter netmask: " net_ip
read -p "enter starting ip range:" start_ip
read -p "enter ending ip range:" end_ip
sed -i -e "s/host_change/${s_ip}/g" /etc/dhcp/dhcpd.conf
sed -i -e "s/subnet_change/${sub_ip}/g" /etc/dhcp/dhcpd.conf
sed -i -e "s/netmask_change/${net_ip}/g" /etc/dhcp/dhcpd.conf
sed -i -e "s/range_start/${start_ip}/g" /etc/dhcp/dhcpd.conf
sed -i -e "s/range_end/${end_ip}/g" /etc/dhcp/dhcpd.conf

mkdir /var/lib/tftpboot/pxelinux.cfg
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/
sed -i -e "s/disable                 = yes/disable                 = no/"  /etc/xinetd.d/tftp
systemctl start xinetd
systemctl enable xinetd
mkdir -p /var/pxe/centos7
mkdir -p /var/lib/tftpboot/centos7
mount -t iso9660 -o loop /dev/cdrom /var/pxe/centos7/
cp /var/pxe/centos7/images/pxeboot/vmlinuz /var/lib/tftpboot/centos7/
cp /var/pxe/centos7/images/pxeboot/initrd.img /var/lib/tftpboot/centos7/
cp /usr/share/syslinux/menu.c32 /var/lib/tftpboot/

tee /var/lib/tftpboot/pxelinux.cfg/default<<EOF
#server_ip
timeout 100
default menu.c32
menu title #######PXE BOOT MENU####
label 1
        menu label ^1) Install centos7
        kernel centos7/vmlinuz
        append initrd=centos7/initrd.img ks=http://host_change/ks/centos7-ks.cfg method=http://host_change/centos7/ devfs=nomount
label 2
        menu label ^2) Boot from local drive
        localboot
EOF
sed -i -e "s/host_change/${s_ip}/g" /var/lib/tftpboot/pxelinux.cfg/default

systemctl start httpd
systemctl enable httpd

tee /etc/httpd/conf.d/pxeboot.conf<<EOF
#subnet_ip
Alias /centos7 /var/pxe/centos7
<Directory /var/pxe/centos7>
        options Indexes FollowSymlinks
        Require ip 127.0.0.1 subnet_change/24
</Directory>
EOF
sed -i -e "s/subnet_change/${sub_ip}/g" /etc/httpd/conf.d/pxeboot.conf
python -c 'import crypt,getpass;print(crypt.crypt(getpass.getpass(),crypt.mksalt(crypt.METHOD_SHA512)))' > pass.txt
mkdir /var/www/html/ks

tee /var/www/html/ks/centos7-ks.cfg<<EOF
#create new
install
# automatically proceed for each steps
autostep
# reboot after installing
reboot
# encrypt algorithm
auth --enableshadow --passalgo=sha512
# installation source
url --url=http://host_change/centos7/
# install disk
ignoredisk --only-use=sda
# keyboard layouts
keyboard --vckeymap=jp106 --xlayouts='jp','us'
# system locale
lang en_US.UTF-8
# network settings
network --bootproto=dhcp --ipv6=auto --activate --hostname=localhost
# root password you generated above
rootpw --iscrypted < pass.txt
# timezone
timezone Asia/Tokyo --isUtc --nontp
# bootloader's settings
bootloader --location=mbr --boot-drive=sda
# initialize all partition tables
zerombr
clearpart --all --initlabel
# partitioning
autopart --type=lvm
#part /boot --fstype="xfs" --ondisk=sda --size=500
#part pv.10 --fstype="lvmpv" --ondisk=sda --size=51200
#volgroup VolGroup --pesize=4096 pv.10
#logvol / --fstype="xfs" --size=20480 --name=root --vgname=VolGroup
#logvol swap --fstype="swap" --size=4096 --name=swap --vgname=VolGroup
%packages
@core
%end
EOF
sed -i -e "s/host_change/${s_ip}/g" /var/www/html/ks/centos7-ks.cfg

