# Infrastructure Automation with Jenkins, Docker, AWS CLI, Kubernetes, and ArgoCD

## Project Description
This project aims to streamline and automate the deployment of infrastructure on the cloud using a combination of powerful DevOps tools. By leveraging Jenkins for continuous integration, Docker for containerization, AWS CLI for managing resources on Amazon Web Services (AWS), Kubernetes for container orchestration, and ArgoCD for GitOps workflows, this project empowers teams to rapidly deploy, scale, and manage cloud infrastructure with efficiency and reliability.

## Features


**Continuous Integration:** Automate the build and testing process with Jenkins pipelines.


**Containerization:** Utilize Docker to package applications and dependencies into lightweight containers.


**Cloud Deployment:** Harness the power of AWS CLI to provision and manage cloud resources on AWS.


**Container Orchestration:** Deploy and manage containerized applications at scale with Kubernetes.


## Getting Started


To get started with this project, follow these steps:



Clone the repository to your local machine.


Install the necessary dependencies: Jenkins, Docker, AWS CLI, Kubernetes.


Configure access to your AWS account and Kubernetes cluster.


Set up Jenkins pipelines for your project.


Define Kubernetes manifests for your infrastructure components.


Trigger the Jenkins pipeline to automate the deployment process.



## Usage


### Clone the repository:


```git clone https://github.com/StavrosZacharia/devops-aws.git```


### Install dependencies locally:
#### NOTE THAT THE DEPENDENCIES ARE LISTED IN THE REQUIRED ORDER TO BE INSTALLED

**Docker**: [Installation Guide](https://docs.docker.com/engine/install/) 
    After installing Docker, use this commands to stop and delete the running "jenkins-blueocean" container:
    ```docker stop jenkins-blueocean```
    ```docker rm jenkins-blueocean```

    Now, run this command to create a container with root privileges, which are needed for the other installations.
    ```
    docker run \
  --name jenkins-blueocean \
  --restart=on-failure \
  --detach \
  --network jenkins \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  --user root \
  myjenkins-blueocean:2.440.2-1
  ```


**Jenkins**: [Installation Guide](https://www.jenkins.io/doc/book/installing/docker/)
    1. When unlocking Jenkins, as per the guide above, select "Install suggested plugins". 
    2. Navigate to localhost:8080 and on the left sidebar click "Manage Jenkins" then on the next page under "System Configuration", click "Plugins".
    3. On the left sidebar click "Available plugins" and install the following plugins if not already installed:
        i. Amazon ECR plugin
        ii. Docker API
        iii. Docker Commons Plugin
        iv. Docker plugin
        v. Yet Another Docker Plugin
        vi. Git plugin
        vii. Git server

### This dependency needs to be installed on both local as well as the docker container created above


**AWS CLI**: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)


**Note that the jenkins container is running on Linux x86**


#### To install inside the container:
    If you followed the steps from the Docker installation guide, use the below command to access the terminal of the container.
    ```docker container exec -it jenkins-blueocean bash```
    
    Follow the instructions in the installation guide.


## Acknowledgments


[Jenkins](https://www.jenkins.io/)


[Docker](https://www.docker.com/)


[AWS CLI](https://aws.amazon.com/cli/)


[Kubernetes](https://kubernetes.io/)
