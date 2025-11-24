import jenkins.model.*
import hudson.tools.*
import hudson.plugins.nodejs.*

def instance = Jenkins.getInstance()

// Configurar Node.js
def nodeJSInstallations = [
    new NodeJSInstallation(
        "NodeJS 18",
        "/usr/local/bin/node",
        null
    )
]

def nodeJSDescriptor = instance.getDescriptor(NodeJSInstallation.class)
nodeJSDescriptor.setInstallations(nodeJSInstallations as NodeJSInstallation[])
nodeJSDescriptor.save()

instance.save()

println "Herramientas configuradas"

