# Set the S3 bucket name and local download path
$bucketName = "your-s3-bucket-name"
$localDownloadPath = "C:\path\to\download\latest-file.zip"

# Get the list of files in the bucket, sorted by last modified date
$files = aws s3api list-objects-v2 --bucket $bucketName --query "reverse(sort_by(Contents, &LastModified))" | ConvertFrom-Json

# Check if there are any files in the bucket
if ($files.Count -eq 0) {
    Write-Host "No files found in the bucket."
    exit
}

# Get the key of the latest file
$latestFileKey = $files[0].Key

# Download the latest file
$downloadCommand = "aws s3 cp s3://$bucketName/$latestFileKey $localDownloadPath"
Invoke-Expression $downloadCommand

Write-Host "Latest file downloaded: $latestFileKey"
