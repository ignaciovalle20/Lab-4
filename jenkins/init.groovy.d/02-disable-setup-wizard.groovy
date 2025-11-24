import jenkins.model.*
import jenkins.install.*

def instance = Jenkins.getInstance()

// Deshabilitar setup wizard
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

instance.save()

println "Setup wizard deshabilitado"

