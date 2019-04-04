ARG ES_VERSION="6.6.1"
ARG MAVEN_TAG="3.6.0-jdk-8-alpine"

FROM maven:${MAVEN_TAG} as build
COPY opendistro-security /root/opendistro-security
COPY opendistro-security-ssl /root/opendistro-security-ssl
COPY opendistro-security-advanced-modules /root/opendistro-security-advanced-modules
COPY pom.xml /root/
COPY .git /root/.git
RUN cd /root/ && mvn install -DskipTests=true
RUN cd /root/opendistro-security && mvn install -DskipTests=true -Padvanced

FROM docker.elastic.co/elasticsearch/elasticsearch:${ES_VERSION}
LABEL Author="Alexey Pronin <a@vuln.be>"
ARG PLUGIN_VERSION="0.8.0.0"
COPY --from=build /root/opendistro-security/target/releases/opendistro_security-${PLUGIN_VERSION}.zip /tmp/
RUN bin/elasticsearch-plugin install -b file:///tmp/opendistro_security-${PLUGIN_VERSION}.zip && \
    echo 'opendistro_security.disabled: true' >> /usr/share/elasticsearch/config/elasticsearch.yml && \
    echo 'xpack.security.enabled: false' >> /usr/share/elasticsearch/config/elasticsearch.yml
