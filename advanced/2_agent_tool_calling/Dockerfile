FROM node:24-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash curl ca-certificates git ripgrep openssh-client \
  && rm -rf /var/lib/apt/lists/*
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

WORKDIR /workspace

RUN pi install git:github.com/GusEllerm/pi-lab-profile
RUN git clone https://github.com/GusEllerm/pi-lab-profile && cd pi-lab-profile
RUN pi-lab-profile/scripts/install.sh lab
