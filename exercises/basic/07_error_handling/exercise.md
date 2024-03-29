# Exercise #7: Error Handling, Troubleshooting

We'll take some time to look at what the different types of errors we discussed look like. In each part of this exercise you'll get a feel for some common error scenarios and how to fix or address them.

## Process Errors

So, as mentioned, process errors are really about just something problematic in way that terraform is being run. So, what happens when you run `apply` before `init`? Let's run apply here before init:

```bash
terraform apply
```

You should see something like:

```text
Error: Could not satisfy plugin requirements


Plugin reinitialization required. Please run "terraform init".

Plugins are external binaries that Terraform uses to access and manipulate
resources. The configuration provided requires plugins which can't be located,
don't satisfy the version constraints, or are otherwise incompatible.

Terraform automatically discovers provider requirements from your
configuration, including providers used in child modules. To see the
requirements and constraints from each module, run "terraform providers".



Error: provider.aws: no suitable version installed
  version requirements: "~> 2.0"
  versions installed: none
```

One of `init`'s jobs is to ensure that dependencies like providers, modules, etc. are pulled in and available locally within your project directory. If we don't run `init` first, none of our other terraform operations have all the requirements they need to do their job.

How about another process error example, the apply command has an argument that will tell it to never prompt you for input variables: `-input=[true|false]`. By default, it's true, but we could try running apply with it set to false.

```bash
terraform init
unset TF_VAR_student_alias
terraform apply -input=false
```

Which should give you something like:

```text
Error: No value for required variable

  on variables.tf line 4:
   4: variable "student_alias" {

The root module input variable "student_alias" is not set, and has no default
value. Use a -var or -var-file command line argument to provide a value for
this variable.
```

### Syntactical Errors

Let's modify the `main.tf` file here to include something invalid. At the end of the file, add this:

```hcl
resource "aws_s3_bucket_object" "an_invalid_resource_definition" {
```

Clearly a syntax problem, so let's run

```bash
terraform plan
```

And you should see something like

```text
Error: Argument or block definition required

  on main.tf line 17, in resource "aws_s3_bucket_object" "an_invalid_resource_definition":
  17:

An argument or block definition is required here.
```

Here, we're just getting used to what things look like depending on our type of error encountered. These syntax errors happen early in the processing of terraform commands.

### Validation Errors

This one might not be as clear to the eye as the syntax problem above. Let's pass something invalid to the AWS provider by setting a property that doesn't exist according to the `aws_s3_bucket_object` resource as defined in the AWS provider. Let's modify the syntax problem above slightly, so change your resource definition to be:

```hcl
resource "aws_s3_bucket_object" "an_invalid_resource_definition" {
  key     = "student.alias"
  content = "This bucket is reserved for ${var.student_alias}"
}
```

Nothing seemingly wrong with the above when looking at it, unless you know that the `bucket` property is a required one on this type of resource. So, let's see what terraform tells us about this:

```bash
terraform validate
```

First, here we see the `terraform validate` command at work. We could just as easily do a `terraform plan` and get a similar result. Two benefits of validate:

* It allows validation of things without having to worry about everything we would in the normal process of plan or apply. For example, variables don't need to be set.
* Related to the above, it's a good tool to consider for a continuous integration and/or delivery/deployment pipeline. Failing fast is an important part of any validation or testing tool.

If you were to have run `terraform plan` here, you would've still been prompted for the `student_alias` value (assuming of course you haven't set it in otherwise).

Having run `terraform validate` you should see immediately something like the following:

```text
Error: Missing required argument

  on main.tf line 17, in resource "aws_s3_bucket_object" "an_invalid_resource_definition":
  17: resource "aws_s3_bucket_object" "an_invalid_resource_definition" {

The argument "bucket" is required, but no definition was found.
```

So, our provider is actually giving us this. The AWS provider defines what a `aws_s3_bucket_object` should include, and what is required. The `bucket` property is required, so it's tell us we have a problem with this resource definition.

### Provider Errors or Pass-through

And now to the most frustrating ones! These may be random, intermittent. They will be very specific to the provider and problems that happen when actually trying to do the work of setting up or maintaining your resources. In short, they happen on the infrastructure API side, e.g. a problem on the AWS side either be it a usage problem on your part, or a problem with AWS itself.

Let's take a look at a simple example. Modify the invalid resource we've been working with here in `main.tf` to now be:

```hcl
resource "aws_s3_bucket_object" "a_resource_that_will_fail" {
  bucket  = "a-bucket-that-doesnt-exist-or-i-dont-own"
  key     = "file"
  content = "This will never exist"
}
```

Then run

```bash
terraform apply
```

And you should see something like:

```bash
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_key_pair.my_key_pair will be created
  + resource "aws_key_pair" "my_key_pair" {
      + fingerprint = (known after apply)
      + id          = (known after apply)
      + key_name    = "rockholla-di-force"
      + key_pair_id = (known after apply)
      + public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 force+di@rockholla.org"
    }

  # aws_s3_bucket_object.a_resource_that_will_fail will be created
  + resource "aws_s3_bucket_object" "a_resource_that_will_fail" {
      + acl                    = "private"
      + bucket                 = "a-bucket-that-doesnt-exist-or-i-dont-own"
      + content                = "This will never exist"
      + content_type           = (known after apply)
      + etag                   = (known after apply)
      + force_destroy          = false
      + id                     = (known after apply)
      + key                    = "file"
      + server_side_encryption = (known after apply)
      + storage_class          = (known after apply)
      + version_id             = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_key_pair.my_key_pair: Creating...
aws_s3_bucket_object.a_resource_that_will_fail: Creating...
aws_key_pair.my_key_pair: Creation complete after 1s [id=rockholla-di-force]

Error: Error putting object in S3 bucket (a-bucket-that-doesnt-exist-or-i-dont-own): NoSuchBucket: The specified bucket does not exist
    status code: 404, request id: B2D0563D9BBE5E53, host id: I5Fs207kx9mlshGs6IAsKu0y3y3Dp/qIssf8REoK8rM6uvVV8CugYfg596HhG3m4liDn/IPuzOM=

  on main.tf line 16, in resource "aws_s3_bucket_object" "a_resource_that_will_fail":
  16: resource "aws_s3_bucket_object" "a_resource_that_will_fail" {
```

Where is this error actually coming from? In this case, it's the AWS S3 API. It's trying to put an object to a bucket that doesn't exist. Terraform is making the related API call to try and create the object, but AWS can't do it because the bucket in which we're trying to put the object either doesn't exist or we don't own it, so we get this error passed back to us.

One other thing worth noting: did it all fail?

```text
aws_key_pair.my_key_pair: Creating...
aws_s3_bucket_object.a_resource_that_will_fail: Creating...
aws_key_pair.my_key_pair: Creation complete after 1s [id=rockholla-di-force]

Error: Error putting object in S3 bucket (a-bucket-that-doesnt-exist-or-i-dont-own): NoSuchBucket: The specified bucket does not exist
    status code: 404, request id: B2D0563D9BBE5E53, host id: I5Fs207kx9mlshGs6IAsKu0y3y3Dp/qIssf8REoK8rM6uvVV8CugYfg596HhG3m4liDn/IPuzOM=

  on main.tf line 16, in resource "aws_s3_bucket_object" "a_resource_that_will_fail":
  16: resource "aws_s3_bucket_object" "a_resource_that_will_fail" {
```

Nope, our key pair that was valid and successful got created, only the bucket object resource failed. Terraform will complete what it can and fail only on what it can't do. In this way, sometimes the solution to failures can sometimes just be running the same Terraform multiple times. For example, if there's a network issue between where you're running terraform and AWS.

### Finishing this exercise

First, remove the offending HCL now in `main.tf`

```terraform
resource "aws_s3_bucket_object" "a_resource_that_will_fail" {
  bucket  = "a-bucket-that-doesnt-exist-or-i-dont-own"
  key     = "file"
  content = "This will never exist"
}
```

And then

```bash
terraform destroy
```
