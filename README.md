# AWS DevOps Engineer Demo

A containerized Python Flask application deployed on AWS using
Docker, Amazon ECR, Amazon ECS Fargate, Application Load Balancer,
Terraform, AWS IAM, Amazon CloudWatch, and GitHub Actions.

---

## Project Overview

This project demonstrates a complete DevOps workflow:

- Containerize a Python Flask application using Docker
- Store the Docker image in Amazon ECR
- Provision AWS infrastructure using Terraform
- Run the application on Amazon ECS Fargate
- Expose the application through an Application Load Balancer
- Send container logs to Amazon CloudWatch
- Automate build and deployment using GitHub Actions
- Authenticate GitHub Actions with AWS using OIDC

---

## Architecture

```mermaid
flowchart TD
    A[Developer] --> B[GitHub Repository]
    B --> C[GitHub Actions]

    C --> D[AWS OIDC]
    C --> E[Docker Build]
    E --> F[Amazon ECR]

    F --> G[ECS Task Definition]
    G --> H[ECS Fargate Service]
    H --> I[Fargate Task]
    I --> J[Flask Container]

    J --> K[Target Group]
    K --> L[Application Load Balancer]
    L --> M[Internet]

    J --> N[Amazon CloudWatch Logs]
