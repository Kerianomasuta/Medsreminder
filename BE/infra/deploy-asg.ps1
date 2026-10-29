param(
  [Parameter(Mandatory = $true)][string]$AmiId,
  [Parameter(Mandatory = $true)][string]$VpcId,
  [Parameter(Mandatory = $true)][string]$SubnetIds,
  [Parameter(Mandatory = $true)][string]$KeyName,
  [string]$StackName = 'medsreminder-login-asg',
  [string]$Region = 'ap-southeast-1',
  [string]$InstanceType = 't3.xlarge',
  [int]$DesiredCapacity = 4
)

$ErrorActionPreference = 'Stop'
$template = Join-Path $PSScriptRoot 'asg-login-stress.yaml'

aws cloudformation deploy `
  --region $Region `
  --stack-name $StackName `
  --template-file $template `
  --parameter-overrides `
    AmiId=$AmiId `
    VpcId=$VpcId `
    "SubnetIds=$SubnetIds" `
    KeyName=$KeyName `
    InstanceType=$InstanceType `
    MinSize=2 `
    MaxSize=4 `
    DesiredCapacity=$DesiredCapacity

aws autoscaling set-desired-capacity `
  --region $Region `
  --auto-scaling-group-name medsreminder-login-asg `
  --desired-capacity $DesiredCapacity `
  --honor-cooldown

$alb = aws cloudformation describe-stacks `
  --region $Region `
  --stack-name $StackName `
  --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" `
  --output text

Write-Host "ALB: http://$alb"
Write-Host "Wait until target group is healthy, then:"
Write-Host "k6 run -e BASE_URL=http://$alb `"$PSScriptRoot\k6-login-stress.js`""
