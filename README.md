# CI/CD Python Flask App on AWS

This repository contains a simple Python Flask application, containerized with Docker, and deployed on AWS using Terraform infrastructure and a Jenkins-based CI/CD pipeline.

---

## Project Overview

This project demonstrates how to build and deploy a containerized Python Flask application on AWS with an automated CI/CD workflow using Jenkins. The infrastructure is provisioned with Terraform and includes:

- A VPC with public subnet and internet gateway
- An EC2 instance running Amazon Linux 2023 with Docker installed
- AWS Elastic Container Registry (ECR) to store Docker images
- IAM roles and security groups configured for secure access
- Jenkins pipeline automating code deployment from source to running container on EC2

The Flask app serves a simple "Hello World" page and can be used as a foundation for learning DevOps practices involving AWS, Docker, Terraform, and Jenkins.

---

## Repository Structure

```bash
.
├── Dockerfile
├── Jenkinsfile
├── src
│   ├── main.py
│   └── requirements.txt
└── terraform
    ├── main.tf
    ├── outputs.tf
    └── variables.tf
```

---

## Prerequisites

- AWS account with permissions to provision EC2, VPC, IAM, and ECR resources
- Terraform installed locally or in your CI environment
- Jenkins server with AWS CLI and Docker installed, configured with credentials:
  - `aws-credentials` for AWS access
  - `devops-linux-private-key` for SSH access to EC2 instance
- Docker installed on local machine for building/testing images (optional)

---

## Setup and Deployment

### 1. Terraform Infrastructure Provisioning

Configure your AWS region, VPC CIDR block, instance type, and SSH public key in `terraform/terraform.tfvars`.

```hcl
region         = "us-east-1"
vpc_cidr       = "10.0.0.0/16"
instance_type  = "t2.micro"
public_key_file = "~/.ssh/id_rsa.pub"
```
Initialize and apply Terraform:

```bash
cd terraform
terraform init
terraform apply
```

This will provision the VPC, public subnet, security groups, EC2 instance, IAM roles, and ECR repository.

### 2. Jenkins Pipeline
The Jenkinsfile automates:
- Retrieving the EC2 public IP and ECR repo URI
- Copying the source code and Dockerfile to the EC2 instance via SCP
- Building the Docker image on EC2 and tagging it with the Jenkins build number
- Logging into AWS ECR and pushing the Docker image
- Running the Flask app Docker container on EC2, mapping container port 5000 to host port 80
- Make sure your Jenkins credentials are correctly configured:
  - aws-credentials for AWS CLI access
  - devops-linux-private-key for SSH access to the EC2 instance

---

## Usage
Once the pipeline completes successfully, the Flask app will be accessible via the public IP of the EC2 instance on port 80:

```cpp
http://<EC2-PUBLIC-IP>/
```

You should see:
```html
<h1>Hello World</h1>
<p>I hope you enjoyed it, follow for more content around DevOps.</p>
```

---

## Technologies Used
- Python and Flask — for the web application
- Docker — containerization of the app
- Terraform — infrastructure as code for AWS resources
- AWS — EC2, VPC, IAM, ECR
- Jenkins — CI/CD automation pipeline

---

## Notes & Recommendations
- The Flask app runs in debug mode (debug=True), which is suitable for development. For production, consider disabling debug and adding more robust error handling.
- The Terraform setup uses a public subnet and exposes the EC2 instance to the internet with SSH and HTTP access; consider adding additional security layers (e.g., bastion host, private subnets) for production.
- The Jenkins pipeline runs Docker commands on the EC2 instance via SSH, which requires that Jenkins has SSH access and proper credentials configured.
- Extend this setup with automated testing, monitoring, and multi-environment deployments as next steps.