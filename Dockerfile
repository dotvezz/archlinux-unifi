# Use Archlinux base/devel so we can use makepkg
FROM base/devel

# Install needed software
RUN pacman -Sy jre8-openjdk-headless fontconfig python yajl git wget --needed --noconfirm

# Pre-install older versions of `mongodb` and `wiredtiger` because mongodb 3.6 breaks unifi
WORKDIR /root
RUN wget -nv https://archive.archlinux.org/packages/m/mongodb/mongodb-3.4.9-1-x86_64.pkg.tar.xz && wget -nv https://archive.archlinux.org/packages/w/wiredtiger/wiredtiger-2.9.3-1-x86_64.pkg.tar.xz
RUN pacman -U *.pkg.* --noconfirm

# Prep a `nobody` home folder for makepkg
RUN mkdir /home/nobody && chown nobody:nobody /home/nobody

# Build and install `unifi`
WORKDIR /home/nobody
USER nobody
RUN git clone https://aur.archlinux.org/unifi.git && cd unifi && makepkg --skippgpcheck
USER root
WORKDIR /home/nobody/unifi
RUN pacman -U *.pkg.* --noconfirm

# Expose the correct ports and start/enable `unifi`
EXPOSE 8443
EXPOSE 8080
EXPOSE 3478/UDP

# Get some systemctl functionality
WORKDIR /root
RUN git clone https://github.com/gdraheim/docker-systemctl-replacement && cd docker-systemctl-replacement && git checkout tags/v1.1.2000 && cp files/docker/systemctl.py /usr/bin/systemctl

# Persist the settings and database for unifi
VOLUME /var/lib/unifi/
VOLUME /usr/lib/unifi/
VOLUME /var/log/unifi/

# RUN systemctl start unifi
ENTRYPOINT systemctl start unifi && bash
