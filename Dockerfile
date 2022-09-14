FROM python:3.10-slim-bullseye as spark_iceberg_glue

# Install Java 11 (for pyspark 3) and confirm that it works
# Deal with slim variants not having man page directories (which causes "update-alternatives" to fail)
RUN mkdir -p /usr/share/man/man1 /usr/share/man/man2 && \
    apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends \
      less \
      sudo \
      curl \
      vim \
      unzip \
      openjdk-11-jdk \
      build-essential \
      software-properties-common \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

## Download spark and and install dependencies
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
ENV HADOOP_HOME=${HADOOP_HOME:-"/opt/hadoop"}
RUN mkdir -p ${HADOOP_HOME} && mkdir -p ${SPARK_HOME}

ADD spark-3.3.0-bin-spark-with-glue-hive.tgz /opt
RUN mv /opt/spark-3.3.0-bin-spark-with-glue-hive/* /opt/spark/

#ENV PYTHONPATH=$(ZIPS=("$SPARK_HOME"/python/lib/*.zip); IFS=:; echo "${ZIPS[*]}"):$PYTHONPATH
ENV PYTHONPATH="$SPARK_HOME"/python/lib/pyspark.zip:"$SPARK_HOME"/python/lib/py4j-0.10.9.5-src.zip:$PYTHONPATH
ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
RUN pip install --no-cache-dir -e $SPARK_HOME/python
RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*

COPY spark_dependencies $SPARK_HOME
COPY glue $SPARK_HOME

# Install Jupyter and other python deps
RUN pip3 install jupyter==1.0.0 prettytable==3.2.0 spylon-kernel==0.4.1

# Add scala kernel via spylon-kernel
RUN python3 -m spylon_kernel install

### Additional libraries for local development
# Install AWS CLI
RUN arch=$(arch) \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-$arch.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && sudo ./aws/install \
 && rm awscliv2.zip \
 && rm -rf aws/


# Download postgres connector jar
RUN mkdir -p /opt/spark/jars
RUN curl https://jdbc.postgresql.org/download/postgresql-42.2.24.jar -o $SPARK_HOME/jars/postgresql-42.2.24.jar

RUN mkdir -p /home/iceberg/localwarehouse /home/iceberg/notebooks /home/iceberg/warehouse /home/iceberg/spark-events /home/iceberg

# Add a notebook command
RUN echo '#! /bin/sh' >> /bin/notebook \
 && echo 'export PYSPARK_DRIVER_PYTHON=jupyter-notebook' >> /bin/notebook \
 && echo "export PYSPARK_DRIVER_PYTHON_OPTS=\"--notebook-dir=/home/iceberg/notebooks --ip='*' --NotebookApp.token='' --NotebookApp.password='' --port=8888 --no-browser --allow-root\"" >> /bin/notebook \
 && echo "pyspark" >> /bin/notebook \
 && chmod u+x /bin/notebook

# Add a pyspark-notebook command (alias for notebook command for backwards-compatibility)
RUN echo '#! /bin/sh' >> /bin/pyspark-notebook \
 && echo 'export PYSPARK_DRIVER_PYTHON=jupyter-notebook' >> /bin/pyspark-notebook \
 && echo "export PYSPARK_DRIVER_PYTHON_OPTS=\"--notebook-dir=/home/iceberg/notebooks --ip='*' --NotebookApp.token='' --NotebookApp.password='' --port=8888 --no-browser --allow-root\"" >> /bin/pyspark-notebook \
 && echo "pyspark" >> /bin/pyspark-notebook \
 && chmod u+x /bin/pyspark-notebook

RUN mkdir -p /root/.ipython/profile_default/startup
COPY tabular/ipython/startup /root/.ipython/profile_default/startup

WORKDIR /root
ENTRYPOINT []
CMD []
