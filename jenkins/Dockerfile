# Jenkins Dockerfile - Optimizado para Lab 4
FROM jenkins/jenkins:2.426.1-lts-jdk17

# Cambiar a usuario root para instalar dependencias
USER root

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Instalar Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli && rm -rf /var/lib/apt/lists/*

# Instalar kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Instalar Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Instalar Semgrep
RUN curl -L https://github.com/returntocorp/semgrep/releases/download/v1.45.0/semgrep-v1.45.0-ubuntu-20.04.tgz | tar xz -C /usr/local/bin

# Instalar Snyk CLI
RUN curl -L https://github.com/snyk/cli/releases/download/v1.1293.0/snyk-linux -o /usr/local/bin/snyk \
    && chmod +x /usr/local/bin/snyk

# Crear directorio para init scripts
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

# Volver al usuario jenkins
USER jenkins

# Copiar lista de plugins a instalar
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Instalar plugins desde la lista
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copiar scripts de inicialización
COPY init.groovy.d/*.groovy /usr/share/jenkins/ref/init.groovy.d/

# Exponer puertos
EXPOSE 8080 50000

# Variables de entorno
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV JENKINS_OPTS="--httpPort=8080"

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8080/login || exit 1

