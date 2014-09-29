# Things to try

- Follow guides
- Use a private repo for push/pull.
- Test CPU shares.
- Try https://github.com/crosbymichael/minecraft-docker
- Look for official Tomcat image
- Other resource limits, network bandwidth?
- How does FROM ubuntu run on e.g. Amazon AMI?
- Other misc stuff from below

# Notes

The lxc-docker install process starts the daemon by default using upstart (/etc/init).

Even though you're root, your *capabilities* are limited. e.g. `poweroff` gets `shutdown: unable to shutdown system`.

Use docker run --name=foo early. Pets vs cattle and all that but for testing call it 'python'.

## tty

If a tty is active on attach, we use `utils.CopyEscapable(cStdin, stdin)` instead of `io.Copy(cStdin, stdin)` in `docker/daemon/attach.go`.

The implementation of ^P^Q can be found at https://github.com/docker/docker/blob/master/utils/utils.go#L216

So: if you attach with tty, ^P^Q will be interpreted. Is tty ever false here?

## Docker as Salt minion

The image will assume the hostname is good. This is the right approach, `docker run` lets you invent your hostname.
We will invent a convention `docker-0123` so the salt master can distinguish the containers.

Cleverness:
1. Don't start the service when you install the salt-minion.
1. Insert our config file with master location.
1. Run as a foreground process in ENTRYPOINT, not as a service.

## The good bits

Port mapping. Can bind ports to specific interfaces, e.g. a port is only available on localhost, not the external interface! Very useful.
Dockerfile RUN layers.
An image can be used as a (potentially very complex) executable, auto-downloaded.
Linking containers without exposing ports.

## Terms and naming

Image naming: a single word is a *base* or *root* image: they are official and maintained by Docker.

From http://blog.thoward37.me/articles/where-are-docker-images-stored/
- An Image is an opaque asset. A Dockerfile is the source code that creates an Image (by docker build). The Docker Index shows Images, not Dockerfiles. Docker push publishes your image, not your Dockerfile.
- An Index is accounts, permissions, search, tagging. A registry stores images and uses an Index for auth.
  - docker search works against the index. The index can point off to multiple registries.
  - docker push/pull works against the index, then gets forwarded to the appropriate registry.
- A registry holds a collection of named repositories.
- A repository is a collection of Images tracked by GUIDs.
  - The same image can be stored under different tags.
  - A repository name is sometimes the whole user/repo string (air/somerepo).
  - The public index will require you to put your username in front. Otherwise you're in the 'root' of the repository.

## Commands

`docker pull` to download an image into local cache that you know you'll need.
`docker search` to find an image from the command line.
`docker commit` to save off the disk of a container as a new image.

## Linking

For this to work, your server container must have an EXPOSE declaration.

Start a server and tell Docker to EXPOSE a port. This doesn't actually open a port!

    $ docker run -d --name=python --expose=8000 ubuntu python3 -u -m http.server

Now we can logically link another container. We get

    $ docker run --link python:http ubuntu nc -zv http 8000
    Connection to http 8000 port [tcp/*] succeeded!

Technically we should read the `8000` value from an env var but the variable gets eaten by the shell.

Docker gives you a bunch of env vars, and an /etc/hosts entry to find your server, e.g.:

    DB_PORT=tcp://172.17.0.5:5432
    DB_PORT_5432_TCP=tcp://172.17.0.5:5432
    DB_PORT_5432_TCP_PROTO=tcp
    DB_PORT_5432_TCP_PORT=5432
    DB_PORT_5432_TCP_ADDR=172.17.0.5

## Streams

`-i` attaches the PID's stdout, stderr to the current terminal.
- Because stdin is attached, you can interact with e.g. `bash`! You just won't see the prompt returned to you.
- This is enough to attach and pipe other processes.
- You can't send signals. e.g. `docker run -i ubuntu bash` is impossible to exit from! This may be a bug (see Issues).

`-t` creates a `pty` in the container (confirm - it's definitely stateful as a startup decision), which allows more complex interaction than stdin/stdout.
- You can send signals.
- If you don't run with a `-t` tty, your process will not accept signals on attach. Ref. https://github.com/docker/docker/issues/2855#issuecomment-56553415
  - This can't be exactly true: The default is forward signals. I can kill a `top` that was not run with `-t` - surely with no TTY I can't Ctrl-C the process?

These flags are important and stateful even in `-d` daemon mode! If you want to attach to your `bash` container and see a prompt, you will need `docker run -i -t -d ubuntu bash`.

It's not clear. Even if you `run` without `-t`, `attach` can be run later and because "it assumes" a terminal, you can send signals to the process.

Weird combinations
- Using `-t` without `-i` seems weird
- `--sig-proxy` seems pointless if you run in `-d` daemon mode, since the thing responsible for proxying goes away.

## Signals

With `docker run/attach --sig-proxy=true`, docker will catch selected signals and forward them to the PID. This is useful if a `tty` is not attached. SIGKILL is not forwarded, i.e. it will kill docker.

With `docker kill --signal="QUIT"` you can send arbitrary signals to the PID, e.g. to generate a `kill -3` Java thread dump.

## Dockerfiles

Create new images, two options:
1. Take any container with some modified state (e.g. an extra installed package) and `docker commit` it with an image name (`air/foo`) and version tag. You can give a commit message and an author name.
  - This is not source controllable.
2. Script it with `docker build` against a Dockerfile. Supply a version tag.

Every command in the Dockerfile creates a new layer.

Every command is executed in its own context - so stateful commands like `cd foo` will do nothing.

`docker build` will send everything in the directory to the daemon - so start with an empty dir and add just the things you need.

If your RUN involves a 'latest' state, like `dist-upgrade -y`, you'll need to invalidate the docker build cache to force it to be evaluated again.

CMD: the default command that can be overwritten.
ENTRYPOINT: the non-negotiable command that will accept `docker run` arguments.
You can have both usefully, e.g.

    ENTRYPOINT ["java"]
    CMD ["-Xmx1536M", "-Xms768M", "-jar", "/minecraft.jar", "nogui"]

ONBUILD: a trigger to execute if someone uses this image as a FROM.

Gotcha: Your Dockerfile is just setting up a file state. You can't start a service in it.

Gotcha: you need DEBIAN_FRONTEND=noninteractive to avoid apt-get warnings; but don't set as an ENV, or the setting will persist into the running container.

Tip: If you're running a service, you're probably Doing It Wrong. Run foreground as main process.

Dockerfile reference examples are weak!

# Gotchas

TODO raise these issues!

The moment you realise all these containers are being remembered, that's when you need to know `docker ps -a`.
PORTS will be blank in `docker ps -a` even if it has port mappings.

## Not docker: Python buffers stdin

The stderr output of `python -m http.server` will not be shown in docker logs (or attached!) until you kill the process, at which point it all appears. You need `python -u` to unbuffer stdin.

## no-stdin=false is a double negative

Raised https://github.com/docker/docker/issues/8183

## Attach is a mess

"Attach isn't intended to run new stuff in the container. It's meant to attach to the running process."

It doesn't work as documented: Ctrl-C kills the process. i.e. It proxies the signal to the PID even though we didn't specify `--sig-proxy=true`. Update: docs were updated to match the behaviour.

- https://github.com/docker/docker/issues/2855
- http://docs.docker.com/reference/commandline/cli/#attach

Also, if you run python, Ctrl-C does nothing at all.

IF you're in an interactive shell (i.e. specifically a shell process?) then Ctrl-p, Ctrl-q will safely get you out of the container.

Lack of technical leadership on e.g. https://github.com/docker/docker/issues/2855 - going on forever.

Solomon:
> I'm the one to blame for the "carpet-bomb consistency" across run, start and attach. My reasoning was that the default behavior should be consistent. But in the case of attach I see the problem.
> Ironically now I worry about causing even more damage by "flip-flopping" and changing back the attach behavior. What do you think?

### Philosophy

Some users are misled into thinking that a container is a "mini quarantined OS". Therefore attaching to the container should allow general interactivity without necessarily messing with the primary process.
This idea is wrong. It derives from the experience of logging into a VM. Brian Goff:
> When you SSH into a VM, you aren't attaching to the VM, you are connecting to a process inside the VM (which itself was started by /sbin/init) which fires off (generally speaking) a new shell process.

Compare this to docker. Brian Goff:
> If you ps faux on your host machine, you won't see a "container process", you'll see all the stuff running in each container as direct descendants of the docker daemon process (except in cases where the container's process was not started with exec, in which case there will be a /bin/sh -c in between).

> While attach is not well named, particularly because of the LXC command lxc-attach (which is more akin docker exec <container> /bin/sh, but LXC specific), it does have a specific purpose of literally attaching you to the process Docker started.
Depending on what the process is the behavior may be different, for instance attaching to /bin/bash will give you a shell, but attaching to redis-server will be like you'd just started redis directly without daemonizing.

> docker logs, for example, is pretty much the same thing as docker attach, but without any input.

An addendum notes that docker logs actually uses a process to write logs to a file before streaming to the client - it's not a direct stream)

Example:

    root       670  0.0  2.1 626600 10844 ?        Ssl  Sep28   0:02 /usr/bin/docker -d
    root      3088  9.2  2.9  49316 15008 ?        Ss   11:16   0:00  \_ python3 -u -m http.server

## Stop is a mess

Beware of docker SIGKILLing your app.

Why is stop taking all ten seconds of the timeout??
- Perhaps because bash is immune to SIGTERM?, https://github.com/docker/docker/issues/3766
- Well why does a python daemon act the same? Just try and Ctrl-C this foreground process:
  - `docker run ubuntu /bin/sh -c "python3 -m http.server"`
- The 'main' issue for this is https://github.com/docker/docker/issues/2436
- It's because the container command is run as PID 1, which is unkillable by SIGTERM - unless you install a trap yourself (e.g. in a bash script). https://github.com/docker/docker/pull/3240
- This seems to be a dead end and not being addressed for now.

Consequences:
- Processes that have their output buffered (see issue #1) will have that output killed before it gets to disk! Your `docker logs` will show nothing because the process didn't get a SIGTERM.

# Resources
http://blog.thoward37.me/articles/where-are-docker-images-stored/

https://registry.hub.docker.com/_/ubuntu/

# Criticism
https://news.ycombinator.com/item?id=8167928
Cute names - why didn't they use a better word list?


# To do

  - Use volumes, signals, nsenter rather than sshd. http://blog.docker.com/why-you-dont-need-to-run-sshd-in-docker/
  - Check concepts, best practices at http://radial.viewdocs.io/docs/topology

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
