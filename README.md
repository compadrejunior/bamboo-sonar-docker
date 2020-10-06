# bamboo-sonar-docker
Tutorial para instalar e executar o Bamboo Server, Sonarqube e Sonar Scanner em container Docker para um projeto Node.js

## Pré-requisitos
Esse tutorial foi elaborado em um servidor Ubuntu Bionic. Para seguir em outras distros, adapte os comandos usados como por exemplo, apt-get update, apt-get install, etc. 

```bash
Distributor ID: Ubuntu
Description:    Ubuntu 18.04.5 LTS
Release:        18.04
Codename:       bionic
```
## Instalação
1. Instale o docker:
```bash
sudo apt-get udate
sudo apt-get upgrade
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```
2. Crie um volume para o diretório BAMBOO_HOME
Para poder iniciar e parar o container docker sem perder os dados, use um *named volume* no docker. Dessa maneira o container vai usar um diretório compartilhado do host para os dados do Bamboo. 

docker volume create --name bambooVolume

3. Crie a imagem do SonarQube. O SonarQube é o servidor do Sonar para onde os resultados das análises do código serão enviada. 
```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube
```
4. Baixe o sonar-scanner. O Sonar Scanner é o executável que vai realizar a análise do código e enviar para o SonarQube
```bash
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.5.0.2216-linux.zip
```
5. Crie uma pasta local para o Scanner do Sonar. 
```bash
mkdir sonar-scanner
```
6. Descompacte os arquivos de sonar-scanner-cli-4.5.0.2216-linux.zip
```bash
unzip sonar-scanner-cli-4.5.0.2216-linux.zip
```
7. Modifique os arquivos sonar-scanner-cli-4.5.0.2216-linux/bin/sonar-scanner e sonar-scanner-cli-4.5.0.2216-linux/bin/sonar-scanner-debug para serem executáveis.
```bash
chmod +x sonar-scanner-cli-4.5.0.2216-linux/bin/sonar-scanner
chmod +x sonar-scanner-cli-4.5.0.2216-linux/bin/sonar-scanner-debug
```
8. Altere a propriedade sonar.host.url no arquivo sonar-scanner-cli-4.5.0.2216-linux/conf/sonar-scanner.properties para apontar para a URL do servidor do sonar. Veja o exemplo abaixo
```bash
#Configure here general information about the environment, such as SonarQube server connection details for example
#No information about specific project should appear here

#----- Default SonarQube server
sonar.host.url=http://192.106.56.107:9000

#----- Default source code encoding
#sonar.sourceEncoding=UTF-8
```
9. Crie um arquivo de propriedades do sonar dentro da pasta raiz do seu projeto. Esse arquivo deve ser feito o commit e push para o Bitbucket. Exemplo:
```bash
# must be unique in a given SonarQube instance
sonar.projectKey=oat-inside

# --- optional properties ---

# defaults to project key
sonar.projectName=OAT Inside
# defaults to 'not provided'
sonar.projectVersion=1.0
 
# Path is relative to the sonar-project.properties file. Defaults to .
sonar.sources=.
sonar.language=js
sonar.exclusions=/**/node_modules/**, node_modules/** 

# Encoding of the source code. Default is default system encoding
#sonar.sourceEncoding=UTF-8
```
10. Crie um arquivo dockerfile para criar uma imagem personalizada do Bamboo Server já com as capacidades desejadas para o build. 
```bash 
touch dockerfile
```
11. Use um editor de texto no linux para incluir o conteúdo do dockerfile. Veja o exemplo abaixo:
```docker
FROM atlassian/bamboo-server
USER root
COPY /sonar-scanner-cli-4.5.0.2216-linux /opt/sonar-scanner
ENV PATH "$PATH:/opt/sonar-scanner/bin:/opt/java/openjdk/bin"
COPY mysql-connector-java-5.1.49-bin.jar /opt/atlassian/bamboo/lib
RUN apt-get update 
RUN apt-get -y install build-essential
RUN apt-get -y install nodejs
```
12. Crie a imagem do container a partir do Dockerfile. 
```bash
docker build -t atlassian/bamboo-server:sonar .
```
13. Execute o comando abaixo para iniciar o container Docker do Bamboo Server.
```bash
docker run --restart unless-stopped \
-e JVM_MINIMUM_MEMORY=1024m \
-e JVM_MAXIMUM_MEMORY=2048m \
-v bambooVolume:/var/atlassian/application-data/bamboo \
--name="bamboo" \
--init -d -p 54663:54663 -p 8085:8085 \
atlassian/bamboo-server:sonar 
```

## Executando o build no Bamboo.
Agora basta acessar o Bamboo no endereço do servidor, por exemplo, http://192.168.56.107:8085. 
1. Crie um plano de build para o seu repositório Bitbucket ao qual o arquivo do sonar foi inserido. 
2. Inclua uma task de checkout do repositório.
3. Inclua e configure uma task de Sonar Scanner (é necessário o app SonarQube for Bamboo).
4. Execute o build do plano. 
5. Confira o resultado na página do projeto no SonarQube. 