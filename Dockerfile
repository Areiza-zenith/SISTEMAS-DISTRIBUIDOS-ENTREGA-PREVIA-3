# Imagen de cada nodo del cluster: Ubuntu 22.04 + Open MPI + servidor SSH
FROM ubuntu:22.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        openmpi-bin libopenmpi-dev openssh-server gcc \
        iputils-ping iproute2 procps \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd \
    && useradd -m -s /bin/bash mpiuser
USER mpiuser
WORKDIR /home/mpiuser
# Llave SSH sin contrasena, compartida por todos los nodos (misma imagen)
RUN ssh-keygen -t rsa -N "" -f .ssh/id_rsa \
    && cat .ssh/id_rsa.pub >> .ssh/authorized_keys \
    && chmod 600 .ssh/authorized_keys \
    && echo "Host *" > .ssh/config \
    && echo "  StrictHostKeyChecking no" >> .ssh/config \
    && echo "  UserKnownHostsFile /dev/null" >> .ssh/config \
    && echo "  LogLevel ERROR" >> .ssh/config
USER root
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
