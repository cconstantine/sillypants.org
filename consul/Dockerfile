FROM debian:jessie

RUN apt-get update 
RUN apt-get install -y --no-install-recommends bzip2 ca-certificates unzip

ADD https://releases.hashicorp.com/consul/0.6.0/consul_0.6.0_linux_amd64.zip /tmp/consul.zip
RUN cd /bin && unzip /tmp/consul.zip && chmod +x /bin/consul && rm /tmp/consul.zip


EXPOSE 8300 8301 8301/udp 8302 8302/udp 8400 8500 53/udp


ENTRYPOINT ["consul"]
