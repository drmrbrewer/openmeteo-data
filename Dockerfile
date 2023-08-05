# https://hub.docker.com/_/ubuntu
FROM ubuntu:22.10

# following ENV is to avoid the docker install waiting on user input when "Configuring tzdata"... as per https://github.com/caprover/caprover/issues/659
ENV DEBIAN_FRONTEND=noninteractive

# install aws and gdal (for digital elevation model)...
# https://github.com/open-meteo/open-meteo/blob/main/docs/getting-started.md#digital-elevation-model
RUN apt-get update && apt-get -y install awscli gdal-bin \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

VOLUME /root/data

# --------------------
# fetch elevation data
# --------------------
# the cronjobs will download and process the weather data files on a schedule, of course because the weather data is constantly updated...
# run the following commands to download and process the elevation files separately, which is a one-off process:
# https://github.com/open-meteo/open-meteo/blob/main/docs/getting-started.md#digital-elevation-model
# xxx should maybe separate these steps out into a separate image and load in with FROM... otherwise
# we risk having to re-download again if we make a change to a layer/step further above this?
RUN cd /root \
# download the raw elevation data files...
# the following needs around 40GB of spare disk... though this is recovered later by removing the raw data files...
  && aws s3 sync --no-sign-request --exclude "*" --include "Copernicus_DSM_COG_30*/*_DEM.tif" s3://copernicus-dem-90m/ dem-90m \
# process the raw elevation data files... this takes a LONG time and uses around 20 GB of disk (not recoverable)...
  && openmeteo-api download-dem dem-90m \
# remove raw elevation data files...
  && rm -fr dem-90m data/download-dem90
# --------------------
