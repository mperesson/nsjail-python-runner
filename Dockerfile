FROM python:3.13-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    libc6 \
    libstdc++6 \
    libprotobuf32 \
    libnl-route-3-200 \
    gosu \
    && rm -rf /var/lib/apt/lists/*

FROM base AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    autoconf \
    bison \
    flex \
    gcc \
    g++ \
    libprotobuf-dev \
    libnl-route-3-dev \
    libtool \
    make \
    pkg-config \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/google/nsjail.git && \
    cd nsjail && make clean && make

FROM base AS final

WORKDIR /app

COPY --from=build /nsjail/nsjail /usr/local/bin/nsjail

RUN mkdir -p /sandbox && chmod 777 /sandbox

# Sandbox venv setup
RUN python -m venv /sandbox/venv && \
    /sandbox/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel

COPY requirements-sandbox.txt .
RUN /sandbox/venv/bin/pip install --no-cache-dir -r requirements-sandbox.txt

# API venv setup
RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Copy app files
COPY entrypoint.sh /app/entrypoint.sh
COPY src/app.py /app/app.py
COPY nsjail/runner.py /sandbox/runner.py
COPY nsjail/nsjail.cfg /app/nsjail.cfg

RUN chmod +x /app/entrypoint.sh

EXPOSE 5000

CMD ["/app/entrypoint.sh"]
