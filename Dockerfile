FROM ubuntu:16.04

WORKDIR /etc/guacamole

# Install libraries/dependencies
RUN apt-get update &&            \
    apt-get install -y           \
      software-properties-common \
      libjpeg62                  \
      libjpeg62-dev              \
      libcairo2-dev              \
      libossp-uuid-dev           \
      libpng12-dev               \
      libpango1.0-dev            \
      libssh2-1-dev              \
      libssl-dev                 \
      libtasn1-3-bin             \
      libvorbis-dev              \
      libwebp-dev &&             \
    rm -rf /var/lib/apt/lists/*

# Install remaining dependencies, tools, and XFCE desktop
RUN apt-get update &&  \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      bash-completion  \
      firefox          \
      gcc              \
      libvncserver-dev \
      make             \
      openssh-server   \
      sudo             \
      tomcat7          \
      vim              \
      wget             \
      xfce4            \
      xfce4-goodies && \
    rm -rf /var/lib/apt/lists/*

# Install TigerVNC server
RUN wget "https://bintray.com/tigervnc/stable/download_file?file_path=ubuntu-16.04LTS%2Famd64%2Ftigervncserver_1.8.0-1ubuntu1_amd64.deb" -O /root/tigervnc.deb && \
    dpkg -i /root/tigervnc.deb && \
    rm /root/tigervnc.deb

# Download necessary Guacamole files
RUN wget "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/0.9.14/binary/guacamole-0.9.14.war" -O /var/lib/tomcat7/webapps/guacamole.war
RUN wget "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/0.9.14/source/guacamole-server-0.9.14.tar.gz" -O /etc/guacamole/guacamole-server-0.9.14.tar.gz
RUN tar xvf /etc/guacamole/guacamole-server-0.9.14.tar.gz

# Install guacd
WORKDIR /etc/guacamole/guacamole-server-0.9.14
RUN ./configure --with-init-dir=/etc/init.d && \
    make &&                                    \
    make install &&                            \
    ldconfig &&                                \
    rm -r /etc/guacamole/guacamole-server-0.9.14*

# Create Guacamole configurations
ENV GUACAMOLE_HOME="/etc/guacamole"
RUN echo "user-mapping: /etc/guacamole/user-mapping.xml" > /etc/guacamole/guacamole.properties
RUN echo \
"<user-mapping>\n\
    <authorize username=\"user\" password=\"password\">\n\
        <connection name=\"VNC\">\n\
            <protocol>vnc</protocol>\n\
            <param name=\"hostname\">localhost</param>\n\
            <param name=\"username\">user</param>\n\
            <param name=\"password\">password</param>\n\
            <param name=\"port\">5901</param>\n\
            <param name=\"enable-sftp\">true</param>\n\
            <param name=\"sftp-username\">user</param>\n\
            <param name=\"sftp-password\">password</param>\n\
            <param name=\"sftp-directory\">/home/user</param>\n\
            <param name=\"sftp-root-directory\">/home/user</param>\n\
        </connection>\n\
        <connection name=\"SSH\">\n\
            <protocol>ssh</protocol>\n\
            <param name=\"hostname\">localhost</param>\n\
            <param name=\"username\">user</param>\n\
            <param name=\"password\">password</param>\n\
            <param name=\"port\">22</param>\n\
            <param name=\"enable-sftp\">true</param>\n\
            <param name=\"sftp-root-directory\">/home/user</param>\n\
        </connection>\n\
    </authorize>\n\
</user-mapping>\n" > /etc/guacamole/user-mapping.xml

# Add help message
RUN echo \
"*==================================================================*\n\n\
  To access the Desktop, point your browser to:\n\n\
  http://localhost:8080/guacamole?username=user&password=password\n\n\
  Once connected to the session, your user info is:\n\n\
      Username: \"user\"\n\
      Password: \"password\"\n\n\
*==================================================================*" > /etc/help-msg

# Create user account with password-less sudo abilities
RUN useradd -s /bin/bash -g 100 -G sudo -m user
RUN /usr/bin/printf '%s\n%s\n' 'password' 'password'| passwd user
RUN echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set VNC password
RUN /usr/bin/printf '%s\n%s\n%s\n' 'password' 'password' 'n' | su user -c vncpasswd

# Remove keyboard shortcut to allow bash_completion in xfce4-terminal
RUN echo "DISPLAY=:1 xfconf-query -c xfce4-keyboard-shortcuts -p \"/xfwm4/custom/<Super>Tab\" -r" >> /home/user/.bashrc

WORKDIR /home/user
ENV RES="1920x1080"
EXPOSE 8080

ENTRYPOINT service guacd start && \
           service ssh start &&   \
           service tomcat7 start; \
           su user -c "USER=user vncserver -depth 24 -geometry $RES -name \"VNC\" :1" && \
           cat /etc/help-msg && \
           tail -f /dev/null
