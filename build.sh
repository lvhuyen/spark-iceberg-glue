docker build -t lvhuyen/spark_iceberg_glue:3.3-0.14-0 --push .
docker buildx build --platform linux/amd64,linux/arm64 -t lvhuyen/spark_iceberg_glue:3.3-0.14-0 --push .

