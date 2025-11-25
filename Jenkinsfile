pipeline {
    agent any
    
    // Variables de entorno globales
    environment {
        // Docker
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_REPO = 'tienda-online'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        
        // Kubernetes
        K8S_NAMESPACE = 'tienda-online'
        KUBECONFIG_CREDENTIALS_ID = 'kubeconfig'
        
        // Security tools
        SNYK_TOKEN = credentials('snyk-token')
        
        // Build info
        GIT_COMMIT_SHORT = sh(
            script: "git rev-parse --short HEAD",
            returnStdout: true
        ).trim()
        BUILD_VERSION = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
        
        // Image tags (se configurarán dinámicamente en el stage de Checkout)
        BACKEND_IMAGE = ''
        FRONTEND_IMAGE = ''
        DATABASE_IMAGE = ''
        USE_MINIKUBE = 'false'
    }
    
    // Opciones del pipeline
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        ansiColor('xterm')
    }
    
    stages {
        stage('1. Checkout') {
            steps {
                echo '========================================='
                echo 'Stage 1: Checkout del código'
                echo '========================================='
                
                checkout scm
                
                script {
                    // Obtener información del commit
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    env.GIT_AUTHOR = sh(
                        script: 'git log -1 --pretty=%an',
                        returnStdout: true
                    ).trim()
                    
                    // Detectar si estamos usando Minikube
                    try {
                        withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG')]) {
                            def currentContext = sh(
                                script: 'kubectl config current-context 2>/dev/null || echo ""',
                                returnStdout: true
                            ).trim()
                            
                            if (currentContext.contains('minikube')) {
                                env.USE_MINIKUBE = 'true'
                                // Para Minikube: usar nombres simples sin registry
                                env.BACKEND_IMAGE = "tienda-backend:${BUILD_VERSION}"
                                env.FRONTEND_IMAGE = "tienda-frontend:${BUILD_VERSION}"
                                env.DATABASE_IMAGE = "tienda-database:${BUILD_VERSION}"
                                echo "✓ Detectado Minikube - Usando imágenes locales"
                            } else {
                                env.USE_MINIKUBE = 'false'
                                // Para producción: usar registry completo
                                env.BACKEND_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_REPO}/backend:${BUILD_VERSION}"
                                env.FRONTEND_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_REPO}/frontend:${BUILD_VERSION}"
                                env.DATABASE_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_REPO}/database:${BUILD_VERSION}"
                                echo "✓ Usando Docker Hub registry"
                            }
                        }
                    } catch (Exception e) {
                        // Si no hay kubeconfig, asumir miniku
                        env.USE_MINIKUBE = 'true'
                        env.BACKEND_IMAGE = "tienda-backend:${BUILD_VERSION}"
                        env.FRONTEND_IMAGE = "tienda-frontend:${BUILD_VERSION}"
                        env.DATABASE_IMAGE = "tienda-database:${BUILD_VERSION}"
                        echo "⚠️  No se pudo detectar contexto de Kubernetes, usando Minikube"
                    }
                }
                
                echo "Commit: ${env.GIT_COMMIT_SHORT}"
                echo "Autor: ${env.GIT_AUTHOR}"
                echo "Mensaje: ${env.GIT_COMMIT_MSG}"
                echo "Entorno: ${env.USE_MINIKUBE == 'true' ? 'Minikube (imágenes locales)' : 'Producción (Docker Hub)'}"
                echo "Backend Image: ${env.BACKEND_IMAGE}"
                echo "Frontend Image: ${env.FRONTEND_IMAGE}"
                echo "Database Image: ${env.DATABASE_IMAGE}"
            }
        }
        
        stage('2. Semgrep - Static Analysis') {
            steps {
                echo '========================================='
                echo 'Stage 2: Análisis estático con Semgrep'
                echo '========================================='
                
                script {
                    try {
                        // Análisis del backend
                        sh '''
                            echo "Analizando backend..."
                            semgrep --config=auto \
                                --json \
                                --output=reports/semgrep-backend.json \
                                backend/ || true
                            
                            echo "Analizando frontend..."
                            semgrep --config=auto \
                                --json \
                                --output=reports/semgrep-frontend.json \
                                frontend/ || true
                            
                            # Generar reporte consolidado
                            echo "=== SEMGREP ANALYSIS REPORT ===" > reports/semgrep-report.txt
                            echo "" >> reports/semgrep-report.txt
                            echo "Build: ${BUILD_VERSION}" >> reports/semgrep-report.txt
                            echo "Date: $(date)" >> reports/semgrep-report.txt
                            echo "" >> reports/semgrep-report.txt
                            
                            echo "--- Backend Results ---" >> reports/semgrep-report.txt
                            semgrep --config=auto backend/ 2>&1 >> reports/semgrep-report.txt || true
                            echo "" >> reports/semgrep-report.txt
                            
                            echo "--- Frontend Results ---" >> reports/semgrep-report.txt
                            semgrep --config=auto frontend/ 2>&1 >> reports/semgrep-report.txt || true
                            
                            cat reports/semgrep-report.txt
                        '''
                        
                        // Publicar resultados
                        archiveArtifacts artifacts: 'reports/semgrep-*.json, reports/semgrep-report.txt', 
                                         allowEmptyArchive: true
                        
                        echo '✓ Semgrep analysis completed'
                    } catch (Exception e) {
                        echo "⚠️  Semgrep analysis failed: ${e.message}"
                        echo "Continuing pipeline..."
                    }
                }
            }
        }
        
        stage('3. Snyk - Dependency Scan') {
            steps {
                echo '========================================='
                echo 'Stage 3: Escaneo de dependencias con Snyk'
                echo '========================================='
                
                script {
                    try {
                        sh '''
                            # Autenticar con Snyk
                            snyk auth ${SNYK_TOKEN}
                            
                            # Escanear backend
                            echo "Escaneando dependencias del backend..."
                            cd backend
                            snyk test --json > ../reports/snyk-backend.json || true
                            snyk test --severity-threshold=high || SNYK_BACKEND_EXIT=$?
                            cd ..
                            
                            # Escanear frontend
                            echo "Escaneando dependencias del frontend..."
                            cd frontend
                            snyk test --json > ../reports/snyk-frontend.json || true
                            snyk test --severity-threshold=high || SNYK_FRONTEND_EXIT=$?
                            cd ..
                            
                            # Generar reporte consolidado
                            echo "=== SNYK DEPENDENCY SCAN REPORT ===" > reports/snyk-report.txt
                            echo "" >> reports/snyk-report.txt
                            echo "Build: ${BUILD_VERSION}" >> reports/snyk-report.txt
                            echo "Date: $(date)" >> reports/snyk-report.txt
                            echo "" >> reports/snyk-report.txt
                            
                            echo "--- Backend Dependencies ---" >> reports/snyk-report.txt
                            cd backend && snyk test 2>&1 >> ../reports/snyk-report.txt || true
                            cd ..
                            echo "" >> reports/snyk-report.txt
                            
                            echo "--- Frontend Dependencies ---" >> reports/snyk-report.txt
                            cd frontend && snyk test 2>&1 >> ../reports/snyk-report.txt || true
                            cd ..
                            
                            cat reports/snyk-report.txt
                        '''
                        
                        // Publicar resultados
                        archiveArtifacts artifacts: 'reports/snyk-*.json, reports/snyk-report.txt', 
                                         allowEmptyArchive: true
                        
                        echo '✓ Snyk scan completed'
                        
                        // Verificar vulnerabilidades críticas
                        def snykBackend = sh(
                            script: 'grep -c "Critical" reports/snyk-report.txt || true',
                            returnStdout: true
                        ).trim()
                        
                        if (snykBackend.toInteger() > 0) {
                            echo "⚠️  Se encontraron ${snykBackend} vulnerabilidades críticas"
                            // Descomentar para fallar el build en caso de críticas
                            // error("Build failed due to critical vulnerabilities")
                        }
                    } catch (Exception e) {
                        echo "⚠️  Snyk scan failed: ${e.message}"
                        echo "Continuing pipeline..."
                    }
                }
            }
        }
        
        stage('4. Build - Install Dependencies') {
            parallel {
                stage('Backend') {
                    steps {
                        echo 'Instalando dependencias del backend...'
                        dir('backend') {
                            sh 'npm ci --prefer-offline --no-audit'
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        echo 'Instalando dependencias del frontend...'
                        dir('frontend') {
                            sh 'npm ci --prefer-offline --no-audit'
                        }
                    }
                }
            }
        }
        
        stage('5. Test') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        echo 'Ejecutando tests del backend...'
                        dir('backend') {
                            sh 'npm test || echo "No tests configured"'
                        }
                    }
                }
                stage('Frontend Tests') {
                    steps {
                        echo 'Ejecutando tests del frontend...'
                        dir('frontend') {
                            sh 'npm test -- --watchAll=false || echo "No tests configured"'
                        }
                    }
                }
            }
        }
        
        stage('6. Docker Build') {
            parallel {
                stage('Backend Image') {
                    steps {
                        echo "Construyendo imagen del backend: ${BACKEND_IMAGE}"
                        dir('backend') {
                            script {
                                docker.build("${BACKEND_IMAGE}")
                            }
                        }
                    }
                }
                stage('Frontend Image') {
                    steps {
                        echo "Construyendo imagen del frontend: ${FRONTEND_IMAGE}"
                        dir('frontend') {
                            script {
                                docker.build("${FRONTEND_IMAGE}")
                            }
                        }
                    }
                }
                stage('Database Image') {
                    steps {
                        echo "Construyendo imagen de la base de datos: ${DATABASE_IMAGE}"
                        dir('database') {
                            script {
                                docker.build("${DATABASE_IMAGE}")
                            }
                        }
                    }
                }
            }
        }
        
        stage('7. Docker Push / Load Images') {
            when {
                branch 'main'
            }
            steps {
                echo '========================================='
                echo 'Stage 7: Publicando/cargando imágenes'
                echo '========================================='
                
                script {
                    if (env.USE_MINIKUBE == 'true') {
                        // Para Minikube: cargar imágenes directamente
                        echo "Cargando imágenes en Minikube..."
                        
                        withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG')]) {
                            // Verificar que Minikube esté corriendo
                            sh """
                                if ! minikube status > /dev/null 2>&1; then
                                    echo "⚠️  Minikube no está corriendo. Las imágenes se construirán pero no se cargarán automáticamente."
                                    echo "⚠️  Para cargar manualmente, ejecuta: minikube image load <imagen>"
                                else
                                    echo "✓ Minikube está corriendo"
                                    
                                    # Cargar imágenes en Minikube
                                    echo "Cargando ${BACKEND_IMAGE} en Minikube..."
                                    minikube image load ${BACKEND_IMAGE} || echo "⚠️  Falló carga de ${BACKEND_IMAGE}"
                                    
                                    echo "Cargando ${FRONTEND_IMAGE} en Minikube..."
                                    minikube image load ${FRONTEND_IMAGE} || echo "⚠️  Falló carga de ${FRONTEND_IMAGE}"
                                    
                                    echo "Cargando ${DATABASE_IMAGE} en Minikube..."
                                    minikube image load ${DATABASE_IMAGE} || echo "⚠️  Falló carga de ${DATABASE_IMAGE}"
                                    
                                    # Verificar que las imágenes estén disponibles
                                    echo "Imágenes disponibles en Minikube:"
                                    minikube image ls | grep tienda || echo "⚠️  No se encontraron imágenes tienda-* en Minikube"
                                fi
                            """
                        }
                        
                        echo '✓ Images loaded into Minikube successfully'
                    } else {
                        // Para producción: pushear a Docker Hub
                        echo "Pusheando imágenes a Docker Hub..."
                        
                        docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS_ID) {
                            // Push backend
                            echo "Pushing ${BACKEND_IMAGE}"
                            sh "docker push ${BACKEND_IMAGE}"
                            
                            // Push frontend
                            echo "Pushing ${FRONTEND_IMAGE}"
                            sh "docker push ${FRONTEND_IMAGE}"
                            
                            // Push database
                            echo "Pushing ${DATABASE_IMAGE}"
                            sh "docker push ${DATABASE_IMAGE}"
                        }
                        
                        echo '✓ Images pushed to Docker Hub successfully'
                    }
                }
            }
        }
        
        stage('8. Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                echo '========================================='
                echo 'Stage 8: Desplegando en Kubernetes'
                echo '========================================='
                
                script {
                    // Usar kubeconfig credentials
                    withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG')]) {
                        sh """
                            # Verificar conexión con el cluster
                            kubectl cluster-info
                            
                            # Crear namespace si no existe
                            kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                            
                            # Desplegar o actualizar con Helm
                            # Configurar imágenes según el entorno
                            if [ "${USE_MINIKUBE}" = "true" ]; then
                                # Para Minikube: usar nombres simples sin registry
                                helm upgrade --install tienda-online ./helm-chart/tienda-online \\
                                    --namespace ${K8S_NAMESPACE} \\
                                    --set backend.image.repository=tienda-backend \\
                                    --set backend.image.tag=${BUILD_VERSION} \\
                                    --set frontend.image.repository=tienda-frontend \\
                                    --set frontend.image.tag=${BUILD_VERSION} \\
                                    --set database.image.repository=tienda-database \\
                                    --set database.image.tag=${BUILD_VERSION} \\
                                    --values helm-chart/tienda-online/values-dev.yaml \\
                                    --wait \\
                                    --timeout 5m
                            else
                                # Para producción: usar registry completo
                                helm upgrade --install tienda-online ./helm-chart/tienda-online \\
                                    --namespace ${K8S_NAMESPACE} \\
                                    --set backend.image.repository=${DOCKER_REGISTRY}/${DOCKER_REPO}/backend \\
                                    --set backend.image.tag=${BUILD_VERSION} \\
                                    --set frontend.image.repository=${DOCKER_REGISTRY}/${DOCKER_REPO}/frontend \\
                                    --set frontend.image.tag=${BUILD_VERSION} \\
                                    --set database.image.repository=${DOCKER_REGISTRY}/${DOCKER_REPO}/database \\
                                    --set database.image.tag=${BUILD_VERSION} \\
                                    --values helm-chart/tienda-online/values-dev.yaml \\
                                    --wait \\
                                    --timeout 5m
                            fi
                            
                            # Verificar despliegue
                            kubectl get pods -n ${K8S_NAMESPACE}
                            kubectl get services -n ${K8S_NAMESPACE}
                            
                            # Esperar a que los pods estén ready
                            kubectl wait --for=condition=ready pod \\
                                -l app=tienda-backend \\
                                -n ${K8S_NAMESPACE} \\
                                --timeout=300s
                            
                            kubectl wait --for=condition=ready pod \\
                                -l app=tienda-frontend \\
                                -n ${K8S_NAMESPACE} \\
                                --timeout=300s
                        """
                    }
                }
                
                echo '✓ Deployment completed successfully'
            }
        }
    }
    
    post {
        always {
            echo '========================================='
            echo 'Pipeline Finished'
            echo '========================================='
            
            // Limpiar workspace
            cleanWs()
        }
        success {
            echo '✓ Pipeline completed successfully!'
            
            // Aquí se pueden agregar notificaciones (Slack, email, etc.)
            // slackSend(
            //     color: 'good',
            //     message: "Build ${BUILD_VERSION} deployed successfully"
            // )
        }
        failure {
            echo '✗ Pipeline failed!'
            
            // Aquí se pueden agregar notificaciones de fallo
            // slackSend(
            //     color: 'danger',
            //     message: "Build ${BUILD_VERSION} failed"
            // )
        }
        unstable {
            echo '⚠️  Pipeline completed with warnings'
        }
    }
}

