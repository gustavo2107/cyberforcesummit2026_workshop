FROM ubuntu:24.04

# tshark no dissecta Lua cuando corre como root. El usuario sin privilegios
# no es higiene: es un requisito funcional de este taller.
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections && \
    apt-get install -y --no-install-recommends \
        tshark \
        python3 \
        python3-pip \
        ca-certificates \
        git \
        jq \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash analyst

USER analyst
WORKDIR /home/analyst

RUN mkdir -p /home/analyst/.local/lib/wireshark/plugins

COPY --chown=analyst:analyst ../evidence/tricotools/TriStation.lua \
     /home/analyst/.local/lib/wireshark/plugins/TriStation.lua

CMD ["sleep", "infinity"]
