## Example run

```
docker run --rm -it          \
    -v "$(pwd)"/scan:/scan   \
    -v "$(pwd)"/creds:/creds \
    npro-emb 192.168.100.1 --ssh-key /creds/id_rsa
```
