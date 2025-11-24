import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

// Crear usuario admin si no existe
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'admin123')
instance.setSecurityRealm(hudsonRealm)

// Configurar autorización
def strategy = new FullControlOnceLoggedInStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()

println "Usuario admin creado con password 'admin123'"

