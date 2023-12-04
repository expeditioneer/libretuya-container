FROM registry.access.redhat.com/ubi9/ubi as builder

RUN dnf install --assumeyes git python3-pip \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum

WORKDIR /usr/local
RUN git clone https://github.com/libretiny-eu/libretiny-esphome

WORKDIR /usr/local/libretiny-esphome
RUN git rev-parse --short HEAD >> gitversion
RUN rm --recursive --force \
    .clang-format .clang-tidy .coveragerc .devcontainer .dockerignore .editorconfig .git .gitattributes .github \
    .gitignore .pre-commit-config.yaml .pre-commit-config.yaml .yamllint docker requirements_optional.txt \
    requirements_test.txt SUMMARY.md

########################################################################################################################

FROM registry.access.redhat.com/ubi9/ubi

RUN dnf install --assumeyes git patch python3-pip \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum

ENV DASHBOARD_USER=""
ENV DASHBOARD_PASSWORD=""

COPY files/libretiny_start /usr/local/bin/
COPY files/libretiny-patches/tornado-enable-ssl.patch /usr/local/src/

RUN groupadd libretiny --gid 1000 \
 && useradd libretiny --uid 1000 --gid libretiny --home-dir /usr/local/libretiny-esphome

COPY --chown=1000:1000 --from=builder /usr/local/libretiny-esphome /usr/local/libretiny-esphome

RUN python3 -m pip install --upgrade pip \
 && python3 -m pip install --requirement /usr/local/libretiny-esphome/requirements.txt \
 && python3 -m pip install --editable /usr/local/libretiny-esphome

RUN chown --recursive libretiny: \
    /usr/local/libretiny-esphome

RUN mkdir --parents /etc/libretiny \
 && chown --recursive libretiny: /etc/libretiny

USER libretiny

RUN git config --global advice.detachedHead false

EXPOSE 6052

VOLUME ["/etc/libretiny"]

CMD ["libretiny_start"]
