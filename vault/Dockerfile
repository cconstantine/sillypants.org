FROM debian:jessie

RUN apt-get update 
RUN apt-get install -y --no-install-recommends bzip2 ca-certificates unzip

ADD https://releases.hashicorp.com/vault/0.3.1/vault_0.3.1_linux_amd64.zip /tmp/vault.zip
RUN cd /bin && unzip /tmp/vault.zip && chmod +x /bin/vault && rm /tmp/vault.zip

ADD vault.hcl /etc/vault.hcl

EXPOSE 8200


ENTRYPOINT ["vault"]
