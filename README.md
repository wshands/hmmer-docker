# hmmer-docker

## Docker support for HMMER-- biological sequence analysis using profile HMMs

#### To build the image:
```bash
docker build --tag my_hmmer .
```

#### To run a HMMER command:
```bash
docker run -it my_hmmer:latest <HMMER command>
```

#### E.g to run hmmsearch:
```bash
docker run -it my_hmmer:latest hmmsearch
```
