docker build -t counter-image -f Dockerfile .

docker pull aquasec/trivy:latest

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v .:/root/.cache/ aquasec/trivy image counter-image
