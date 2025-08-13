# Terraform modules

This are some testing terraform modules

* [modules/test](modules/test/README.md)

A testing module to get the account id, vpcs, and a list of all 
subnets in a vpc, and write them to a file `fred.json`. The 
input `force_rewrite` can be change to force the module to 
change state. This is used mainly to test deployments for the 
self-serve project.
