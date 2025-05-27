output "instance_public_dns" {
  value       = aws_instance.public_instance.public_dns
  description = "The EC2 instance public DNS"
}

output "ecr_repo_url" {
  value       = aws_ecr_repository.flak.repository_url
  description = "The URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)"
}
