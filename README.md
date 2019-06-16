# hmmer-docker

## Docker support for HMMER-- biological sequence analysis using profile HMMs

#### To learn more about HMMER
http://hmmer.org/documentation.html
http://eddylab.org/software/hmmer/Userguide.pdf

#### To learn more about Docker:
https://docs.docker.com/get-started/

### Quickstart instructions:

#### Install Docker on your machine: 
https://docs.docker.com/docker-for-mac/install/
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04


#### Build the HMMER Docker image:
You will need to build a Docker image from the Dockerfile and you need to be in the same directory where the Dockerfile is located to execute build command
```bash
cd hmmer-docker
docker build --tag my_hmmer .
```

#### Run a HMMER command:
```bash
docker run -it my_hmmer:latest <HMMER command>
```

#### E.g to run hmmsearch:
```bash
docker run -it my_hmmer:latest hmmsearch
```
