# Stock Analysis System - Infrastructure as Code

## Project Overview
This project implements a real-time stock analysis system using AWS services, deployed via Infrastructure as Code (Terraform). The system collects real-time stock data, processes it through various technical indicators, makes predictions using machine learning models, and visualizes the results.

## Architecture
![Data Flow Architecture]
- **Data Collection**: ECS/Fargate container fetches real-time stock data from Yahoo Finance API
- **Data Streaming**: AWS Kinesis handles real-time data streaming
- **Processing**: AWS Lambda processes data and calculates technical indicators
- **Prediction**: Amazon SageMaker hosts the prediction model
- **Storage**: DynamoDB stores processed data and predictions
- **Visualization**: Amazon QuickSight provides data visualization

## Infrastructure Components
- **Network Infrastructure**
  - VPC with public and private subnets
  - NAT Gateway for private subnet internet access
  - Security Groups for ECS tasks
  
- **Core Services**
  - Amazon ECS Cluster (Fargate)
  - Kinesis Data Stream
  - Lambda Function
  - DynamoDB Table
  - S3 Bucket
  - SageMaker Endpoint
  - IAM Roles and Policies

## Prerequisites
- AWS Account
- Terraform installed (version >= 1.0)
- AWS CLI configured
- Docker installed (for building ECS container images)
- Python 3.9+

## Repository Structure
```
.
├── README.md
├── network/
│   ├── config.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── services/
│   ├── config.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── kevinw.pem
├── lambda_function.zip
└── ta_lib_layer.zip
```

## Deployment Guide

### 1. Network Infrastructure
```bash
cd network
terraform init
terraform plan
terraform apply
```

### 2. Services Deployment
```bash
cd ../services
terraform init
terraform plan
terraform apply
```

### 3. Post-Deployment Steps
1. Build and push the Docker image for the stock data collector:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPO_URL>
docker build -t stock-data-collector .
docker tag stock-data-collector:latest <ECR_REPO_URL>:latest
docker push <ECR_REPO_URL>:latest
```

2. Upload historical data to S3:
```bash
aws s3 cp tsla_history.csv s3://kevinw-p2/data/
```

3. Train and deploy the SageMaker model using the provided notebook

4. Configure QuickSight dashboard

## Data Storage Schema

### DynamoDB Table Structure
- **Table Name**: stock-table
- **Partition Key**: stock_symbol (String)
- **Sort Key**: timestamp (Number)
- **Attributes**:
  - price (Number)
  - volume (Number)
  - indicator (Map)
  - prediction (String)

## Monitoring and Maintenance

### CloudWatch Logs
- ECS container logs: `/ecs/stock-data-collector`
- Lambda function logs: `/aws/lambda/StockAnalysisLambda`

### Metrics to Monitor
- Kinesis Stream Metrics
  - GetRecords.IteratorAgeMilliseconds
  - WriteProvisionedThroughputExceeded
- Lambda Metrics
  - Duration
  - Errors
  - Throttles
- DynamoDB Metrics
  - ConsumedReadCapacityUnits
  - ConsumedWriteCapacityUnits

## Security Considerations
- All services run within private subnets where possible
- IAM roles follow principle of least privilege
- Data in transit is encrypted using AWS KMS
- S3 bucket has encryption enabled
- Network access is controlled via security groups

## Cost Optimization
- Fargate Spot can be used for ECS tasks
- DynamoDB is configured with on-demand capacity
- Lambda functions are sized appropriately
- CloudWatch logs have retention periods set

## Cleanup
To destroy the infrastructure:
```bash
cd services
terraform destroy

cd ../network
terraform destroy
```

## Contributing
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License
This project is licensed under the MIT License - see the LICENSE file for details

## Contact
- Project Owner: [Your Name]
- Email: [Your Email]

## Acknowledgments
- Yahoo Finance API for providing stock data
- AWS for cloud infrastructure
- Terraform for IaC capabilities