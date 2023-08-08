FROM drmrbrewer/open-meteo:v10
WORKDIR /root

RUN ln /root/openmeteo-api /usr/local/bin/openmeteo-api

RUN apt-get update && apt-get -y install awscli gdal-bin \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=rclone/rclone:latest /usr/local/bin/rclone /usr/local/bin/rclone
COPY rclone.conf /root/.config/rclone/rclone.conf

RUN --mount=type=cache,target=/root/dem-90m,sharing=locked \
  cd /root \
  && rclone sync --progress --transfers 25 --checkers 16 --include '/Copernicus_DSM_COG_30*/*_DEM.tif' s3:copernicus-dem-90m ./dem-90m

RUN --mount=type=cache,target=/root/dem-90m,sharing=locked \
  --mount=type=cache,target=/root/data/download-dem90,sharing=locked \
  cd /root \
  && openmeteo-api download-dem dem-90m --concurrent-conversion-jobs 16 --concurrent-compression-jobs 4

# could delete the /root/Public and /root/Resources folders from this image because they aren't required... only the content of /root/data/omfile-dem90 is required...
# but their size is relatively quite small compared to /root/data/omfile-dem90 so let's not bother...
