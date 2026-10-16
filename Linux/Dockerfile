# syntax=docker/dockerfile:1
#
#  Linux/Dockerfile -- the Phase B toolchain spike (MAD_LINUX.md §9).
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
CMD ["bash", "Linux/build.sh", "--in-image", "test"]
