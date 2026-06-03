project     = "aws-lakehouse"
environment = "dev"
region      = "eu-central-1"

vpc_cidr_block  = "10.10.0.0/16"
public_subnets  = ["10.10.0.0/19", "10.10.96.0/19"]
private_subnets = ["10.10.32.0/19", "10.10.64.0/19"]
save_vpc_cost   = false

force_destroy_bucket = true
bucket_versioning    = "Disabled"

create_emr_cluster       = true
emr_master_instance_type = "m5.xlarge"
emr_core_instance_type   = "m5.xlarge"
emr_core_instance_count  = 1