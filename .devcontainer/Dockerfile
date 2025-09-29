ARG USER_NAME="vscode"
ARG COMPILER_VER="20"
ARG NIXOS_VER="25.05"
ARG TARGETPLATFORM

FROM --platform=$TARGETPLATFORM debian:13 AS runtime
ARG USER_NAME
ARG COMPILER_VER
ARG TARGETPLATFORM
ARG TARGETARCH
ARG NIXOS_VER
ENV NIXOS_VER="${NIXOS_VER}"

USER root
RUN useradd -U --shell /bin/bash ${USER_NAME}

ENV DEBIAN_FRONTEND="noninteractive"
ENV LANG="en_US.UTF-8"
ENV DEV_CONTAINER="1"

RUN apt-get update && apt-get full-upgrade -y && \
    apt-get install -y bash zsh \
    git vim build-essential \
    sudo direnv fzf zoxide \
    gnupg wget curl ca-certificates \
    locales locales-all shfmt \
    python3 python3-venv python3-pip \
    patchelf ripgrep podman procps file

COPY ./storage.conf /etc/containers/
COPY ./containers.conf /etc/containers/

RUN echo > /etc/containers/nodocker

RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | \
    gpg --dearmor - | tee /usr/share/keyrings/llvm-keyring.gpg >/dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-keyring.gpg arch=$(dpkg --print-architecture)] http://apt.llvm.org/trixie/ llvm-toolchain-trixie-${COMPILER_VER} main" > \
    /etc/apt/sources.list.d/llvm.list

RUN echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_13/ /' | tee /etc/apt/sources.list.d/shells:fish:release:4.list && \
    curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_13/Release.key | gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null

RUN apt-get update && \
    apt-get install -y \
    fish \
    ninja-build \
    clang-${COMPILER_VER} \
    clang-tools-${COMPILER_VER} \
    clang-format-${COMPILER_VER} \
    clang-tidy-${COMPILER_VER} \
    clangd-${COMPILER_VER} \
    lldb-${COMPILER_VER} \
    lld-${COMPILER_VER}

RUN locale-gen ${LANG} && update-locale LANG=${LANG}
ENV CC=/usr/bin/clang
ENV CXX=/usr/bin/clang++
ENV LD=/usr/bin/lld

RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-${USER_NAME}-sudo && \
    chmod 0400 /etc/sudoers.d/99-${USER_NAME}-sudo

RUN echo "root:1:65535\n${USER_NAME}:1:999\n${USER_NAME}:1001:64535" > /etc/subuid
RUN echo "root:1:65535\n${USER_NAME}:1:999\n${USER_NAME}:1001:64535" > /etc/subgid

ENV PATH="/usr/local/bin:$PATH"

RUN mkdir "/home/${USER_NAME}" && chown ${USER_NAME}:${USER_NAME} -R "/home/${USER_NAME}"

USER ${USER_NAME}
ENV HOME="/home/${USER_NAME}"

RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

RUN curl -L "https://nixos.org/nix/install" | sh -s -- --no-daemon --no-channel-add --yes && \
    mkdir -p "$HOME/.config/nix" && \
    echo "experimental-features = nix-command flakes" >"$HOME/.config/nix/nix.conf" && \
    "$HOME/.nix-profile/bin/nix-channel" --add "https://nixos.org/channels/nixos-${NIXOS_VER:-25.05}" nixpkgs && \
    "$HOME/.nix-profile/bin/nix-channel" --update && \
    "$HOME/.nix-profile/bin/nix" profile add \
    nixpkgs#nixd \
    nixpkgs#nil \
    nixpkgs#nix-direnv \
    nixpkgs#nixfmt-rfc-style
    
RUN echo 'eval "$(direnv hook zsh)"' >> "$HOME/.zshrc"
RUN echo 'eval "$(direnv hook bash)"' >> "$HOME/.bashrc"
RUN mkdir -p "$HOME/.config/fish" || true && echo 'direnv hook fish | source' >> "$HOME/.config/fish/config.fish"
