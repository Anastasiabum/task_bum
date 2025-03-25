# Используем официальный базовый образ Ubuntu 22.04
FROM ubuntu:22.04

# Определяем переменные окружения
ENV DEBIAN_FRONTEND=noninteractive \
    SOFT=/soft \
    PATH=/usr/bin:$PATH

# Создаем директорию для установки специализированных программ
RUN mkdir -p $SOFT && chmod 777 $SOFT

# Установка зависимостей
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    tar \
    xz-utils \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libffi-dev \
    libncursesw5-dev \
    cmake \
    pkg-config \
    python3.10 \
    python3.10-venv \
    python3-pip \
    autoconf \
    automake \
    libtool \
    && rm -rf /var/lib/apt/lists/*

# Установка Python-библиотек
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir argparse pandas pysam

# Переменные для установки Samtools
ENV SAMTOOLS_VERSION=1.19 \
    SAMTOOLS_DIR=$SOFT/samtools-br240304

# Установка Samtools и его зависимостей
RUN cd $SOFT && \
    wget -q https://github.com/samtools/samtools/releases/download/$SAMTOOLS_VERSION/samtools-$SAMTOOLS_VERSION.tar.bz2 && \
    wget -q https://github.com/samtools/htslib/releases/download/$SAMTOOLS_VERSION/htslib-$SAMTOOLS_VERSION.tar.bz2 && \
    wget -q https://github.com/ebiggers/libdeflate/archive/refs/tags/v1.19.tar.gz -O libdeflate-1.19.tar.gz && \
    tar -xjf samtools-$SAMTOOLS_VERSION.tar.bz2 && \
    tar -xjf htslib-$SAMTOOLS_VERSION.tar.bz2 && \
    tar -xzf libdeflate-1.19.tar.gz && \
    cd libdeflate-1.19 && mkdir build && cd build && cmake .. && make -j$(nproc) && make install PREFIX=$SAMTOOLS_DIR && \
    cd ../../htslib-$SAMTOOLS_VERSION && ./configure --prefix=$SAMTOOLS_DIR && make -j$(nproc) && make install && \
    cd ../samtools-$SAMTOOLS_VERSION && ./configure --prefix=$SAMTOOLS_DIR --with-htslib=$SAMTOOLS_DIR && make -j$(nproc) && make install && \
    rm -rf $SOFT/samtools-$SAMTOOLS_VERSION* $SOFT/htslib-$SAMTOOLS_VERSION* $SOFT/libdeflate-1.19*

# Переменные для установки BCFtools
ENV BCFTOOLS_VERSION=1.19 \
    BCFTOOLS_DIR=$SOFT/bcftools-br240304

# Установка BCFtools
RUN cd $SOFT && \
    wget -q https://github.com/samtools/bcftools/releases/download/$BCFTOOLS_VERSION/bcftools-$BCFTOOLS_VERSION.tar.bz2 && \
    tar -xjf bcftools-$BCFTOOLS_VERSION.tar.bz2 && \
    cd bcftools-$BCFTOOLS_VERSION && ./configure --prefix=$BCFTOOLS_DIR && make -j$(nproc) && make install && \
    rm -rf $SOFT/bcftools-$BCFTOOLS_VERSION*

# Переменные для установки VCFtools
ENV VCFTOOLS_VERSION=0.1.16 \
    VCFTOOLS_DIR=$SOFT/vcftools-br200610

# Установка VCFtools
RUN cd $SOFT && \
    wget -q https://github.com/vcftools/vcftools/archive/refs/tags/v$VCFTOOLS_VERSION.tar.gz -O vcftools-$VCFTOOLS_VERSION.tar.gz && \
    tar -xzf vcftools-$VCFTOOLS_VERSION.tar.gz && \
    cd vcftools-$VCFTOOLS_VERSION && ./autogen.sh && ./configure --prefix=$VCFTOOLS_DIR && make -j$(nproc) && make install && \
    rm -rf $SOFT/vcftools-$VCFTOOLS_VERSION*

# Исправленный LD_LIBRARY_PATH
ENV PATH=$SAMTOOLS_DIR/bin:$BCFTOOLS_DIR/bin:$VCFTOOLS_DIR/bin:$PATH \
    SAMTOOLS=$SAMTOOLS_DIR/bin/samtools \
    BCFTOOLS=$BCFTOOLS_DIR/bin/bcftools \
    VCFTOOLS=$VCFTOOLS_DIR/bin/vcftools \
    LD_LIBRARY_PATH=$SAMTOOLS_DIR/lib:$BCFTOOLS_DIR/lib:$VCFTOOLS_DIR/lib

# Устанавливаем рабочую директорию
WORKDIR /data

# Указываем точку входа (bash)
ENTRYPOINT ["/bin/bash"]
