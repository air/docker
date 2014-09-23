# Set up a Salt minion with prebaked master IP.
# The salt-minion runs in the foreground as the main process, not as a service!

FROM ubuntu

MAINTAINER Aaron Bell <aaron.bell+fromweb@gmail.com>

# install add-apt-repository
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common

# register the salt repo
RUN add-apt-repository -y ppa:saltstack/salt

# install salt but don't start the service! That would create a minion_id.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive RUNLEVEL=1 apt-get install -y salt-minion

# override config file with location of master
ADD minion /etc/salt/minion

# minion only starts when the container runs - the correct time to create a new identity based on hostname
ENTRYPOINT ["/usr/bin/salt-minion", "-l", "debug"]

