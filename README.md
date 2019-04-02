# hmmer-docker

## Docker support for HMMER-- biological sequence analysis using profile HMMs

#### To build the image:
```bash
docker build --tag <name of the image> .
```

#### To run a HMMER command:
```bash
docker run -it <name of the image>:latest <HMMER command>
```

#### E.g to run hmmsearch:
```bash
docker run -it <name of the image>:latest hmmsearch
```
