docker pull atlassian/bamboo-server
docker volume create --name bambooVolume
docker run --restart unless-stopped \
-e JVM_MINIMUM_MEMORY=1024m \
-e JVM_MAXIMUM_MEMORY=2048m \
-v bambooVolume:/var/atlassian/application-data/bamboo \
--name="bamboo" \
--init -d -p 54663:54663 -p 8085:8085 \
atlassian/bamboo-server:sonar 