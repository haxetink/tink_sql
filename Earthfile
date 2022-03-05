VERSION 0.6
FROM mcr.microsoft.com/vscode/devcontainers/base:0-bullseye
ARG WORKDIR=/workspace
RUN mkdir -m 777 "/workspace"
WORKDIR $WORKDIR

ARG TARGETARCH

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV HAXESHIM_ROOT=/haxe

devcontainer-library-scripts:
    RUN curl -fsSLO https://raw.githubusercontent.com/microsoft/vscode-dev-containers/main/script-library/common-debian.sh
    RUN curl -fsSLO https://raw.githubusercontent.com/microsoft/vscode-dev-containers/main/script-library/docker-debian.sh
    SAVE ARTIFACT --keep-ts *.sh AS LOCAL .devcontainer/library-scripts/

github-src:
    ARG --required REPO
    ARG --required COMMIT
    ARG DIR=/src
    WORKDIR $DIR
    RUN curl -fsSL "https://github.com/${REPO}/archive/${COMMIT}.tar.gz" | tar xz --strip-components=1 -C "$DIR"
    SAVE ARTIFACT "$DIR"

# Usage:
# COPY +earthly/earthly /usr/local/bin/
# RUN earthly bootstrap --no-buildkit --with-autocomplete
earthly:
    FROM +devcontainer-base
    RUN curl -fsSL https://github.com/earthly/earthly/releases/download/v0.6.8/earthly-linux-${TARGETARCH} -o /usr/local/bin/earthly \
        && chmod +x /usr/local/bin/earthly
    SAVE ARTIFACT /usr/local/bin/earthly

devcontainer-base:
    # Avoid warnings by switching to noninteractive
    ENV DEBIAN_FRONTEND=noninteractive

    ARG INSTALL_ZSH="false"
    ARG UPGRADE_PACKAGES="true"
    ARG ENABLE_NONROOT_DOCKER="true"
    ARG USE_MOBY="false"
    COPY .devcontainer/library-scripts/common-debian.sh .devcontainer/library-scripts/docker-debian.sh /tmp/library-scripts/
    RUN apt-get update \
        && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
        && /bin/bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}" "${USE_MOBY}" \
        # Clean up
        && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

    # Configure apt and install packages
    RUN apt-get update \
        && apt-get install -y --no-install-recommends apt-utils dialog 2>&1 \
        && apt-get install -y \
            iproute2 \
            procps \
            sudo \
            bash-completion \
            build-essential \
            curl \
            wget \
            software-properties-common \
            direnv \
            tzdata \
            # install docker engine for running `WITH DOCKER`
            docker-ce \
            # for testing php target
            php-cli \
            php-mbstring \
            php-mysql \
            php-sqlite3 \
        && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
        && apt-get install -y nodejs=16.* \
        #
        # Clean up
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*

    # Switch back to dialog for any ad-hoc use of apt-get
    ENV DEBIAN_FRONTEND=

    # Setting the ENTRYPOINT to docker-init.sh will configure non-root access 
    # to the Docker socket. The script will also execute CMD as needed.
    ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
    CMD [ "sleep", "infinity" ]

haxeshim-root:
    FROM +devcontainer-base
    COPY haxe_libraries haxe_libraries
    COPY .haxerc .
    RUN mkdir src
    RUN npx lix download
    SAVE ARTIFACT "$HAXESHIM_ROOT"

devcontainer:
    FROM +devcontainer-base

    COPY +earthly/earthly /usr/local/bin/
    RUN earthly bootstrap --no-buildkit --with-autocomplete

    RUN npm config --global set update-notifier false
    RUN npm config set prefix /usr/local
    RUN npm install -g lix

    USER $USERNAME

    # Config direnv
    COPY --chown=$USER_UID:$USER_GID .devcontainer/direnv.toml "/home/$USERNAME/.config/direnv/config.toml"
    RUN echo 'eval "$(direnv hook bash)"' >> ~/.bashrc

    # Install deps
    COPY +haxeshim-root/* "$HAXESHIM_ROOT"
    COPY .haxerc package.json package-lock.json .
    RUN npm i
    VOLUME /workspace/node_modules

    USER root

    ARG IMAGE_TAG=master
    SAVE IMAGE ghcr.io/haxetink/tink_sql_devcontainer:$IMAGE_TAG

test-base:
    FROM +devcontainer
    COPY haxe_libraries haxe_libraries
    COPY src src
    COPY tests tests
    COPY haxelib.json tests.hxml .

test-node:
    FROM +test-base
    ARG TEST_DB_TYPES=MySql,PostgreSql,Sqlite
    ENV TEST_DB_TYPES="$TEST_DB_TYPES"
    WITH DOCKER --compose tests/docker-compose.yml
        RUN npm run test node
    END

test-php:
    FROM +test-base
    ARG TEST_DB_TYPES=MySql,PostgreSql,Sqlite
    ENV TEST_DB_TYPES="$TEST_DB_TYPES"
    WITH DOCKER --compose tests/docker-compose.yml
        RUN npm run test php
    END
