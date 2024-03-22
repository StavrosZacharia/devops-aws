# Infrastructure Automation with Jenkins, Docker, AWS CLI, Kubernetes, and Terraform

## Project Description
This project aims to streamline and automate the deployment of infrastructure on the cloud using a combination of powerful DevOps tools. By leveraging Jenkins for continuous integration, Docker for containerization, AWS CLI for managing resources on Amazon Web Services (AWS), Kubernetes for container orchestration, and Terraform for infrastructure automation, this project enables teams to quickly deploy, scale, and manage cloud infrastructure.

## Features


**Continuous Integration:** Automate the build and testing process with Jenkins pipelines.


**Containerization:** Utilize Docker to package applications and dependencies into lightweight containers.


**Cloud Deployment:** Harness the power of AWS CLI to provision and manage cloud resources on AWS.


**Container Orchestration:** Deploy and manage containerized applications at scale with Kubernetes.


## Getting Started


To get started with this project, follow these steps:



Clone the repository to your local machine.


Install the necessary dependencies: Jenkins, Docker, AWS CLI, Terraform, Kubernetes.


Configure access to your AWS account and Kubernetes cluster.


Set up Jenkins pipelines for your project.


Define Kubernetes manifests for your infrastructure components.


Trigger the Jenkins pipeline to automate the deployment process.



## Usage


### Clone the repository:


```bash
git clone https://github.com/StavrosZacharia/devops-aws.git
```


### Install dependencies locally:
#### NOTE THAT THE DEPENDENCIES ARE LISTED IN THE REQUIRED ORDER TO BE INSTALLED


**Docker**: [Installation Guide](https://docs.docker.com/engine/install/) 


After installing Docker, use these commands to stop and delete the running "jenkins-blueocean" container:

    
```bash
docker stop jenkins-blueocean
docker rm jenkins-blueocean
```

 

Now, run this command to create a container with root privileges, which are needed for the other installations.

    
```bash
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

### These dependencies need to be installed on both local as well as the docker container created above


**Terraform**: [Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)


**AWS CLI**: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)


**Note that the jenkins container is running on Linux x86**


#### To install inside the container:
If you followed the steps from the Docker installation guide, use the below command to access the terminal of the container.


```bash
docker container exec -it jenkins-blueocean bash
```
    
Follow the instructions in the installation guides.

## Setting up and building the project


#### NOTE THAT THE SETUP STEPS ARE LISTED IN THE ORDER THEY NEED TO BE EXECUTED WITH


### Amazon Web Services (AWS)


Note: I could provide my personal credentials through an Access Key for AWS, but that would pose a high security risk towards my account and the billing regarding any use of services.

#### If you do not have an AWS account:


1. Go to the [AWS Registration page.](https://portal.aws.amazon.com/billing/signup#/start/email)

2. Provide the required details in the page, and verify using the email.

3. Create a password. (**Note that this password is for a user with full access to everything in AWS**)

4. Fill in your personal details on the next page and tick the box regarding the terms and conditions, make sure to select "Personal" on the "How do you plan to use AWS?" question.

5. Enter a payment method.

6. Enter a verification method using a phone number.

7. Use the code sent to you on the next page.

8. Select "Basic support" and click "Sign up"

9. When redirected, click to go to the management console.

10. Follow the steps listed below, for people that already had an AWS account.

#### If you created, or have an AWS account:

1. Sign in with your AWS credentials.

2. On the top search bar, type "IAM" and click the first result.

3. Click "Create User".

4. Provide a name for the user, check the box of "Provide user access to the AWS Management Console - optional", select "I want to create an IAM user", untick the "Users must create a new password" and click "Next".

5. Select "Attach policies directly" and from the permission policies below, tick only the "AdministratorAccess" and click "Next" and on the next page click "Create user".

6. Save the user name and password, or download them as a .csv file, then click "Return to users list".

7. Click on the name of the user you created, then navigate to "Security credentials" and click "Create access key".

8. Select the "Command Line Interface (CLI)" option, tick the box of confirmation and click "Next".

9. In the description tag, we can leave it empty but it is recommended to include here where the key is used. In this case "local-jenkins" would be fitting. Click "Create access key".

**NOTE: the secret access key is only available once. if you navigate out of this page without getting it, or if you lose it, you will need to follow the access key procedure again.** 

10. Copy and save the values of the "Access key" and the "Secret access key".

11. On your local machine, navigate to the home directory and open the folder ".aws".

12. Create (if it does not already exist) a file named "credentials" with no extension.

13. Insert into this file the Access key and Secret access key in this format:

   [default]

   aws_access_key_id = AccessKeyValue
   
   aws_secret_access_key = SecretAccessKeyValue

14. Save the file.

### Local Terraform


1. Navigate to the directory of the cloned repository and into the folder named "infra". 


   e.g. ```cd devops-aws/infra```


2. Run the command ```terraform init```


## Acknowledgments


[Terraform](https://www.terraform.io/)


[Jenkins](https://www.jenkins.io/)


[Docker](https://www.docker.com/)


[AWS CLI](https://aws.amazon.com/cli/)


[Kubernetes](https://kubernetes.io/)
