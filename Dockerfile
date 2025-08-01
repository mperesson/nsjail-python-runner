FROM python:3.13 AS base

# Install run-time dependencies in base image
RUN apt-get -y update && apt-get install -y \
    libc6 \
    libstdc++6 \
    libprotobuf32 \
    libnl-route-3-200

FROM base AS build

# Install build dependencies only in builder image
RUN apt-get install -y \
    git \
    autoconf \
    bison \
    flex \
    gcc \
    g++ \
    git \
    libprotobuf-dev \
    libnl-route-3-dev \
    libtool \
    make \
    pkg-config \
    protobuf-compiler

RUN git clone https://github.com/google/nsjail.git

RUN cd /nsjail && make clean && make

FROM build AS nsjail-bin

# Copy over build result and trim image
RUN rm -rf /var/lib/apt/lists/*
COPY --from=build /nsjail/nsjail /bin

FROM nsjail-bin AS python-app

WORKDIR /app

# install security updates and required packages
RUN apt-get -qq update && apt-get -qq upgrade \
    && apt-get -qq install --no-install-recommends \
    gosu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create sandbox dir
RUN mkdir -p /sandbox && chmod 777 /sandbox
RUN python -m venv /sandbox/venv
# upgrade pip and install python packages for building
RUN pip install --no-cache-dir --upgrade \
    pip \
    setuptools \
    wheel

# install dependencies
COPY requirements-sandbox.txt .
RUN pip install --no-cache-dir -r requirements-sandbox.txt


COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh


# create virtual environment
RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# upgrade pip and install python packages for building
RUN pip install --no-cache-dir --upgrade \
    pip \
    setuptools \
    wheel

# install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy server and runner
COPY src/app.py /app/app.py
COPY nsjail/runner.py /sandbox/runner.py
COPY nsjail/nsjail.cfg /app/nsjail.cfg

# Expose the Flask port
EXPOSE 5000

CMD ["/app/entrypoint.sh"]
