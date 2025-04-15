module "network" {
    source = "../modules"
    vpc_cidr = "10.0.0.0/16"
    project_name = "class"
    az         = module.network.az
}