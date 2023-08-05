# this image is built from my fork of the open-meteo repo:
#   https://github.com/drmrbrewer/open-meteo
#   https://hub.docker.com/r/drmrbrewer/open-meteo
FROM drmrbrewer/open-meteo:v6
WORKDIR /root

# make the openmeteo-api command (from the open-meteo image above) accessible from anywhere...
RUN ln /root/openmeteo-api /usr/local/bin/openmeteo-api

# install aws and gdal (for fetching and processing the elevation data)...
# https://github.com/open-meteo/open-meteo/blob/main/docs/getting-started.md#digital-elevation-model
RUN apt-get update && apt-get -y install awscli gdal-bin \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# the cronjobs will download and process the weather data files on a schedule, because of course the weather data is constantly changing...
# run the following commands to download and process the elevation files separately, which is a one-off process:
# https://github.com/open-meteo/open-meteo/blob/main/docs/getting-started.md#digital-elevation-model
RUN --mount=type=cache,target=/root/dem-90m,sharing=locked \
  --mount=type=cache,target=/root/data/download-dem90,sharing=locked \
  cd /root \
# download the raw elevation data files...
# the following needs around 40GB of spare disk... though this is recovered later by removing the raw data files...
# && aws s3 sync --no-sign-request --exclude "*" --include "Copernicus_DSM_COG_30*/*_DEM.tif" s3://copernicus-dem-90m/ dem-90m \
  && aws s3 sync --no-sign-request --exclude "*" --include "Copernicus_DSM_COG_30*/*_DEM.tif" --delete s3://copernicus-dem-90m/ dem-90m \
# process the raw elevation data files... this takes a long time and uses around 20 GB of disk (not recoverable)...
  && openmeteo-api download-dem dem-90m
# remove raw elevation data files that are now surplus to requirements...
#  && rm -fr dem-90m data/download-dem90
