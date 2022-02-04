# gce-integrity-tester

A script for quickly examining instance's shielded VM integrity logs on GCE for errors.

## Demo

![screenshot](https://user-images.githubusercontent.com/1793699/152545231-387731cc-13f6-4272-af89-bb130d117239.png)

## Usage

1. Create a shielded instance with a service account and required API scope:
    ```
    gcloud compute instances create \
      test-instance \
      --machine-type "n2d-standard-2" \
      --zone "europe-west1-d" \
      --maintenance-policy=TERMINATE \
      --image-project=IMAGE_PROJECT \
      --image-name=IMAGE_NAME \
      --service-account SERVICE_ACCOUNT@developer.gserviceaccount.com \
      --scopes https://www.googleapis.com/auth/logging.read \
      --shielded-integrity-monitoring \
      --shielded-secure-boot
    ```
2. SSH into the instance: `gcloud compute ssh test-instance`
3. Run the script: `curl -sSf https://raw.githubusercontent.com/ikapelyukhin/gce-integrity-tester/master/integrity.sh | bash`
4. Troubleshoot errors :-)