#Output mediawiki public IP for accessing the URL

output "MediaWiki-Host-PublicIP" {
  value = aws_instance.mediawiki.public_ip
}
