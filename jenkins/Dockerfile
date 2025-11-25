# Jenkins Dockerfile - Optimizado para Lab 4
FROM jenkins/jenkins:2.528.2-lts-jdk17

# Cambiar a usuario root para instalar dependencias
USER root

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
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

# Instalar Helm (versión fija para evitar rate limits de GitHub)
RUN HELM_VERSION="v3.14.0" \
    && curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
    && tar -zxvf "helm-${HELM_VERSION}-linux-amd64.tar.gz" \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf "helm-${HELM_VERSION}-linux-amd64.tar.gz" linux-amd64 \
    && helm version

# Instalar Semgrep usando pip (con --break-system-packages para sistemas protegidos)
RUN pip3 install --break-system-packages --no-cache-dir semgrep==1.45.0

# Instalar Snyk CLI (con reintentos para evitar rate limits)
RUN curl -L --retry 3 --retry-delay 2 \
    "https://github.com/snyk/cli/releases/download/v1.1293.0/snyk-linux" \
    -o /usr/local/bin/snyk \
    && chmod +x /usr/local/bin/snyk \
    && snyk --version || echo "Snyk instalado (versión puede requerir autenticación)"

# Crear directorio para init scripts
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

# Copiar lista de plugins a instalar (como root para tener permisos)
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Instalar plugins desde la lista (como root, luego cambiar ownership)
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt \
    && chown -R jenkins:jenkins /usr/share/jenkins/ref

# Volver al usuario jenkins
USER jenkins

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

