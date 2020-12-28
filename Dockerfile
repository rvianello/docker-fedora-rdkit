ARG fedora_release=33
FROM docker.io/fedora:${fedora_release} AS rdkit-builder
ARG rdkit_git_url=https://github.com/rdkit/rdkit.git
ARG rdkit_git_ref=Release_2020_09_3

RUN dnf install -y \
    boost-devel \
    boost-python3-devel \
    cairo-devel \
    catch-devel \
    cmake \
    eigen3-devel \
    g++ \
    git \
    make \
    python3-devel \
    python3-numpy \
    python3-pandas \
    python3-pillow \
    sqlite-devel \
    zlib-devel \
  && dnf clean all


WORKDIR /opt/build

RUN git clone ${rdkit_git_url}

WORKDIR /opt/build/rdkit

RUN git checkout ${rdkit_git_ref}

RUN cmake \
    -D CATCH_DIR=/usr/include/catch2 \
    -D RDK_BUILD_COMPRESSED_SUPPLIERS=ON \
    -D RDK_BUILD_CAIRO_SUPPORT=ON \
    -D RDK_BUILD_INCHI_SUPPORT=ON \
    -D RDK_BUILD_AVALON_SUPPORT=ON \
    -D RDK_BUILD_DESCRIPTORS3D=ON \
    -D RDK_BUILD_FREESASA_SUPPORT=ON \
    -D RDK_BUILD_COORDGEN_SUPPORT=ON \
    -D RDK_BUILD_MOLINTERCHANGE_SUPPORT=ON \
    -D RDK_BUILD_YAEHMOP_SUPPORT=ON \
    -D RDK_BUILD_STRUCTCHECKER_SUPPORT=ON \
    -D RDK_USE_URF=ON \
    -D RDK_BUILD_PGSQL=OFF \
    -D RDK_INSTALL_INTREE=OFF \
    -D RDK_INSTALL_STATIC_LIBS=ON \
    -D RDK_INSTALL_DEV_COMPONENT=ON \
    -D LIB_SUFFIX=64 \
    -D CMAKE_INSTALL_PREFIX=/usr \
    . 
  
RUN make -j4
RUN RDBASE="$PWD" LD_LIBRARY_PATH="$PWD/lib" PYTHONPATH="$PWD" ctest -j4 --output-on-failure
RUN make install DESTDIR=/opt/stage

ARG fedora_release=33
FROM docker.io/fedora:${fedora_release} AS chemicalite-builder
ARG chemicalite_git_url=https://github.com/rvianello/chemicalite.git
ARG chemicalite_git_ref=2020.12.5

RUN dnf install -y \
    boost-devel \
    catch-devel \
    cmake \
    eigen3-devel \
    g++ \
    git \
    make \
    python3 \
    sqlite-devel \
  && dnf clean all

COPY --from=rdkit-builder /opt/stage/usr /usr

WORKDIR /opt/build

RUN git clone ${chemicalite_git_url}

WORKDIR /opt/build/chemicalite

RUN git checkout ${chemicalite_git_ref}

RUN cmake \
    -D CMAKE_INSTALL_PREFIX=/usr \
    . 

RUN make
RUN LD_LIBRARY_PATH="$PWD/src" ctest --output-on-failure
RUN make install DESTDIR=/opt/stage

ARG fedora_release=33
FROM docker.io/fedora:${fedora_release}

RUN dnf install -y \
    boost-iostreams \
    boost-python3 \
    boost-regex \
    boost-serialization \
    boost-system \
    cairo \
    python3 \
    python3-numpy \
    python3-ipython \
    sqlite \
    zlib \
  && dnf clean all

COPY --from=rdkit-builder /opt/stage/usr /usr
COPY --from=chemicalite-builder /opt/stage/usr /usr

