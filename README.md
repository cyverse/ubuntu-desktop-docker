# ubuntu-desktop-docker

This is a container that has a full Guacamole installation and Ubuntu XFCE desktop. This allows someone to have a simple all-in-one desktop through their web browser.

First, get the image by cloning this repository and building it:
```
docker build -t ubuntu-desktop-docker .
```
or by pulling from Docker Hub:
```
docker pull calvinmclean/ubuntu-desktop-docker
```

Then, run it:
```
docker run -ti -p 8080:8080 ubuntu-desktop-docker
```

When the container finishes starting up, it will present you with a link to access the desktop.
