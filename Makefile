.PHONY:
docker: .docker.image
.docker.image: Dockerfile
	sudo -A docker build --iidfile=$@ --progress=plain .
