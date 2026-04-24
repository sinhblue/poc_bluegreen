# POC Blue/Green Terraform Deployment

## Files Overview

- **provider.tf** - AWS provider and Terraform backend configuration (S3 state)
- **variables.tf** - Input variables for customization
- **data.tf** - Data sources (Ubuntu 24.04 AMI lookup)
- **security.tf** - Security groups for EC2 and Aurora
- **ec2.tf** - EC2 instance configuration
- **rds.tf** - Aurora cluster, parameter groups, KMS, and IAM resources
- **outputs.tf** - Output values
- **user_data.sh** - EC2 initialization script

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **S3 bucket** named `poc-bluegreen-tfstate` (for Terraform state)
   ```bash
   aws s3api create-bucket --bucket poc-bluegreen-tfstate --region ap-southeast-2
   aws s3api put-bucket-versioning --bucket poc-bluegreen-tfstate --versioning-configuration Status=Enabled
   ```

3. **DynamoDB table** for state locking (optional but recommended)
   ```bash
   aws dynamodb create-table \
     --table-name terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

4. **EC2 Key Pair** named `my-key-pair`
   ```bash
   aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > my-key-pair.pem
   chmod 400 my-key-pair.pem
   ```

5. **AWS CLI** configured with appropriate credentials

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Plan deployment
```bash
terraform plan -out=tfplan
```

### 3. Apply configuration
```bash
terraform apply tfplan
```

### 4. Get outputs
```bash
terraform output terraform_output_summary
```

## Variables

Edit `variables.tf` or pass via command line:
```bash
terraform apply \
  -var="aws_region=ap-southeast-2" \
  -var="db_cluster_identifier=poc-bluegreen" \
  -var="aurora_engine_version=14.17"
```

## Resources Created

1. **EC2 Instance** (t3.medium)
   - Ubuntu 24.04 AMI
   - Connected to specified VPC and subnet
   - Security group allowing SSH (22) and Flask (5000)
   - User data script installs the app and waits for Aurora readiness before starting Flask

2. **Aurora Cluster** (PostgreSQL 14.17)
   - db.r6g.large instance
   - Encrypted with KMS
   - Advanced monitoring with 1-second granularity
   - Performance Insights enabled
   - Automatic backups (7-day retention)
   - High availability with health monitoring

3. **RDS Parameter Groups** (4 total)
   - 2 for PostgreSQL 14 (cluster + instance)
   - 2 for PostgreSQL 15 (cluster + instance)
   - All with logical replication enabled

4. **Security Groups**
   - EC2: Allow SSH (0.0.0.0/0) and port 5000 (0.0.0.0/0)
   - Aurora: Allow PostgreSQL (5432) from EC2 security group

5. **AWS Secrets Manager**
   - Stores Aurora master password
   - Randomly generated 32-character password

6. **KMS Key**
   - For Aurora encryption
   - For performance insights encryption
   - For activity stream encryption

7. **IAM Role**
   - For RDS Enhanced Monitoring

## Security Notes

- ⚠️ **Master password** is auto-generated and stored in AWS Secrets Manager
- ⚠️ **Database password** is NOT stored in Terraform state (only reference to secret)
- ⚠️ **SSH access** is open to 0.0.0.0/0 - restrict in production
- ⚠️ **Flask port 5000** is open to 0.0.0.0/0 - add authentication/WAF in production
- ✅ **Aurora** is encrypted at rest and in transit
- ✅ **Enhanced monitoring** enabled for performance insights
- ✅ **Activity stream** enabled for audit logging

## Connectivity

EC2 instance can connect to Aurora via:
```
DATABASE_URL=postgresql://postgres:password@poc-bluegreen.xxxxx.ap-southeast-2.rds.amazonaws.com:5432/poc_bluegreen
```

Retrieved from Terraform output: `aurora_cluster_endpoint`

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

⚠️ **Note:** Aurora final snapshot will be created before deletion.

## Troubleshooting

### EC2 can't connect to Aurora
- Verify security groups are correctly configured
- Check Aurora security group allows inbound 5432 from EC2 SG
- Verify EC2 and Aurora are in the same VPC

### State lock timeout
- Check if `terraform-locks` DynamoDB table exists and is accessible
- Remove stale locks if needed: `aws dynamodb delete-item --table-name terraform-locks --key '{"LockID":{"S":"poc-bluegreen-tfstate/terraform/state.tfstate"}}'`

### Aurora password retrieval
```bash
aws secretsmanager get-secret-value --secret-id poc-bluegreen-aurora-password --query SecretString --output text | jq -r '.password'
```
