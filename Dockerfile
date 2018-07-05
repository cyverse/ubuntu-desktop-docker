FROM ubuntu:16.04

WORKDIR /etc/guacamole

# Install libraries/dependencies
RUN apt-get update &&            \
    apt-get install -y           \
      software-properties-common \
      libjpeg62                  \
      libcairo2-dev              \
      libjpeg62-dev              \
      libpng12-dev               \
      libpango1.0-dev            \
      libssh2-1-dev              \
      libssl-dev                 \
      libossp-uuid-dev           \
      libwebp-dev                \
      libvorbis-dev &&           \
    rm -rf /var/lib/apt/lists/*

# Install remaining dependencies and tools
RUN apt-get update &&  \
    apt-get install -y \
      automake         \
      gcc              \
      git              \
      libvncserver-dev \
      make             \
      tomcat7          \
      wget &&          \
    rm -rf /var/lib/apt/lists/*

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
        <protocol>vnc</protocol>\n\
        <param name=\"hostname\">localhost</param>\n\
        <param name=\"username\">root</param>\n\
        <param name=\"port\">5901</param>\n\
        <param name=\"password\">password</param>\n\
    </authorize>\n\
</user-mapping>\n" > /etc/guacamole/user-mapping.xml

# Install desktop and VNC server
RUN apt-get update &&   \
    apt-get install -y  \
      xfce4             \
      xfce4-goodies     \
      libtasn1-3-bin && \
    rm -rf /var/lib/apt/lists/*

# Install some goodies
RUN apt-get update &&  \
    apt-get install -y \
      bash-completion  \
      firefox          \
      vim &&           \
    rm -rf /var/lib/apt/lists/*

# Install TigerVNC server
RUN wget "https://bintray.com/tigervnc/stable/download_file?file_path=ubuntu-16.04LTS%2Famd64%2Ftigervncserver_1.8.0-1ubuntu1_amd64.deb" -O /root/tigervnc.deb && \
    dpkg -i /root/tigervnc.deb && \
    rm /root/tigervnc.deb

# Set VNC password
RUN /usr/bin/printf '%s\n%s\n%s\n' 'password' 'password' 'n' | vncpasswd

# Remove keyboard shortcut to allow bash_completion in xfce4-terminal
RUN echo "DISPLAY=:1 xfconf-query -c xfce4-keyboard-shortcuts -p \"/xfwm4/custom/<Super>Tab\" -r" >> /root/.bashrc

# Add help message
RUN echo \
"*==================================================================*\n\n\
  To access the Desktop, point your browser to:\n\n\
  http://localhost:8080/guacamole?username=user&password=password\n\n\
*==================================================================*" > /etc/help-msg

WORKDIR /root
ENV RES="1920x1080"
EXPOSE 8080

ENTRYPOINT service guacd start && \
           service tomcat7 start; \
           USER=root vncserver -depth 24 -geometry $RES :1 && \
           cat /etc/help-msg && \
           tail -f /dev/null
