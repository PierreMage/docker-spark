FROM pierremage/hadoop:2.7.2
MAINTAINER SequenceIQ

# Install jq
RUN yum -y install wget
RUN cd /opt \
      && mkdir jq \
      && wget -O ./jq/jq http://stedolan.github.io/jq/download/linux64/jq \
      && chmod +x ./jq/jq \
      && ln -s /opt/jq/jq /usr/local/bin

#support for Hadoop 2.7.2
RUN curl -s http://d3kbcqa49mib13.cloudfront.net/spark-2.0.0-bin-hadoop2.7.tgz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s spark-2.0.0-bin-hadoop2.7 spark
ENV SPARK_HOME /usr/local/spark
RUN mkdir $SPARK_HOME/yarn-remote-client
ADD yarn-remote-client $SPARK_HOME/yarn-remote-client

RUN $BOOTSTRAP && $HADOOP_PREFIX/bin/hdfs dfsadmin -safemode leave && \
  cd $SPARK_HOME/jars && \
  tar -czf /spark-2.0.0-jars-hadoop2.7.tgz ./*  && \
  $HADOOP_PREFIX/bin/hdfs dfs -mkdir /spark && \
  $HADOOP_PREFIX/bin/hdfs dfs -put /spark-2.0.0-jars-hadoop2.7.tgz /spark/ && \
  rm /spark-2.0.0-jars-hadoop2.7.tgz

ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV PATH $PATH:$SPARK_HOME/bin:$HADOOP_PREFIX/bin
# update boot script
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

# get rid of WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
ENV LD_LIBRARY_PATH $HADOOP_PREFIX/lib/native

#install R
#RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#RUN yum -y install R

ENTRYPOINT ["/etc/bootstrap.sh"]

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
 CMD $SPARK_HOME/yarn-remote-client/yarn_is_ready.sh
