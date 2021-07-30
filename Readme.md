## Setup 
* [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/gcp-get-started)
* [Configure access to GCP for Terraform](https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build?in=terraform/gcp-get-started#set-up-gcp)
* Enable the following services in the GCP project:
  * [Artifact Registry](https://cloud.google.com/artifact-registry/docs/enable-service)
  * [Cloud Build](https://cloud.google.com/build/docs/quickstart-build#before-you-begin)
  * [Source Repository](https://cloud.google.com/source-repositories/docs/quickstart#before-you-begin)
  * [Secret Manager](https://cloud.google.com/secret-manager/docs/configuring-secret-manager#enable_api)
* Move to the `gcp-nessus-build-pipeline` folder 
  * `cd gcp-nessus-build-pipeline`
* Run `terraform init`
* (Optional) Run `terraform plan` to view the changes made to your GCP account before deploying
* Run `terraform apply` and supply the following values when prompted:
  * [GCP Project ID](https://support.google.com/googleapi/answer/7014113?hl=en)
  * Nessus License Key
  * Nessus Admin Password you want to utilize
* After Terraform completes, move back to the root of this repo
  * `cd ..`
* [Install and configure the `gcloud` CLI tool](https://cloud.google.com/sdk/docs/install)
* To begin a build job, run `gcloud builds submit --config=cloudbuild.yaml --machine-type=N1_HIGHCPU_8`
* Once the build completes, make sure you've [configured Docker to have access to your Artifact Registry](https://cloud.google.com/artifact-registry/docs/docker/authentication).
* Run `docker pull <location>-docker.pkg.dev/<project-id>/<artifact-registry-name>/<image-name>:latest` after replacing all values with the resources in your GCP account.
  * By default:
    * `location` is set to `us-central1`
    * `artifact-registry-name` is set to `nessus-builds`
    * `image-name` is set to `npro`
  * All these settings can be located and changed in `variables.tf`. You must also update `cloudbuild.yaml` if you change any of these three settings
* You now have a fully licensed Nessus Docker image ready to perform scans 

### Additional Setup Details
**Note:** If you altered any values in the `variables.tf` file, make sure those values are also changed in the `cloudbuild.yaml` file. Most importantly, make sure `_LOCATION`, `_REPOSITORY`, and `_IMAGE` all match with what you created using Terraform.

Cloud Build also runs on a source trigger on the `main` branch of the created Source Repository. However, starting a job with `gcloud build` is the easiest method for getting a Docker image built immediately.

## Example run

```
docker run --rm -it          \
    -v "$(pwd)"/scan:/scan   \
    -v "$(pwd)"/creds:/creds \
    us-central1-docker.pkg.dev/nessus-project/nessus-builds/npro:latest 192.168.100.1 --ssh-key /creds/id_rsa --scan-username='<user-to-assume-on-ssh>'
```

## Example for using the container as a long running Nessus instance
```
docker run -it -p 8834:8834 \
    --entrypoint='/opt/nessus/sbin/nessus-service' \
    us-central1-docker.pkg.dev/nessus-project/nessus-builds/npro:latest`
```

After container starts running, connect to https://localhost:8834 or `https://<vm-public-ip>:8834`
