# terraform-aws-ssl-certificate

# TODO
- lambda to update (re-import) the acm cert triggered by the sns notification


# Use Cases

1. Create a Secret with LetsEncrypt generated certificate and import into ACM
2. Create a import Certificate files into a Secret, then import into ACM
3. Use an existing Secret to retrieve Certificate files from and import into ACM
4. Just create an AWS managed Certificate via ACM, results in not having a Private Key


