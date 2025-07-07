FROM python:3.11-bookworm

RUN apt-get update && \
    apt-get install -yq tzdata && \
    ln -fs /usr/share/zoneinfo/America/Caracas /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

ADD . /app

WORKDIR /app

COPY . /app

ADD deployment/secrets/.  /root/.ssh

RUN chmod 600 /root/.ssh -R


ENV POETRY_VIRTUALENVS_CREATE=false
RUN pip install --upgrade pip && pip install poetry pytest coverage

EXPOSE 5002

RUN poetry lock
RUN poetry install  --no-root
RUN chmod +x deployment/scripts/start_service.sh


CMD ["./deployment/scripts/start_service.sh"]
