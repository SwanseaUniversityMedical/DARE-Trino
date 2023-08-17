FROM trinodb/trino:420

LABEL org.opencontainers.image.source=https://github.com/SwanseaUniversityMedical/DARE-Trino

USER root
ENV TRINO_PLUGIN_DIR=/usr/lib/trino/plugin
ENV TRINO_VERSION=420
ENV IMPORT_PLUGIN_DIR=/custom-plugins

RUN apt-get update && apt-get install -y unzip vim

# Copy any extra plugin files
COPY /containers/trino/plugins/trino-querylog-$TRINO_VERSION.zip $IMPORT_PLUGIN_DIR/
COPY /containers/trino/plugins/trino-trino-$TRINO_VERSION.zip $IMPORT_PLUGIN_DIR/

# Unzip and move extra plugins
RUN unzip $IMPORT_PLUGIN_DIR/trino-querylog-$TRINO_VERSION.zip -d $IMPORT_PLUGIN_DIR/trino-querylog && \
	mv $IMPORT_PLUGIN_DIR/trino-querylog $TRINO_PLUGIN_DIR/

RUN unzip $IMPORT_PLUGIN_DIR/trino-trino-$TRINO_VERSION.zip -d $IMPORT_PLUGIN_DIR/ && \
	mkdir $TRINO_PLUGIN_DIR/trino && \
	mv $IMPORT_PLUGIN_DIR/trino-trino-$TRINO_VERSION/* $TRINO_PLUGIN_DIR/trino/

# Correct permissions for folder for the logging
RUN chown 1000 /var/log

USER trino