# terraform-sample

## Setup

1. You need aws user account which has permission to operate necessary aws resource.
2. Keep both secret key and access key.
3. Execute commands below.

```bash
$ vagrant up
$ vagrant ssh

$ aws configure
AWS Access Key ID [None]: [aws_user_access_key]
AWS Secret Access Key [None]: [aws_user_secret_key]
Default region name [None]: ap-north-east
Default output format [None]: [Enter]

$ cd tf/
$ terraform init
$ terraform apply

$ chmod 400 ./terraform-handson-keypair.id_rsa
$ ssh -p 22 ec2-user@[ip-address] -i ./terraform-handson-keypair.id_rsa
```

## More Information

### AWS CLI

* `aws configure list`

### Terraform

* `terraform state list`
* `terraform validate`
* `terraform plan`
* `terraform show`
* `terraform import`
* `terraform plan -destroy`
* `terraform destroy`
