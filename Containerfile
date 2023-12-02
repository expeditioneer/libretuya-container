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
    requirements_test.txt

########################################################################################################################
FROM registry.access.redhat.com/ubi9/ubi

RUN dnf install --assumeyes python3-pip \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum

COPY --from=builder /usr/local/libretiny-esphome /usr/local/libretiny-esphome

RUN bin/python3 -m pip install --upgrade pip \
 && bin/python3 -m pip install --requirement /usr/local/libretiny-esphome/requirements.txt

ENV DASHBOARD_USER=""
ENV DASHBOARD_PASSWORD=""

RUN dnf install --assumeyes --setopt=install_weak_deps=False git nginx \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum

COPY files/nginx/conf.d/libretiny.nginx.conf /etc/nginx/conf.d/libretiny.conf
COPY files/nginx/default.d/libretiny.nginx.conf /etc/nginx/default.d/libretiny.conf
COPY files/libretiny_start /usr/local/bin/

RUN groupadd libretiny --gid 1000 \
 && useradd libretiny --uid 1000 --gid libretiny --home-dir /usr/local/libretiny-esphome

RUN mkdir /var/cache/nginx

RUN sed --in-place \
    --expression='/^\s*#/d' \
    --expression='/user nginx;/d' \
    --expression='s /run/nginx.pid /tmp/nginx.pid ' \
    --expression='s/listen\s*80;/listen       8080;/' \
    --expression='s/listen       \[::\]:80;/listen       [::]:8080;/' \
    --expression='/\s*root\s*\/usr\/share\/nginx\/html;/d' \
    --expression="/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=myCache:8m max_size=100m inactive=1h;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;\n" \
    /etc/nginx/nginx.conf

RUN ln --symbolic --force /dev/stdout /var/log/nginx/access.log \
 && ln --symbolic --force /dev/stderr /var/log/nginx/error.log  \
 && chown --recursive libretiny:0 /var/cache/nginx \
 && chmod --recursive g+w /var/cache/nginx \
 && chown --recursive libretiny:0 /etc/nginx \
 && chmod --recursive g+w /etc/nginx

RUN chown --recursive libretiny: \
    /usr/local/libretiny-esphome

RUN mkdir --parents /etc/libretiny \
 && chown --recursive libretiny: /etc/libretiny

USER libretiny

RUN git config --global advice.detachedHead false

EXPOSE 8080

VOLUME ["/etc/libretiny"]

CMD ["libretiny_start"]
