FROM debian:latest

MAINTAINER Petr Velan <petr.velan@cesnet.cz>

# IPFIXcol dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  autoconf \
  bison \
  build-essential \
  docbook-xsl \
  doxygen \
  flex \
  git \
  liblzo2-dev \
  libtool \
  libsctp-dev \
  libxml2 \
  libxml2-dev \
  pkg-config \
  xsltproc \
  librdkafka-dev \
  librdkafka1 \
  librrd-dev \
  ca-certificates \
  automake

# checkout IPFIXcol
WORKDIR /root/
#RUN git clone --recursive https://github.com/CESNET/ipfixcol.git
ADD . /root/ipfixcol
WORKDIR /root/ipfixcol/

# select devel branch for installation
#RUN git checkout devel;
RUN git submodule update --init --recursive

ENV CFLAGS="-march=native -mtune=native -O3 -pipe"
ENV CPPFLAGS="-march=native -mtune=native -O3 -pipe"

# install IPFIXcol base
RUN cd base; \
  autoreconf -i; \
  ./configure --with-distro=debian --without-openssl; \
  make clean; \
  make install; \
  ldconfig

# install IPFIXcol plugins
RUN for p in storage/json; do \
    cd plugins/$p; \
    autoreconf -i; \
    ./configure --with-distro=debian --enable-kafka; \
	make clean; \
    make install; \
	cd -; \
  done
RUN for p in intermediate/stats intermediate/profile_stats; do \
    cd plugins/$p; \
    autoreconf -i; \
    ./configure --with-distro=debian --enable-kafka; \
	make clean; \
    make install; \
	cd -; \
  done


EXPOSE 4739 4739/udp
VOLUME /etc/ipfixcol/

ENTRYPOINT ["/usr/local/bin/ipfixcol"]
