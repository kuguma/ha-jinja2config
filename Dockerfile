ARG BUILD_FROM
FROM $BUILD_FROM

COPY rootfs /

COPY requirements.txt /tmp/

# Force rebuild: Updated to jinjanator for Python 3.12+ support (v2.0.1)
RUN \
  pip3 install -r /tmp/requirements.txt && \
  apk add --no-cache inotify-tools nodejs npm && \
  npm install -g prettier
