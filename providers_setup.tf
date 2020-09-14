#Defining multiple providers using "alias" parameter
provider "aws" {
  profile = var.profile
  region  = var.mediawiki-node
  alias   = "mediawiki-node"
}

