FROM hashicorp/terraform:0.14.11
ARG tfnotify_ver=v0.7.0
ARG assume_role_ver=0.3.2
ARG kustomize_ver=v3.6.1
RUN apk add curl
RUN curl -sL https://github.com/mercari/tfnotify/releases/download/${tfnotify_ver}/tfnotify_linux_amd64.tar.gz  \
  | tar xz -C /tmp \
  && mv /tmp/tfnotify /bin/
RUN curl -sL https://github.com/remind101/assume-role/releases/download/${assume_role_ver}/assume-role-Linux -o /tmp/assume-role \
  && chmod +x /tmp/assume-role \
  && mv /tmp/assume-role /bin
RUN curl -sL https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/0.4.0-alpha.1/aws-iam-authenticator_0.4.0-alpha.1_linux_amd64 -o /tmp/aws-iam-authenticator \
  && chmod +x /tmp/aws-iam-authenticator \
  && mv /tmp/aws-iam-authenticator /bin
RUN curl -sL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /tmp/kubectl \
  && chmod +x /tmp/kubectl \
  && mv /tmp/kubectl /bin
RUN curl -sSL https://github.com/shyiko/kubesec/releases/download/0.9.2/kubesec-0.9.2-linux-amd64 \
  -o kubesec && chmod +x kubesec && mv kubesec /bin/
RUN curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${kustomize_ver}/kustomize_${kustomize_ver}_linux_amd64.tar.gz \
  | tar xz -C /tmp \
  && mv /tmp/kustomize /bin/
FROM circleci/ruby:2.6.0-node
RUN sudo apt-get update && sudo apt-get install -y gcc make
WORKDIR /tmp
RUN curl -sSL http://www.gcd.org/sengoku/stone/stone-2.3e.tar.gz -o stone.tar.gz
RUN tar zxf stone.tar.gz && \
  cd stone-*/ && \
  FLAGS=-D_GNU_SOURCE make linux && chmod +x stone && \
  cp stone /tmp/stone
FROM circleci/ruby:2.7.1-node
COPY --from=0 /bin/terraform /bin
COPY --from=0 /bin/tfnotify /bin
COPY --from=0 /bin/assume-role /bin
COPY --from=0 /bin/aws-iam-authenticator /bin
COPY --from=0 /bin/kubectl /bin
COPY --from=0 /bin/kubesec /bin
COPY --from=0 /bin/kustomize /bin
COPY --from=1 /tmp/stone /bin
RUN sudo apt-get -y update \
  && sudo apt -y install mariadb-client python3 python3-pip mariadb-server redis groff-base \
  && pip3 install awscli mycli datadog \
  && sudo gem update --system
RUN curl -sSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb" \
  && sudo dpkg -i /tmp/session-manager-plugin.deb \
  && rm /tmp/session-manager-plugin.deb
COPY tools/lock.sh /bin
COPY tools/do-exclusively.sh /bin
RUN sudo chmod +x /bin/do-exclusively.sh \
    && sudo chmod +x /bin/lock.sh
COPY tools/do-exclusively-workflow.sh /bin/do-exclusively-workflow.sh
RUN sudo chmod +x /bin/do-exclusively-workflow.sh
ENV PATH $PATH:/home/circleci/.local/bin
RUN echo 'export PATH=$PATH:${HOME}/.local/bin' >> /home/circleci/.bashrc
