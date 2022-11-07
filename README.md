# terraform-sample

## Setup

1. You need aws user account which has permission to operate necessary aws resource.
2. Keep both secret key and access key.
3. [Subscribe Kali Linux on AWS Marketplace](https://aws.amazon.com/marketplace/server/procurement?productId=8b7fdfe3-8cd5-43cc-8e5e-4e0e7f4139d5)
4. Change a part of `main.tf`

```terraform
...
# EC2
resource "aws_instance" "htbkali_ec2" {
  ami = <Your AMI>
  ...
}
...
```

5. Execute commands below.

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
$ terraform plan
$ terraform apply

$ ssh -i ./terraform-htbkali-keypair.id_rsa kali@[ip-address]
```

## More Information

Reference1: [offensive-terraform / terraform-aws-ec2-kali-linux](https://github.com/offensive-terraform/terraform-aws-ec2-kali-linux)
Reference2: [AWS環境にKali Linuxを建てて遊ぶ方法](https://chikoblog.hatenablog.jp/entry/2020/12/07/112518)
