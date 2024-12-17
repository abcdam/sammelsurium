FROM rust:1.81-slim-bookworm
WORKDIR /app

RUN apt update  &&  \
    apt install -y  \
    make            \
    curl            \
    openssh-server  \
    git

### test user section 
# would be handled outside of dockerfile
RUN useradd -m dev-user

RUN mkdir -p /var/run/sshd /home/dev-user/.ssh       \
    && chmod 700 /home/dev-user/.ssh                 \
    && touch /home/dev-user/.ssh/authorized_keys     \
    && chmod 600 /home/dev-user/.ssh/authorized_keys \
    && chown -R dev-user:dev-user /home/dev-user/.ssh

RUN echo "AllowAgentForwarding yes"     >> /etc/ssh/sshd_config \
    && echo "PubkeyAuthentication yes"  >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
###

ENV HOME=/app

RUN mkdir bin lib Downloads
COPY installers/jetbrains/Makefile .
COPY installers/jetbrains/rs.VERSION .

RUN make LANG=rs && rm -r Downloads bin

COPY docker/rust/remote/run.sh .

# kiss workaround
CMD service ssh start && tail -f /dev/null
