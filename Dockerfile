FROM jetbrains/writerside-builder:2026.02.8644 as build

ARG INSTANCE=Writerside/aag

RUN mkdir /opt/sources

WORKDIR /opt/sources

ADD . ./Writerside

RUN export DISPLAY=:99 && \
  Xvfb :99 & \
  sleep 3 && \
  /opt/builder/bin/idea.sh helpbuild --source-dir /opt/sources --product $INSTANCE --runner other --output-dir /opt/wrs-output/

WORKDIR /opt/wrs-output

RUN unzip -O UTF-8 webHelpAAG2-all.zip -d /opt/wrs-output/unzipped-artifact

FROM httpd:2.4 as http-server

COPY --from=build /opt/wrs-output/unzipped-artifact/ /usr/local/apache2/htdocs/
