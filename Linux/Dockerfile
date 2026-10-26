# syntax=docker/dockerfile:1
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  Linux/Dockerfile -- the Phase B toolchain spike (docs/project/MAD_LINUX.md §9).
#
#  Three stages:
#    toolchain-base  Ubuntu 24.04 plus the distro clang and GNUstep's
#                    dependencies; sets the compiler environment
#    toolchain       libobjc2, libdispatch, gnustep-make and gnustep-base,
#                    built from the pins in Linux/toolchain.conf, then the C
#                    libraries the frameworks link, built from the pins in
#                    Linux/libraries.conf
#    build           the repo copied in and the frameworks compiled;
#                    `docker run <image>` runs the Linux tests
#
#  Build through Linux/build.sh, not by hand -- it resolves the docker CLI and
#  tags the images.  The context is the repo root:
#
#    docker build -f Linux/Dockerfile --target toolchain -t mad-linux-toolchain:1 .
#    docker build -f Linux/Dockerfile -t mad-linux:phase-b .
#
#  Only Linux/ and the framework sources are in the context (.dockerignore).

FROM ubuntu:24.04 AS toolchain-base

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		clang lld cmake make git pkg-config curl ca-certificates \
		libbsd-dev \
		libffi-dev libxml2-dev libxslt1-dev libgnutls28-dev zlib1g-dev \
		libavahi-client-dev libicu-dev tzdata libcurl4-openssl-dev \
		libncurses-dev libtirpc-dev \
	&& rm -rf /var/lib/apt/lists/*

# The toolchain lives in /usr/local, like GNUstep's Linux guide says.
ENV CC=clang \
	CXX=clang++ \
	LD=ld.lld \
	LDFLAGS=-fuse-ld=lld \
	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
	LD_LIBRARY_PATH=/usr/local/lib \
	MAD_LOG_TAG=build

FROM toolchain-base AS toolchain

COPY Linux/toolchain.conf /opt/madlinux/toolchain.conf
COPY Linux/libraries.conf /opt/madlinux/libraries.conf
COPY Linux/lib/ /opt/madlinux/lib/
# The SQLite option list stays in its one place: the recipe and this build
# both read Compressor/sqlite3.xcconfig.
COPY Compressor/sqlite3.xcconfig /opt/madlinux/sqlite3.xcconfig

# Fetch and build are separate layers on purpose: the fetch layer survives a
# build failure, so fixing a GNUstep step never re-downloads.  Both layers are
# invalidated only by the conf files or lib/, never by repo source edits.
RUN bash /opt/madlinux/lib/toolchain.sh --fetch
RUN bash /opt/madlinux/lib/toolchain.sh --build
RUN bash /opt/madlinux/lib/libraries.sh --fetch
RUN bash /opt/madlinux/lib/libraries.sh --build

FROM toolchain AS build

WORKDIR /src
COPY . /src
RUN bash Linux/build.sh --in-image build
# The CMake install rule puts the binary at a stable path (/usr/local/bin/mad),
# so the runtime stage does not reach into the build tree.
RUN cmake --install /src/Linux/build
CMD ["bash", "Linux/build.sh", "--in-image", "test"]

# ---------------------------------------------------------------------------
# runtime -- the CLI deliverable: `mad` on PATH, the shared libraries it links,
# GNUstep's runtime directories, and the Sqlite3 sample database.  The compiler,
# the sources and the 124 test binaries stay in the stages above.
#
# Built locally as mad-cli:latest (`Linux/build.sh --runtime` / `--verify`) and
# published by CI as ghcr.io/mthomason/mad
# (`.github/workflows/publish-image.yml`).  The GPLv2 blocker left with the
# mysqlclient swap: mariadb (Connector/C) is LGPL and is linked statically, so
# it needs no runtime files here and its relink offer
# (`ThirdParty/Licenses/README.md`) covers distribution.
# ---------------------------------------------------------------------------
FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
	LANG=C.UTF-8 \
	LD_LIBRARY_PATH=/usr/local/lib

# The runtime half of toolchain-base's package list: what GNUstep Base links,
# without clang, cmake, git or the -dev packages.  The C libraries the
# frameworks link (sqlite3, freetds, openssl, zlib, bzip2, libarchive,
# mariadb) are static and are already inside the binary.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates libavahi-client3 libcurl4 libffi8 libgmp10 \
		libgnutls30 libicu74 libsasl2-2 libssl3 libstdc++6 libxml2 \
		libxslt1.1 tzdata zlib1g \
	&& rm -rf /var/lib/apt/lists/*

# The toolchain stage installs everything into /usr/local.  Only the shared
# objects move; the static archives and headers stay behind.
COPY --from=toolchain /usr/local/lib/libgnustep-base.so.1.31.1 /usr/local/lib/
COPY --from=toolchain /usr/local/lib/libobjc.so.4.6 /usr/local/lib/
COPY --from=toolchain /usr/local/lib/libdispatch.so /usr/local/lib/
COPY --from=toolchain /usr/local/lib/libBlocksRuntime.so /usr/local/lib/
COPY --from=toolchain /usr/local/lib/GNUstep /usr/local/lib/GNUstep
COPY --from=toolchain /usr/local/etc/GNUstep /usr/local/etc/GNUstep
COPY --from=toolchain /usr/local/share/GNUstep /usr/local/share/GNUstep

COPY --from=build /usr/local/bin/mad /usr/local/bin/mad

# A Sqlite3 document stores a bare database name, and the engine resolves it
# against the per-user Application Support directory -- $HOME/GNUstep/Library/
# ApplicationSupport off Apple.  Baking chinook.sqlite3 in makes the checked-in
# London and Music documents refresh without extra setup.
COPY --from=build \
	/src/MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset/chinook.sqlite3 \
	/root/GNUstep/Library/ApplicationSupport/chinook.sqlite3

# The sonames the binary names (DT_NEEDED) as links to the versioned files --
# COPY would dereference them -- then ldconfig, so the objects resolve without
# the ENV above.  `mad help` is the build-time link check: a missing shared
# object fails this RUN.
RUN ln -s libgnustep-base.so.1.31.1 /usr/local/lib/libgnustep-base.so.1.31 \
	&& ldconfig \
	&& mad help >/dev/null

WORKDIR /work

# No ENTRYPOINT, so the command reads the way docs/project/MAD_CLI.md writes it:
#   docker run --rm -v "$PWD/docs":/docs mad-cli:latest mad inspect /docs/x.mad
CMD ["mad"]
