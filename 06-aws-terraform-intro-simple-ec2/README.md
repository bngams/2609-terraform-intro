# AWS Terraform Intro — Simple EC2

A minimal Terraform example that launches a single EC2 instance (**t3.micro**) in
the default VPC, with a security group allowing SSH (22) and HTTP (80).

## Resources created

- `data.aws_vpc.default` — looks up the account's default VPC
- `aws_security_group.ec2_sg` — inbound SSH + HTTP, all outbound
- `aws_instance.simple_ec2` — the EC2 instance

The SSH key pair (`aleion-tf-2609`) already exists in AWS and is referenced by
name via `var.key_name` — Terraform does **not** create it.

## AMIs

| AMI | Architecture | Compatible instance type |
|-----|-------------|--------------------------|
| `ami-06121aa3085b6f918` | 64-bit x86 (uefi-preferred) | `t3.micro` *(default)* |
| `ami-03748c04dc81412c6` | 64-bit Arm (uefi) | `t4g.micro` |

> The default AMI is x86 and pairs with `t3.micro`. To use the Arm AMI, override
> **both** the AMI and the instance type:
> ```bash
> terraform apply -var="ami_id=ami-03748c04dc81412c6" -var="instance_type=t4g.micro"
> ```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Credentials are read from `aws.auto.tfvars` (loaded automatically).

## Connect over SSH

After `apply`, Terraform prints an `ssh_command` output. The `.pem` private key
lives in your `~/Downloads` folder:

```bash
chmod 600 ~/Downloads/aleion-tf-2609.pem
ssh -i ~/Downloads/aleion-tf-2609.pem ec2-user@<public_ip>
```

> Default user is `ec2-user` for Amazon Linux. Use `ubuntu` for Ubuntu AMIs.

## Cleanup

```bash
terraform destroy
```
