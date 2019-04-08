FROM ubuntu:18.04

ARG    TURBOVNC_VERSION="2.2.1"
ENV    GUACAMOLE_HOME="/etc/guacamole"
ENV    RES "1920x1080"
EXPOSE 8080

WORKDIR /etc/guacamole

# Install locale and set
RUN apt-get update &&            \
    apt-get install -y           \
      locales &&                 \
    apt-get clean &&             \
    rm -rf /var/lib/apt/lists/*
# Before installing desktop, set the locale to UTF-8
# see https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-ubuntu-docker-container
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install libraries/dependencies
RUN apt-get update &&            \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      software-properties-common \
      libjpeg-turbo8             \
      libjpeg-turbo8-dev         \
      libcairo2-dev              \
      libossp-uuid-dev           \
      libpng-dev                 \
      libpango1.0-dev            \
      libssh2-1-dev              \
      libssl-dev                 \
      libtasn1-bin               \
      libvorbis-dev              \
      libwebp-dev                \
      libpulse-dev               \

      # Install remaining dependencies, tools, and XFCE desktop
      bash-completion  \
      chromium-browser \
      gcc              \
      gcc-6            \
      make             \
      openssh-server   \
      sudo             \
      tomcat8          \
      vim              \
      wget             \
      xfce4            \
#      xfce4-goodies    \
      xauth            \

      # install libvncserver depencies
      libvncserver-dev \
      gtk2.0       &&  \

    apt-get clean &&             \
    rm -rf /var/lib/apt/lists/*

# install turbovnc
RUN wget "https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download" -O /opt/turbovnc.deb && \
    dpkg -i /opt/turbovnc.deb && \
    rm -f /opt/turbovnc.deb

# Download necessary Guacamole files
RUN rm -rf /var/lib/tomcat8/webapps/ROOT && \
    wget "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/1.0.0/binary/guacamole-1.0.0.war" -O /var/lib/tomcat8/webapps/ROOT.war && \
    wget "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/1.0.0/source/guacamole-server-1.0.0.tar.gz" -O /etc/guacamole/guacamole-server-1.0.0.tar.gz && \
    tar xvf /etc/guacamole/guacamole-server-1.0.0.tar.gz && \
    cd /etc/guacamole/guacamole-server-1.0.0 && \
   ./configure --with-init-dir=/etc/init.d &&   \
    make CC=gcc-6 &&                            \
    make install &&                             \
    ldconfig &&                                 \
    rm -r /etc/guacamole/guacamole-server-1.0.0*

# Create Guacamole configurations
RUN echo "user-mapping: /etc/guacamole/user-mapping.xml" > /etc/guacamole/guacamole.properties && \
    touch /etc/guacamole/user-mapping.xml

# Create user account with password-less sudo abilities
RUN useradd -s /bin/bash -g 100 -G sudo -m user && \
    /usr/bin/printf '%s\n%s\n' 'password' 'password'| passwd user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set VNC password
#RUN mkdir /home/user/.vnc && \
#    chown user /home/user/.vnc && \
#    /usr/bin/printf '%s\n%s\n%s\n' 'password' 'password' 'n' | su user -c /opt/TurboVNC/bin/vncpasswd
#RUN  echo -n 'password\npassword\nn\n' | su user -c vncpasswd

# Remove keyboard shortcut to allow bash_completion in xfce4-terminal
RUN echo "DISPLAY=:1 xfconf-query -c xfce4-keyboard-shortcuts -p \"/xfwm4/custom/<Super>Tab\" -r" >> /home/user/.bashrc

# Fix chromium-browser to run with no sandbox
RUN sed -i -e 's/Exec=chromium-browser/Exec=chromium-browser --no-sandbox/g' /usr/share/applications/chromium-browser.desktop

# enable pulse audio
RUN echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> /etc/pulse/default.pa

# Add help message
RUN touch /etc/help-msg

WORKDIR /home/user/Desktop

COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

USER 1000:100

# copy and untar the default xfce4 config so that we don't get an annoying startup dialog
COPY xfce4-default-config.tgz /home/user/xfce4-default-config.tgz
RUN mkdir -p /home/user/.config/xfce4/ && \
    tar -C /home/user/.config/xfce4/ --strip-components=1 -xvzf /home/user/xfce4-default-config.tgz && \
    rm -f /home/user/xfce4-default-config.tgz

# Fix web browser panel launcher
RUN sed -i -e 's/Exec=exo-open --launch WebBrowser %u/Exec=chromium-browser --no-sandbox/g' /home/user/.config/xfce4/panel/launcher-11/15389508853.desktop

ENTRYPOINT sudo -E /startup.sh
