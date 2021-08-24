FROM centos:7

ARG LICENSE=""
ARG ADMIN_USER="admin"
ARG ADMIN_PASS="password"

ENV LC_ALL "en_US.UTF-8"
ENV LANG "en_US.UTF-8"

COPY yum.repo /etc/yum.repos.d/Tenable.repo
COPY gpg.key /etc/pki/rpm-gpg/RPM-GPG-KEY-Tenable

RUN yum -y -q install                                                   \
        Nessus                                                          \
        expect                                                          \
        java-11-openjdk-headless                                        \
        python3                                                         \
        python3-pip                                                     \
 && pip3 install typer pytenable pyyaml pexpect                         \
 && yum -y -q clean all                                                 \
 && ln -sf /dev/stdout /opt/nessus/var/nessus/logs/nessusd.messages     \
 && ln -sf /dev/stdout /opt/nessus/var/nessus/logs/www_server.log       \
 && ln -sf /dev/stdout /opt/nessus/var/nessus/logs/backend.log

COPY scanner.py /usr/bin/scanme

RUN chmod 755 /usr/bin/scanme                                           \
 && /usr/bin/scanme adduser ${ADMIN_USER} ${ADMIN_PASS}                 \
 && /opt/nessus/sbin/nessuscli fetch --register ${LICENSE}              \
 && /opt/nessus/sbin/nessusd -R                                         \
 && /opt/nessus/sbin/nessuscli fix --set auto_update=no                 \
 && /usr/bin/scanme spawn --terminate                                   \
 && echo -e "username: \"${ADMIN_USER}\"" > /etc/nessus_creds.yaml      \
 && echo -e "password: \"${ADMIN_PASS}\"" >> /etc/nessus_creds.yaml     \
 && mkdir /creds                                                        \
 && mkdir /scan

EXPOSE 8834

ENTRYPOINT ["/usr/bin/scanme", "scan"]
