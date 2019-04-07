#!/bin/bash

help (){
echo "USAGE:
docker run -it -p 8080:8080 ubuntu-desktop-docker:<tag> <option>

OPTIONS:
-v, --vnc-only  only add VNC connection to Guacamole (no SSH Shell)
-h, --help      print out this help

For more information see: https://github.com/cyverse/ubuntu-desktop-docker"
}

vnc-only () {
  echo \
"<user-mapping>
    <authorize username=\"user\" password=\"password\">
        <connection name=\"VNC\">
            <protocol>vnc</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"username\">user</param>
            <param name=\"password\">password</param>
            <param name=\"port\">5901</param>
            <param name=\"enable-sftp\">true</param>
            <param name=\"sftp-username\">user</param>
            <param name=\"sftp-password\">password</param>
            <param name=\"sftp-directory\">/home/user</param>
            <param name=\"sftp-root-directory\">/home/user</param>
            <param name=\"enable-audio\">true</param>
            <param name=\"audio-servername\">127.0.0.1</param>
        </connection>
    </authorize>
</user-mapping>" > /etc/guacamole/user-mapping.xml

  echo \
"*==================================================================*
  Use this link for direct VNC Desktop:
  http://localhost:8080/guacamole?username=user&password=password

  Once connected to the session, your user info is:
      Username: \"user\"
      Password: \"password\"
*==================================================================*" > /etc/help-msg
}

default () {
  echo \
"<user-mapping>
    <authorize username=\"user\" password=\"password\">
        <connection name=\"VNC\">
            <protocol>vnc</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"username\">user</param>
            <param name=\"password\">password</param>
            <param name=\"port\">5901</param>
            <param name=\"enable-sftp\">true</param>
            <param name=\"sftp-username\">user</param>
            <param name=\"sftp-password\">password</param>
            <param name=\"sftp-directory\">/home/user</param>
            <param name=\"sftp-root-directory\">/home/user</param>
            <param name=\"enable-audio\">true</param>
            <param name=\"audio-servername\">127.0.0.1</param>
        </connection>
        <connection name=\"SSH\">
            <protocol>ssh</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"username\">user</param>
            <param name=\"password\">password</param>
            <param name=\"port\">22</param>
            <param name=\"enable-sftp\">true</param>
            <param name=\"sftp-root-directory\">/home/user</param>
        </connection>
    </authorize>
</user-mapping>" > /etc/guacamole/user-mapping.xml

  echo \
"*==================================================================*
  For the Guacamole Homepage:
  http://localhost:8080/?username=user&password=password

  For direct VNC Desktop:
  http://localhost:8080/#/client/Vk5DAGMAZGVmYXVsdA==?username=user&password=password

  For direct SSH Shell:
  http://localhost:8080/#/client/U1NIAGMAZGVmYXVsdA==?username=user&password=password

  Once connected to the session, your user info is:
      Username: \"user\"
      Password: \"password\"
*==================================================================*" > /etc/help-msg
}

if [[ $1 =~ -h|--help ]]; then
  help
  exit 0
fi

if [[ $1 =~ -v|--vnc-only ]]; then
  vnc-only
else
  default
fi

service ssh start &&   \
service tomcat8 start; \
#su user -c "USER=user vncserver -depth 24 -geometry $RES -name \"VNC\" :1" && \
su user -c "USER=user /opt/TurboVNC/bin/vncserver -localhost -verbose -nohttpd -depth 24 -geometry $RES -securitytypes NONE -name \"VNC\" :1" && \
cat /etc/help-msg && \
guacd -L debug -f
