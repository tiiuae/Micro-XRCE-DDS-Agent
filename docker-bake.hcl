variable "TAG" {
    default = "tag_not_set"
}

variable "NAME" {
    default = "name_not_set"
}

variable "LABELS" {
    default = null
}

group "default" {
    targets = ["amd64", "riscv64"]
}

target "_common" {
    context = "."
    labels = zipmap([for s in split("\n", "${LABELS}") : split("=", s)[0]], [for s in split("\n", "${LABELS}") : split("=", s)[1]])
}

target "amd64" {
    inherits = ["_common"]
    dockerfile = "Dockerfile.amd64"
    platforms = ["linux/amd64"]
    tags = ["ghcr.io/tiiuae/${NAME}:sha-${TAG}-amd64"]
}

target "arm64" {
    inherits = ["_common"]
    dockerfile = "Dockerfile.arm64"
    platforms = ["linux/arm64"]
    tags = ["ghcr.io/tiiuae/${NAME}:sha-${TAG}-arm64"]
}

target "riscv64" {
    inherits = ["_common"]
    dockerfile = "Dockerfile.riscv64"
    platforms = ["linux/riscv64"]
    tags = ["ghcr.io/tiiuae/${NAME}:sha-${TAG}-riscv64"]
}
