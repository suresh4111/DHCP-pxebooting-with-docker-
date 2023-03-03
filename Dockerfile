FROM centos:centos7
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
#RUN yum install -y  dhcp*  xinetd  tftp-server httpd syslinux
#COPY dhcpd.conf /etc/dhcp/dhcpd.conf
#RUN mkdir -p /var/lib/tftpboot/pxelinux.cfg/
#COPY pxelinux.0 /var/lib/tftpboot/
#RUN sed -i "s14/yes/no/" /etc/xinetd.d/tftp \
#RUN mkdir -p /var/pxe/centos7
#ADD ./centos7/ /var/pxe/centos7
#RUN mkdir -p /var/lib/tftpboot/centos7
#COPY vmlinuz /var/lib/tftpboot/centos7 
#COPY initrd.img /var/lib/tftpboot/centos7 
#COPY menu.c32 /var/lib/tftpboot
#COPY default /var/lib/tftpboot/pxelinux.cfg/default
#COPY pxeboot.conf /etc/httpd/conf.d/pxeboot.conf
COPY new_pxe.sh /
RUN chmod +x /new_pxe.sh
RUN bash -c "/new_pxe.sh"
#ENTRYPOINT ["/bin/bash","/pxe1.sh"]
#RUN systemctl enable dhcpd \
# && systemctl enable xinetd.service \
# && systemctl enable tftp.service \
# && systemctl enable httpd
#ADD pxe1.sh /pxe1.sh
#RUN chmod +x /pxe1.sh
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]
