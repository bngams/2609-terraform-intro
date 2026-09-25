# AWS Terraform Introduction

This project demonstrates hosting a static website on AWS S3 using Terraform.

## Resources Created

- S3 bucket configured as a static website
- Public access configuration
- Bucket policy for public read access
- Static HTML files (index.html, error.html)

## Terraform Backend Configuration with AWS

### Backend Configuration vs Provider Configuration

#### Backend Configuration (Remote State Storage)

The backend block in [providers.tf](providers.tf#L5-L9) configures where Terraform stores its state file:

```hcl
terraform {
  backend "s3" {
    bucket = "aelion-2603-borisn"
    key    = "05-aws-terraform-intro/terraform.tfstate"
    region = "eu-west-3"
  }
}
```

**Key characteristics:**
- **No variables allowed**: Backend configuration cannot use Terraform variables (`var.*`)
- **Uses AWS CLI credentials**: Authenticates using local AWS credentials from:
  - `~/.aws/credentials` (credential file)
  - `~/.aws/config` (config file)
  - Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
  - IAM roles (when running on EC2/ECS)
- **Purpose**: Store and manage Terraform state remotely for team collaboration
- **Loaded early**: Backend is initialized before variables are evaluated

#### Provider Configuration (Resource Management)

The provider block in [providers.tf](providers.tf#L19-L24) configures how Terraform manages AWS resources:

```hcl
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```

**Key characteristics:**
- **Variables allowed**: Can use Terraform variables for flexibility
- **Multiple authentication options**:
  - Explicit credentials (as shown above)
  - AWS CLI credentials (same as backend)
  - Environment variables
  - IAM roles
- **Purpose**: Authenticate and interact with AWS APIs to create/manage resources
- **Loaded after**: Provider is configured after variables are evaluated

### Authentication Strategies

#### Option 1: AWS CLI Credentials (Recommended)

Configure AWS CLI once and both backend and provider use it automatically:

```bash
aws configure
```

**Backend:**
```hcl
backend "s3" {
  bucket = "my-bucket"
  key    = "terraform.tfstate"
  region = "eu-west-3"
}
```

**Provider:**
```hcl
provider "aws" {
  region = var.aws_region
  # access_key and secret_key not needed - uses AWS CLI config
}
```

#### Option 2: Separate Credentials

Use AWS CLI for backend, variables for provider:

**Backend:** Uses `~/.aws/credentials`

**Provider:** Uses variables (from `terraform.tfvars` or environment variables)
```hcl
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```

#### Option 3: Environment Variables

Set environment variables for both:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-west-3"
```

Both backend and provider will use these automatically.

### Best Practices

1. **Use AWS CLI credentials** for local development (simplest approach)
2. **Use IAM roles** for CI/CD pipelines and production environments
3. **Never commit credentials** to version control
4. **Backend cannot use variables** - hardcode values or use `-backend-config` flag:
   ```bash
   terraform init -backend-config="bucket=my-bucket"
   ```
5. **Provider credentials are optional** if AWS CLI is configured

### Summary Table

| Aspect | Backend Config | Provider Config |
|--------|---------------|-----------------|
| Variables allowed | ❌ No | ✅ Yes |
| AWS CLI credentials | ✅ Yes | ✅ Yes |
| Environment variables | ✅ Yes | ✅ Yes |
| Explicit credentials | ❌ No (must use `-backend-config`) | ✅ Yes |
| Purpose | State storage | Resource management |
| Initialization | Early (before vars) | Later (after vars) |

## Usage

1. Configure your AWS credentials (see authentication strategies above)
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review the plan:
   ```bash
   terraform plan
   ```
4. Apply the configuration:
   ```bash
   terraform apply
   ```
