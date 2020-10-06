docker pull atlassian/bamboo-agent-base
docker volume create --name bambooAgentVolume
docker run --restart unless-stopped -v bambooAgentVolume:/home/bamboo/bamboo-agent-home --name="bambooAgent" --init -d atlassian/bamboo-agent-base http://192.168.56.107:8085