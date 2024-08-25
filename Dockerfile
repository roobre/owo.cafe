ARG MASTODON_VERSION="v4.3.0-beta.1"
FROM ghcr.io/mastodon/mastodon:${MASTODON_VERSION} as mastodon

# TODO: locale-patcher could be merged with patcher, but debian does not have yq on their repos yet.
FROM alpine:latest as locale-patcher

RUN apk add --update jq yq && \
  mkdir -p /locales/config /locales/javascript && \
  mkdir /patches && \
  mkdir -p /output/config /output/javascript

# Reminder: Wicked docker COPY syntax will copy files inside folder, instead of folder itself.
COPY locale-patches/ /patches
COPY --from=mastodon /opt/mastodon/config/locales/ /locales/config
COPY --from=mastodon /opt/mastodon/app/javascript/mastodon/locales/ /locales/javascript

RUN cd /locales/javascript; \
  for lang in es en; do \
  for j in $lang*.json; do \
  echo Patching $j; \
  jq -s '.[0] * .[1]' /locales/javascript/$j /patches/javascript/$lang.json > /output/javascript/$j; \
  done; \
  done

RUN cd /locales/config; \
  for lang in es en; do \
  for y in $lang*; do \
  echo Patching $y; \
  yq '. *= load("/patches/config/'$lang'.yaml")' /locales/config/$y > /output/config/$y; \
  done; \
  done

FROM alpine:latest as patcher

COPY --from=mastodon /opt/mastodon /opt/mastodon

RUN apk add patch

COPY patches /patches
RUN find /patches -type f -name '*.patch' | while read p; do \
  echo "Applying $p" && \
  patch -p1 -d /opt/mastodon < $p || exit 1; \
  done

FROM mastodon

# Copy all files, patched or not, from the patcher image.
# This copy is lightweight as identical files are reused. It does take a few kilobytes for modification times.
COPY --from=patcher /opt/mastodon /opt/mastodon
# Copy patched locales.
COPY --chown=root:root --from=locale-patcher /output/javascript /opt/mastodon/app/javascript/mastodon/locales/
COPY --chown=root:root --from=locale-patcher /output/config /opt/mastodon/config/locales/
# Finally, copy overrides.
COPY --chown=root:root overlay/ /opt/mastodon/

