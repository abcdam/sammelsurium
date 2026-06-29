
ARG _APTGET_='apt-get update && apt-get install -y'
ARG _RM_APTMETA_='rm -rf /var/lib/apt/lists/*'

ARG ARTIFACT_DIR=/artifact
ARG TARGET_DIR=/usr/5bin
ARG MANIFEST_ID=manifest-posix2001.txt

###
## START manifest-builder
# fetch the full label list of all utilities defined in IEEE Std 1003.1-2001
FROM debian:stable-slim AS manifest-builder
ARG _APTGET_
ARG _RM_APTMETA_
RUN eval $_APTGET_ curl && $_RM_APTMETA_

ARG ARTIFACT_DIR
ARG MANIFEST_ID

ARG MANIFEST_URL=https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html

WORKDIR $ARTIFACT_DIR
RUN curl -s "$MANIFEST_URL" |       \
  tr '<' '\n' |                     \
  grep '^a href=.*target="main"' |  \
  cut -d'>' -f2 > $MANIFEST_ID      \
  && [ "$(wc -l < $MANIFEST_ID)" -eq 160 ]
## END manifest-builder
###

###
## START BUILDER
# compiles heirloom-ng utility suite and extracts posix 2001 compliant binaries
FROM debian:stable-slim AS builder
ARG _APTGET_
ARG _RM_APTMETA_
RUN eval $_APTGET_          \
  bison build-essential     \
  ed                        \
  flex                      \
  git                       \
  libbz2-dev libncurses-dev \
  zlib1g-dev                \
  && $_RM_APTMETA_

ARG ARTIFACT_DIR
ARG TARGET_DIR
ARG MANIFEST_ID

ARG REPO_URL=https://github.com/Projeto-Pindorama/heirloom-ng.git
ARG SRC_DIR=/src
ARG BUILD_DIR=/build


# fix makefile error that expects these binaries to exist for symlinking
# we don't need them so we just place mocks inside it
WORKDIR $BUILD_DIR/usr/ccs/bin
RUN touch sccs prt && mkdir -p $ARTIFACT_DIR

WORKDIR $SRC_DIR
RUN git clone --depth=1 $REPO_URL . \
  && make                           \
  && make install ROOT=$BUILD_DIR

COPY --from=manifest-builder $ARTIFACT_DIR/$MANIFEST_ID $SRC_DIR/

WORKDIR $BUILD_DIR/$TARGET_DIR
RUN cat $SRC_DIR/$MANIFEST_ID | \
  while read -r utility; do \
  [ -n "${utility}" ] \
  && [ -e "${utility}" ] \
  && mv "${utility}" $ARTIFACT_DIR/ \
  || continue;                      \
  done
RUN [ -d posix2001 ] && mv posix2001/* $ARTIFACT_DIR/
## END BUILDER
###

###
## START RUNNER
# creates a locked-down user that can only access the extracted utils
FROM debian:stable-slim AS runner
ARG _APTGET_
ARG _RM_APTMETA_
ARG DASH_BIN=/bin/dash
RUN if [ ! -x $DASH_BIN ]; then \
  eval $_APTGET_ dash     \
  && $_RM_APTMETA_;       \
  fi

ARG TARGET_DIR
ARG ARTIFACT_DIR

ARG USER=posix
ARG SCRIPT_ID=entrypoint.sh

COPY --from=builder $ARTIFACT_DIR $TARGET_DIR
RUN ln -s $DASH_BIN $TARGET_DIR/sh

COPY --chmod=755 $SCRIPT_ID .

ENV ENV=/etc/shinit
RUN echo '[ "$(id -u)" != 0 ] && PATH="'$TARGET_DIR'"' > /etc/shinit

RUN useradd -m -s $DASH_BIN $USER
USER $USER
WORKDIR /home/$USER

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/dash"]
## END RUNNER
###
