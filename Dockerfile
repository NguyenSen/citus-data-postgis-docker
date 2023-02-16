# This file is auto generated from it's template,
# see citusdata/tools/packaging_automation/templates/docker/latest/latest.tmpl.dockerfile.
FROM postgres:15.2
ARG VERSION=11.2.0
LABEL maintainer="Citus Data https://citusdata.com" \
      org.label-schema.name="Citus" \
      org.label-schema.description="Scalable PostgreSQL for multi-tenant and real-time workloads" \
      org.label-schema.url="https://www.citusdata.com" \
      org.label-schema.vcs-url="https://github.com/citusdata/citus" \
      org.label-schema.vendor="Citus Data, Inc." \
      org.label-schema.version=${VERSION} \
      org.label-schema.schema-version="1.0"

ENV CITUS_VERSION ${VERSION}.citus-1

# install Citus
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
    && curl -s https://install.citusdata.com/community/deb.sh | bash \
    && apt-get install -y postgresql-$PG_MAJOR-citus-11.2=$CITUS_VERSION \
                          postgresql-$PG_MAJOR-hll=2.17.citus-1 \
                          postgresql-$PG_MAJOR-topn=2.5.0.citus-1 \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

# add citus to default PostgreSQL config
RUN echo "shared_preload_libraries='citus'" >> /usr/share/postgresql/postgresql.conf.sample

# install PostGis
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      libboost-atomic1.74.0 \
      libboost-chrono1.74.0 \
      libboost-date-time1.74.0 \
      libboost-filesystem1.74.0 \
      libboost-program-options1.74.0 \
      libboost-serialization1.74.0 \
      libboost-system1.74.0 \
      libboost-test1.74.0 \
      libboost-thread1.74.0 \
      libboost-timer1.74.0 \
      libcurl3-gnutls \
      libexpat1 \
      libgmp10 \
      libgmpxx4ldbl \
      libjson-c5 \
      libmpfr6 \
      libprotobuf-c1 \
      libtiff5 \
      libxml2 \
      sqlite3 \
      # build dependency
      autoconf \
      automake \
      autotools-dev \
      bison \
      build-essential \
      ca-certificates \
      cmake \
      g++ \
      git \
      libboost-all-dev \
      libcgal-dev \
      libcurl4-gnutls-dev \
      libgmp-dev \
      libjson-c-dev \
      libmpfr-dev \
      libpcre3-dev \
      libpq-dev \
      libprotobuf-c-dev \
      libsqlite3-dev \
      libtiff-dev \
      libtool \
      libxml2-dev \
      make \
      pkg-config \
      protobuf-c-compiler \
      xsltproc

# sfcgal
ENV SFCGAL_VERSION master
#current:
#ENV SFCGAL_GIT_HASH df3c2ccc015d4a85ac672fc307d2c7c324cccca7
#reverted for the last working version
ENV SFCGAL_GIT_HASH e1f5cd801f8796ddb442c06c11ce8c30a7eed2c5

RUN set -ex \
    && mkdir -p /usr/src \
    && cd /usr/src \
    && git clone https://gitlab.com/Oslandia/SFCGAL.git \
    && cd SFCGAL \
    && git checkout ${SFCGAL_GIT_HASH} \
    && mkdir cmake-build \
    && cd cmake-build \
    && cmake .. \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -fr /usr/src/SFCGAL

# proj
ENV PROJ_VERSION master
ENV PROJ_GIT_HASH 23ffb4ba179a9b3bf1debd2749e92f1862b51536

RUN set -ex \
    && cd /usr/src \
    && git clone https://github.com/OSGeo/PROJ.git \
    && cd PROJ \
    && git checkout ${PROJ_GIT_HASH} \
    # check the autotools exist? https://github.com/OSGeo/PROJ/pull/3027
    && if [ -f "autogen.sh" ] ; then \
        set -eux \
        && echo "autotools version: 'autogen.sh' exists! Older version!"  \
        && ./autogen.sh \
        && ./configure --disable-static \
        && make -j$(nproc) \
        && make install \
        ; \
    else \
        set -eux \
        && echo "cmake version: 'autogen.sh' does not exists! Newer version!" \
        && mkdir build \
        && cd build \
        && cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
        && make -j$(nproc) \
        && make install \
        ; \
    fi \
    \
    && cd / \
    && rm -fr /usr/src/PROJ

# geos
ENV GEOS_VERSION master
ENV GEOS_GIT_HASH dd31eb17c6b5283bfee0c3c513192cd257b015cc

RUN set -ex \
    && cd /usr/src \
    && git clone https://github.com/libgeos/geos.git \
    && cd geos \
    && git checkout ${GEOS_GIT_HASH} \
    && mkdir cmake-build \
    && cd cmake-build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -fr /usr/src/geos

# gdal
ENV GDAL_VERSION master
ENV GDAL_GIT_HASH 12c1c58435d025a97ecec0dffd39bb793b332b11

RUN set -ex \
    && cd /usr/src \
    && git clone https://github.com/OSGeo/gdal.git \
    && cd gdal \
    && git checkout ${GDAL_GIT_HASH} \
    \
    # gdal project directory structure - has been changed !
    && if [ -d "gdal" ] ; then \
        echo "Directory 'gdal' dir exists -> older version!" ; \
        cd gdal ; \
    else \
        echo "Directory 'gdal' does not exists! Newer version! " ; \
    fi \
    \
    && if [ -f "./autogen.sh" ]; then \
        # Building with autoconf ( old/deprecated )
        set -eux \
        && ./autogen.sh \
        && ./configure --disable-static \
        ; \
    else \
        # Building with cmake
        set -eux \
        && mkdir build \
        && cd build \
        && cmake -DCMAKE_BUILD_TYPE=Release .. \
        ; \
    fi \
    \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -fr /usr/src/gdal

# Minimal command line test.
RUN set -ex \
    && ldconfig \
    && cs2cs \
    && gdalinfo --version \
    && geos-config --version \
    && ogr2ogr --version \
    && proj \
    && sfcgal-config --version \
    && pcre-config  --version

FROM postgres:15-bullseye

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      libboost-atomic1.74.0 \
      libboost-chrono1.74.0 \
      libboost-date-time1.74.0 \
      libboost-filesystem1.74.0 \
      libboost-program-options1.74.0 \
      libboost-serialization1.74.0 \
      libboost-system1.74.0 \
      libboost-test1.74.0 \
      libboost-thread1.74.0 \
      libboost-timer1.74.0 \
      libcurl3-gnutls \
      libexpat1 \
      libgmp10 \
      libgmpxx4ldbl \
      libjson-c5 \
      libmpfr6 \
      libpcre3 \
      libprotobuf-c1 \
      libtiff5 \
      libxml2 \
      sqlite3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local

#ENV SFCGAL_GIT_HASH df3c2ccc015d4a85ac672fc307d2c7c324cccca7
ENV PROJ_GIT_HASH 23ffb4ba179a9b3bf1debd2749e92f1862b51536
ENV GEOS_GIT_HASH dd31eb17c6b5283bfee0c3c513192cd257b015cc
ENV GDAL_GIT_HASH 12c1c58435d025a97ecec0dffd39bb793b332b11

# Minimal command line test.
RUN set -ex \
    && ldconfig \
    && cs2cs \
    && gdalinfo --version \
    && geos-config --version \
    && ogr2ogr --version \
    && proj \
    && sfcgal-config --version

# Testing ogr2ogr PostgreSQL driver.
RUN ogr2ogr --formats | grep -q "PostgreSQL/PostGIS" && exit 0 \
    || echo "ogr2ogr missing PostgreSQL driver" && exit 1

# install postgis
ENV POSTGIS_VERSION master
ENV POSTGIS_GIT_HASH ee06f41209c87366494b454f33179f56788cabc5

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      autoconf \
      automake \
      autotools-dev \
      bison \
      build-essential \
      ca-certificates \
      cmake \
      g++ \
      git \
      libboost-all-dev \
      libcgal-dev \
      libcurl4-gnutls-dev \
      libgmp-dev \
      libjson-c-dev \
      libmpfr-dev \
      libpcre3-dev \
      libprotobuf-c-dev \
      libsqlite3-dev \
      libtiff-dev \
      libtool \
      libxml2-dev \
      make \
      pkg-config \
      postgresql-server-dev-$PG_MAJOR \
      protobuf-c-compiler \
      xsltproc \
    && cd \
    # postgis
    && cd /usr/src/ \
    && git clone https://github.com/postgis/postgis.git \
    && cd postgis \
    && git checkout ${POSTGIS_GIT_HASH} \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure \
#       --with-gui \
        --with-pcredir="$(pcre-config --prefix)" \
    && make -j$(nproc) \
    && make install \
# regress check
    && mkdir /tempdb \
    && chown -R postgres:postgres /tempdb \
    && su postgres -c 'pg_ctl -D /tempdb init' \
    && su postgres -c 'pg_ctl -D /tempdb start' \
    && ldconfig \
    && cd regress \
    && make -j$(nproc) check RUNTESTFLAGS=--extension PGUSER=postgres \
    \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis;"' \
    && su postgres -c 'psql -t -c "SELECT version();"' >> /_pgis_full_version.txt \
    && su postgres -c 'psql -t -c "SELECT PostGIS_Full_Version();"' >> /_pgis_full_version.txt \
    \
    && su postgres -c 'pg_ctl -D /tempdb --mode=immediate stop' \
    && rm -rf /tempdb \
    && rm -rf /tmp/pgis_reg \
# clean
    && cd / \
    && rm -rf /usr/src/postgis \
    && apt-get purge -y --autoremove \
      autoconf \
      automake \
      autotools-dev \
      bison \
      build-essential \
      cmake \
      g++ \
      git \
      libboost-all-dev \
      libcgal-dev \
      libcurl4-gnutls-dev \
      libgmp-dev \
      libjson-c-dev \
      libmpfr-dev \
      libpcre3-dev \
      libprotobuf-c-dev \
      libsqlite3-dev \
      libtiff-dev \
      libtool \
      libxml2-dev \
      make \
      pkg-config \
      postgresql-server-dev-$PG_MAJOR \
      protobuf-c-compiler \
      xsltproc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# add citus to default PostgreSQL config
RUN echo "shared_preload_libraries='postgis'" >> /usr/share/postgresql/postgresql.conf.sample

# add scripts to run after initdb
COPY 001-create-citus-extension.sql /docker-entrypoint-initdb.d/

# add scripts to run after initdb

COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
COPY ./update-postgis.sh /usr/local/bin

RUN set -ex \
    # Is the "ca-certificates" package installed? (for accessing remote raster files)
    #   https://github.com/postgis/docker-postgis/issues/307
    && dpkg-query -W -f='${Status}' ca-certificates 2>/dev/null | grep -c "ok installed" \
    \
    # list postgresql, postgis version
    && cat /_pgis_full_version.txt
    
 
# add health check script
COPY pg_healthcheck wait-for-manager.sh /
RUN chmod +x /wait-for-manager.sh

# entry point unsets PGPASSWORD, but we need it to connect to workers
# https://github.com/docker-library/postgres/blob/33bccfcaddd0679f55ee1028c012d26cd196537d/12/docker-entrypoint.sh#L303
RUN sed "/unset PGPASSWORD/d" -i /usr/local/bin/docker-entrypoint.sh

HEALTHCHECK --interval=4s --start-period=6s CMD ./pg_healthcheck
