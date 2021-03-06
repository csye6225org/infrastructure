# Infrastructure

### Tech Stack
```
1. Amazon Web Services
2. Hashicorp Terraform
```
# Assignment 8: Some Important Commands

1. Command to import ssl certificate (Certificate, CA bundle, Unencrypted private key) to AWS Certificate Manager

```
export AWS_PROFILE=prod

aws acm import-certificate --certificate fileb://prod_varaddesai_me.crt \
      --certificate-chain fileb://prod_varaddesai_me.ca-bundle \
      --private-key fileb://domain_ssl_unencrypted_pk.key
```

2. Command to generate CSR for ssl activation (used password to encrypt private key)

```
openssl req -newkey rsa:2048 -keyout domain_ssl_pk.key -out domain_ssl_csr.csr
```

3. Move to correct file location

```
cd /home/varad/Desktop/NSC/ssl_cert_files/prod_varaddesai.me
```

4. Command to decrypt private key with password

```
openssl rsa -in domain_ssl_pk.key -out domain_ssl_unencrypted_pk.key
```



# Assignment 2: How to Demo?

### 1. Git Demo:

1. Create pull requests between
```
1. Main branch of organization and assignment branch of fork.
2. Main branch of organization and main branch of fork.
3. Main branch of fork and assignment branch of fork.
```
There should be nothing to compare.

2.  TAs and instructors are collaborators to the GitHub repository.
```
https://github.com/orgs/csye6225org/people
```
3. Show case README.md file
```
https://github.com/csye6225org/infrastructure
```
4. Git Repository Content Check

```
https://github.com/csye6225org/infrastructure/blob/main/.gitignore
```
5. Show case that repository is cloned correctly.
   Execute the following commands in terminal.
```
# cd /home/varad/Desktop/NSC
# cd Github/infrastructure
# git remote -v
```

### 2. Demo AWS cleanliness:

1. Login to AWS prod account
```
https://signin.aws.amazon.com
```
2. Go to VPC
3. Show that there are no VPCs

### 3. Demo Infrastructure using Terraform:

1. Go to your infrastructure local repository, main branch.

```
# cd /home/varad/Desktop/NSC/Github/infrastructure && git checkout main
```

2. Check contents of terraform.tfvars
```
# cat terraform.tfvars
```

3. Set AWS profile to interact with prod account
```
# export AWS_PROFILE=prod
```

4. Check infrastructre that will get created
```
# terraform plan
```
5. Execute infrastructure creation
```
# terraform apply
```
6. Show the infrastructre in AWS prod account
<br><br>
7. Clone infrastructure repository second time locally.
```
# cd /home/varad/Desktop/NSC/Github && mkdir demoinfra && cd demoinfra
# git clone git@github.com:csye6225org/infrastructure.git
# cd infrastructure

```
8. Copy terraform.tfvars file from previous clone to this clone
```
# cp ../../infrastructure/terraform.tfvars .
```
9. Change the CIDR blocks so that they don't overlap with first VPC and subnets from first Infrastructure.
<br>
Use contents from the following file.
<br>

```
# cat /home/varad/Desktop/NSC/Github/helper/unique1.tfvars
```

10. Initialize terraform in the new clone
```
# terraform init
```

11. Format terraform files
```
# terraform fmt
```

12. Check infrastructre that will get created
```
# terraform plan
```

13. Execute infrastructure creation
```
# terraform apply
```

14. Show the second infrastructre in AWS prod account
<br><br>

15. Destroy first infrastructure
```
# cd /home/varad/Desktop/NSC/Github/infrastructure/
# terraform destroy
```

16. Destroy second infrastructure
```
# cd /home/varad/Desktop/NSC/Github/demoinfra/infrastructure/
# terraform destroy
```

17.  Unset AWS profile and Cleanup 
```
# export AWS_PROFILE=
# rm -rf /home/varad/Desktop/NSC/Github/demoinfra/
```
...


