FROM centos:7
ARG LINKING_KEY=""
ARG SCANNER_NAME=""
ARG MANAGER_HOST=""
ARG MANAGER_PORT=""
ARG PROXY_HOST=""
ARG PROXY_PORT=""
ARG PROXY_USER=""
ARG PROXY_PASS=""
ARG PROXY_AGENT=""
ARG LICENSE=""
ARG ADMIN_USER="admin"
ARG ADMIN_PASS=""

ENV LINKING_KEY=${LINKING_KEY}
ENV SCANNER_NAME=${SCANNER_NAME}
ENV MANAGER_HOST=${MANAGER_HOST}
ENV MANAGER_PORT=${MANAGER_PORT}
ENV PROXY_HOST=${PROXY_HOST}
ENV PROXY_PORT=${PROXY_PORT}
ENV PROXY_USER=${PROXY_USER}
ENV PROXY_PASS=${PROXY_PASS}
ENV PROXY_AGENT=${PROXY_AGENT}
ENV LICENSE=${LICENSE}
ENV ADMIN_USER=${ADMIN_USER}
ENV ADMIN_PASS=${ADMIN_PASS}

COPY nessus_startup.sh nessus_adduser.exp /usr/bin/
COPY yum.repo /etc/yum.repos.d/Tenable.repo
COPY gpg.key /etc/pki/rpm-gpg/RPM-GPG-KEY-Tenable

RUN    yum -y -q install Nessus expect java-11-openjdk-headless         \
    && yum -y -q clean all                                              \
    && chmod 755 /usr/bin/nessus_startup.sh                             \
    && chmod 755 /usr/bin/nessus_adduser.exp                            \
    && rm -f /opt/nessus/var/nessus/*.db*                               \
    && rm -f /opt/nessus/var/nessus/master.key                          \
    && rm -f /opt/nessus/var/nessus/uuid                                \
    && rm -f /opt/nessus/var/nessus/CA/cakey.pem                        \
    && rm -f /opt/nessus/var/nessus/CA/serverkey.pem                    \
    && rm -rf /tmp/*                                                    \
    && ln -sf /dev/stdout /opt/nessus/var/nessus/logs/nessusd.messages  \
    && ln -sf /dev/stdout /opt/nessus/var/nessus/logs/www_server.log    \
    && ln -sf /dev/stdout /opt/nessus/var/nessus/logs/backend.log       \
    && echo -e "export PATH=$PATH:/opt/nessus/bin:/opt/nessus/sbin" >> /etc/bashrc

EXPOSE 8834
CMD ["/usr/bin/nessus_startup.sh"]