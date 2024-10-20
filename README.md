# AWS Highly Available Photo Album Website

## Project Overview

This project demonstrates how to build a **highly available, scalable, and resilient Photo Album website** using **AWS Cloud Services**. It leverages various AWS resources including EC2, RDS, S3, Lambda, ELB (Elastic Load Balancer), and Auto Scaling to ensure that the web application is highly available, secure, and easily scalable.

The website allows users to upload photos, which are stored in an S3 bucket and are automatically resized using an AWS Lambda function.

## Table of Contents

1. [Project Features](#project-features)
2. [Architecture](#architecture)
3. [Technologies Used](#technologies-used)
4. [Infrastructure Overview](#infrastructure-overview)
5. [Setup Instructions](#setup-instructions)
6. [How to Use](#how-to-use)
7. [Future Improvements](#future-improvements)
8. [Contact](#contact)

## Project Features

- **VPC with Public and Private Subnets**: Ensures network isolation for the resources.
- **Elastic Load Balancer (ELB)**: Distributes incoming traffic to the web servers across multiple availability zones.
- **Auto Scaling Group**: Automatically adjusts the number of web servers based on demand, ensuring high availability.
- **EC2 Instances**: Used for both the web and DevServer, configured with a custom Amazon Machine Image (AMI) to host the PHP-based web application.
- **RDS (MySQL)**: Provides a managed relational database for storing metadata about uploaded photos.
- **S3 Bucket**: Stores uploaded photos, with automatic resizing via a Lambda function.
- **Lambda Function**: Automatically resizes the photos stored in S3.
- **Security Groups and NACL**: Provide security at the instance and subnet levels, enforcing least privilege access.
- **IAM Roles**: Provide secure access between services such as S3 and EC2.

## Architecture

The following diagram describes the high-level architecture of the project:

1. **VPC**: Consists of both public and private subnets across two availability zones.
2. **Elastic Load Balancer (ELB)**: Distributes traffic between multiple EC2 instances running in different availability zones.
3. **EC2 Instances**: Host the PHP-based photo album website, configured with Auto Scaling for high availability.
4. **RDS MySQL**: Stores photo metadata.
5. **S3 Bucket**: Stores uploaded photos.
6. **Lambda Function**: Automatically resizes the uploaded photos.
7. **NAT Gateway**: Allows the private instances to access the internet (e.g., for software updates).
8. **Security Groups/NACL**: Controls traffic in and out of the VPC for added security.

## Technologies Used

- **Amazon Web Services (AWS)**:
  - EC2 (Elastic Compute Cloud)
  - RDS (Relational Database Service)
  - S3 (Simple Storage Service)
  - Lambda (Serverless Functions)
  - ELB (Elastic Load Balancer)
  - VPC (Virtual Private Cloud)
  - IAM (Identity and Access Management)
  - Auto Scaling Group
  - NAT Gateway
  - Security Groups, Network ACLs

- **Infrastructure as Code (IaC)**:
  - Terraform for provisioning and managing AWS resources.

- **Backend Technologies**:
  - **PHP** for the web server.
  - **MySQL** for the database.

- **Frontend**:
  - HTML, CSS for the user interface.

## Infrastructure Overview

### VPC & Subnets
- VPC: **SParoiVPC**
  - Public Subnets: **10.0.1.0/24**, **10.0.2.0/24**
  - Private Subnets: **10.0.3.0/24**, **10.0.4.0/24**

### EC2 Instances
- **DevServer**: Hosts PHP-based web application, from which an AMI is created for the Auto Scaling group.
- **Web Servers**: Created by Auto Scaling, deployed across multiple availability zones for high availability.

### RDS (MySQL)
- **Database Name**: sparoi-db
- **Subnet Group**: Hosts the database instances in private subnets.

### S3 Bucket
- **Bucket Name**: sparoi-bucket
  - Stores the uploaded photos.
  - Integrated with a Lambda function to resize images.

### Lambda Function
- **Function Name**: CreateThumbnail
  - Resizes photos uploaded to the S3 bucket.

### Elastic Load Balancer
- **ELB Name**: Sparoi-ELB
  - Distributes incoming traffic to EC2 instances in the Auto Scaling Group.

### Auto Scaling Group
- **ASG Name**: Sparoi-ASG
  - Manages web server scaling to meet traffic demands.
  
## Setup Instructions

To deploy this infrastructure using Terraform:

1. **Install Terraform**: Ensure Terraform is installed on your machine. You can download it from [Terraform's official website](https://www.terraform.io/downloads).

2. **Clone the Repository**: Clone the repository to your local machine.
   ```bash
   git clone https://github.com/yourusername/aws-photo-album-website.git
   cd aws-photo-album-website
3. **Set Up AWS Credentials**: Make sure you have your AWS credentials configured. You can configure them using the AWS CLI:
   ```bash
   aws configure

### **Initialize Terraform**:
This instruction is also in the **Setup Instructions** section, guiding users to initialize Terraform before applying the configuration.
```md
4. **Initialize Terraform**: Run the following command to initialize Terraform. This downloads the necessary providers and sets up the backend.
   ```bash
   terraform init

### **Apply the Terraform Configuration**:
This part is included after initializing Terraform, explaining how to apply the configuration and provision resources on AWS.
```md
5. **Apply the Terraform Configuration**: Apply the configuration to create all the resources on AWS.
   ```bash
   terraform apply

### **Access the Website**:
This step is clearly explained after applying the Terraform configuration:
```md
6. **Access the Website**: Once the infrastructure is set up, you can access the photo album website using the DNS name provided by the Elastic Load Balancer.

## How to Use

1. **Uploading Photos**: You can upload photos to the website through the photo album interface.
2. **Resizing**: Once uploaded, the Lambda function will automatically resize the images stored in the S3 bucket.
3. **Accessing phpMyAdmin**: The database can be managed through phpMyAdmin, accessible through the public-facing DevServer IP address.

## Future Improvements

- **HTTPS Support**: Add an SSL certificate to secure the website.
- **CI/CD Pipeline**: Implement a continuous integration and delivery (CI/CD) pipeline for automatic deployment of infrastructure changes.
- **Monitoring and Alerts**: Integrate AWS CloudWatch for monitoring server metrics and setting up alerts for critical issues.
