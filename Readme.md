Change into the project directory:![Screenshot from 2023-04-19 15-35-06](https://user-images.githubusercontent.com/70139300/233110820-b9d3c0f4-afa6-44a7-818a-e0f9b2b0eb1f.png)



Clone this repository:
git clone https://github.com/devbarham/Terraform1.git
cd terraform-one

Create a terraform.tfvars file to define your variables:
region = "us-east-1"
key_name = "your-keypair-name"
public_key = "your public key" // Note this should be store as a secret for better security.
Initialize the Terraform project:
terraform init -backend-config="bucket=<s3_bucket_name>"

Preview the changes that Terraform will make:
terraform plan --var-file="terraform.tfvars"

Apply the changes to create the resources:
terraform apply --var-file="terraform.tfvars"

When you're finished with the resources, destroy them:
terraform destroy --var-file="terraform.tfvars"


Variables
The following variables can be defined in your terraform.tfvars file:

Variable	Description	Type
access_key	AWS access key	string
secret_key	AWS secret key	string
region	AWS region where resources will be created	string
key_name	Name of an existing key pair in your AWS account	string
public_key	Your generated pub key with ssh-keygen	string
If you have any further clarification, kindly reach out to me with the below information.

Author
Saheed Ibrahim Damilare
Twitter: @king__barham
