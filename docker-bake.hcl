variable "TAG" {
    default = "latest"
}

group "default" {
    targets = ["amd64", "riscv64"]
}

target "_common" {
    context = "."
}

target "amd64" {
    inherits = ["_common"]
    dockerfile = "Dockerfile.amd64"
    platforms = ["linux/amd64"]
    tags = ["ghcr.io/tiiuae/tii-microxrce-agent:sha-${TAG}-amd64"]
}

target "riscv64" {
    inherits = ["_common"]
    dockerfile = "Dockerfile.riscv64"
    platforms = ["linux/riscv64"]
    tags = ["ghcr.io/tiiuae/tii-microxrce-agent:sha-${TAG}-riscv64"]
}
