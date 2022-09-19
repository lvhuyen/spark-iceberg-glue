mvn -f spark_dependencies/pom.xml dependency:copy-dependencies -DoutputDirectory=jars

docker buildx build --platform linux/amd64 -t lvhuyen/spark_iceberg_glue:3.3.0-0.14.1-0-slim -f Dockerfile_slim --push .
docker buildx build --platform linux/amd64,linux/arm64 -t lvhuyen/spark_iceberg_glue:3.3.0-0.14.1-0 --push .
