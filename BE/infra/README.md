# Request stress + Auto Scaling (Free Tier)

This stack puts 1–2 `t3.micro` copies of the current Docker compose stack behind an ALB. `t3.micro` is a Free Tier instance type. A Free Tier account rejects `t3.xlarge`.

## AWS account

Use the MedsReminder AWS user that owns the production EC2. The local CLI profile `legacyvault-backend-dev` cannot create this stack.

## One-time AWS setup

1. On the current EC2, confirm `docker compose -f docker-compose.prod.yml` is healthy on port 3000.
2. Create an AMI from that instance (no reboot if you must keep the site up).
3. Note `VpcId`, two public `SubnetIds`, and the SSH `KeyName`.
4. From a machine logged into that AWS account:

```powershell
cd BE/infra
.\deploy-asg.ps1 `
  -AmiId ami-xxxxxxxx `
  -VpcId vpc-xxxxxxxx `
  -SubnetIds "subnet-aaa,subnet-bbb" `
  -KeyName your-key
```

The script starts at desired capacity **1**. Auto scaling can add a second `t3.micro` from CPU 55% and ALB 400 requests/target.

5. Point DuckDNS at the ALB DNS only after the target group is healthy. Until then, k6 can hit `http://<alb-dns>`.

## Run the test

Install [k6](https://k6.io/docs/get-started/installation/). Wait until the target passes `/api/v1/billing/config`. On `t3.micro`, hit that light endpoint. Two thousand bcrypt logins will not succeed on 1 GB RAM.

```powershell
k6 run -e BASE_URL=http://<alb-dns> .\k6-login-stress.js
```

k6 ramps to 2000 virtual users in 2 minutes, holds 3 minutes, then ramps down. Setup registers 200 patient accounts (`stress1@medsreminder.test` …) and reuses them. Duplicate email/phone on a second run is ignored.

## What to screenshot for the report

- k6 summary: `http_req_failed`, `p(95)`, `login_fail`
- CloudWatch CPU of `medsreminder-login-asg`
- EC2 / ASG activity: desired 1 → 2

## After the demo

```powershell
aws cloudformation delete-stack --stack-name medsreminder-login-asg
```

Delete the stack when the demo ends. The load balancer is billed by the hour even on a Free Tier account. Do not fire this test at PayOS or the AI scan route.
