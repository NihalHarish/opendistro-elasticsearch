IMAGE_NAME			:= opendistro-elasticsearch
REPO						?= vulnbe
ES_VERSION 			?= 6.6.1
PLUGIN_VERSION	?= 0.8.0.0
MAVEN_TAG				?= 3.6.0-jdk-8-alpine

.PHONY: image push submodules

submodules:
	git submodule update --recursive

image: submodules
	docker build \
		--build-arg ES_VERSION=${ES_VERSION} \
		--build-arg PLUGIN_VERSION=${PLUGIN_VERSION} \
		--build-arg MAVEN_TAG=${MAVEN_TAG} \
		-t ${IMAGE_NAME}:${ES_VERSION}-${PLUGIN_VERSION} \
		--pull .

plugin: submodules
	mkdir output
	docker run -it --rm \
		-v $$PWD:/opendistro-security:ro \
		-v $$PWD/output:/output \
		maven:${MAVEN_TAG} \
		bash -c "\
			cp -r /opendistro-security /tmp/ods && \
			cd /tmp/ods && \
			mvn install -DskipTests=true && \
			cd /tmp/ods/opendistro-security && \
			mvn install -DskipTests=true -Padvanced && \
			cp /tmp/ods/opendistro-security/target/releases/opendistro_security-${PLUGIN_VERSION}.zip /output"

push:
	docker tag ${IMAGE_NAME}:${ES_VERSION}-${PLUGIN_VERSION} \
		${REPO}/${IMAGE_NAME}:${ES_VERSION}-${PLUGIN_VERSION}
	docker push ${REPO}/${IMAGE_NAME}:${ES_VERSION}-${PLUGIN_VERSION}
