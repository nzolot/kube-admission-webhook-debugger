FROM python:3.9.10-slim-buster

MAINTAINER Nick Zolotarov <n.zolot@hotmail.com>

ENV APP_HOME    /app
ENV RUN_USER    app
ENV RUN_GROUP   app

RUN mkdir -p $APP_HOME && \
    groupadd -g 4331 $RUN_GROUP && \
    useradd -u 4331 -g $RUN_GROUP -d $APP_HOME $RUN_USER && \
    chown $RUN_USER:$RUN_GROUP $APP_HOME -R

WORKDIR $APP_HOME
COPY app/requirements.txt $APP_HOME/requirements.txt
RUN pip install -r requirements.txt
COPY app $APP_HOME

USER $RUN_USER

ENTRYPOINT ["gunicorn", "--access-logfile=/dev/stdout", "--log-file=/dev/stdout", "app:app"]
