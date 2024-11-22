FROM python:3.12.7-slim-bookworm

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN groupadd -g 1000 py-tainer && \
    useradd -u 1000 -g py-tainer -m -s /bin/bash py-tainer

COPY ./requirements.txt /tmp/requirements.txt

RUN pip install -r /tmp/requirements.txt

USER py-tainer
