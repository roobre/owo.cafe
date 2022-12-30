ARG MASTODON_VERSION
FROM tootsuite/mastodon:${MASTODON_VERSION} as src

FROM alpine:latest as locale-patcher

RUN apk add --update jq yq && \
    mkdir -p /locales/config /locales/javascript && \
    mkdir /patches && \
    mkdir -p /output/config /output/javascript

# Reminder: Wicked docker COPY syntax will copy files inside folder, instead of folder itself.
COPY locale-patches/ /patches
COPY --from=src /opt/mastodon/config/locales/ /locales/config
COPY --from=src /opt/mastodon/app/javascript/mastodon/locales/ /locales/javascript

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

FROM src

COPY --chown=mastodon:mastodon --from=locale-patcher /output/javascript /opt/mastodon/app/javascript/mastodon/locales/
COPY --chown=mastodon:mastodon --from=locale-patcher /output/config /opt/mastodon/config/locales/
COPY --chown=mastodon:mastodon overlay/ /opt/mastodon/

RUN sed -i 's/IMAGE_LIMIT =.*/IMAGE_LIMIT = 5.megabytes/' /opt/mastodon/app/models/media_attachment.rb && \
    sed -i 's/VIDEO_LIMIT =.*/VIDEO_LIMIT = 30.megabytes/' /opt/mastodon/app/models/media_attachment.rb && \
    sed -i -e 's/500/1024/g' \
      /opt/mastodon/app/javascript/mastodon/features/compose/components/compose_form.js \
      /opt/mastodon/app/validators/status_length_validator.rb && \
    OTP_SECRET=precompile_placeholder SECRET_KEY_BASE=precompile_placeholder rails assets:precompile
