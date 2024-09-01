FROM ubuntu:20.04

ENV R_VERSION 4.1.0
ENV R_PAPERSIZE=letter

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    make \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    unzip \
    wget \
    zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip 

WORKDIR /root/local/src

# download and install R using the specified version
RUN wget --timestamping https://cloud.r-project.org/src/base/R-${R_VERSION%.*}/R-${R_VERSION}.tar.gz && \
    tar zxf R-${R_VERSION}.tar.gz && \
    cd R-${R_VERSION} && \
    ./configure --prefix=/root/local/${R_VERSION} && \
    make && \
    rm -rf /root/local/${R_VERSION} && \
    make install

# set the installed R bin in the PATH
ENV PATH="/root/local/${R_VERSION}/bin:${PATH}"

# install & run streamlit app
COPY ./app .
RUN python -m pip install --upgrade pip
RUN python -m pip install -r requirements.txt
EXPOSE 8501
CMD ["streamlit", "run", "app.py"]

# install the randomForest package version 4.7-1.1
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/randomForest/randomForest_4.7-1.1.tar.gz', repos=NULL, type='source')"
