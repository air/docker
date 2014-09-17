# To do

1. Use a config product to set up new docker nodes. Same setup on a fresh Ubuntu droplet.
1. Read docker user guide and make notes.

  - Work through all core stuff on Ubuntu
  - Use volumes, signals, nsenter rather than sshd. http://blog.docker.com/why-you-dont-need-to-run-sshd-in-docker/
  - Check concepts, best practices at http://radial.viewdocs.io/docs/topology

# Docker notes

Install starts the daemon by default using upstart (/etc/init).

# Things to look at

Docker subprojects, libfoo

http://coreos.com/blog/zero-downtime-frontend-deploys-vulcand/
Akka
Local, EC2, GCE
Kubernetes

Weave

Fig, Orchard.

Service discovery e.g. https://github.com/flynn/discoverd

Atomic

  - CoreOS vs Atomic: Atomic has linked containers for stacks. e.g. Nginx + MariaDB.
  - Has good GUI, cockpit

Similar projects:

- http://ispyker.blogspot.com/2014/06/open-source-release-of-ibm-acme-air.html - https://github.com/EmergingTechnologyInstitute/acmeair-netflixoss-dockerlocal

http://wiredcraft.com/posts/2014/07/30/dns-and-docker-containers.html

new CoreOS/docker/WebGL project
  - what do nodes calculate?
    - a local gravity system
    - control a ship in a 2D system, chase a given peer, avoid close peers
    - navigate a static map, say a 3D landscape, or Andrew's city. Chase a peer?
  - what do we visualise?
    - colliding ships in a 2D space
    -  solar systems in a galaxy. Each nodes comes online as a star birth and ages, developing planets

rationalise http://www.flockport.com/lxc-vs-docker/

## libcontainer

  - nsinit
  - https://github.com/google/cadvisor
