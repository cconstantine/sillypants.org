resource "aws_s3_bucket" "docker_registry" {
    bucket = "registry.docker.sillypants.org"

    tags {
        Name = "Docker Registry"
    }
}