dotnet publish -c Release

docker build -t counter-image -f Dockerfile .

docker create --name core-counter counter-image

docker start core-counter

docker pull aquasec/trivy:latest

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v .:/root/.cache/ aquasec/trivy image counter-image
