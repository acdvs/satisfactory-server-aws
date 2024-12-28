# Satisfactory Server AWS

Automated Satisfactory 1.0 Dedicated Server setup on AWS.

## Changes from upstream projects

- Removed unused 1.0 port configurations.
- Simplified auto-shutdown script with cron job.
- To reduce S3 costs:
  - Saves are synced from server to S3 only on shutdown.
  - Saves are synced from S3 to server on startup. Allows save modification while the instance is stopped. Good for moving between AWS and a local server if AWS is unnecessary (e.g., playing solo).

## Intro

FICSIT Incorporated has provided you with this tool (cost deducted from your existing balance) to assist you with Project Assembly. This tool can help you collaborate with friends on your factory projects.

This project uses [AWS CDK](https://aws.amazon.com/cdk/) to provision everything you need to host a [Satisfactory Dedicated Server](https://satisfactory.fandom.com/wiki/Dedicated_servers) on AWS. It includes the following:
 - VPC/Network configuration
 - EC2 Instance provisioning
 - Automatic shutdown when not in use (saves $$)
 - Automatic game file backup to S3
 - A Lambda browser endpoint to [start the server](#starting-the-server)

Why use AWS when you can host for free on your own computer?
 - If you want to allow friends to play on your server without you, you will have to always leave your computer on and the server running continuously, even if you are not playing. Having it on the cloud frees up your hardware.
 - Your computer may not have enough resources to host the server and play at the same time.

### Costs

If you play on the server 2 hours per day, this setup will cost around $5/month on AWS.

Since the server automatically shuts down when not in use, you only pay when the server is up and you (or your friends) are actively playing on it.

S3 and Lambda usage costs are free tier eligible.

### Disclaimers

This is a free and open source project and there are no guarantees that it will work or always continue working. If you use it, you are responsible for maintaining your setup and monitoring and paying for your AWS bill.  It is a great project for learning a little AWS and CDK, but it is not so great if you wish to have a hands-off experience managing your game server.

## Requirements

- [AWS Account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account)
- [AWS CLI](https://aws.amazon.com/cli)
- [Git](https://git-scm.com/downloads)
- [NodeJS](https://nodejs.org/en/download)

## Configuration

Copy the given `server-hosting/config.sample.ts` file to `server-hosting/config.ts` file. Fill the fields with appropriate values. Explanation for each field is given in file itself.

At a minimum, account (account number) and region are required.

## Quick Start

This assumes you have all requirements and have [configured aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)

1. [Clone this project](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
2. `npm install`
3. `npx cdk bootstrap <aws account number>/<aws region>` (replace account number and region)
4. `cp server-hosting/.config.sample.ts server-hosting/.config.ts` if you have not done so (see [Configuration](#configuration) for customization); you must fill in region and account
5. `npx cdk deploy`
6. Wait for the CloudFormation stack to finish. It may take a few minutes for the server to download/install everything after the stack is finished.
7. Use the EC2 instance public IP address to connect to your server in Satisfactory Server Manager (see [DNS and IP management](#dns-and-ip-management))
8. Start a new game or upload a save

## Accessing your server

Access to the EC2 instance hosting your Satisfactory server can be done via [Session Manager](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/session-manager.html). External SSH is **blocked** by default at the network level. Tip: ssm may open /bin/sh, running `bash` can get you to a more familiar bash shell.

## DNS and IP management

When your EC2 instance shuts down and starts back up, there's no gurantee that the IP address will stay the same. If it changes, you will have to re-add the server in Server Manager. There are a couple ways to fix the issue:

1. [Elastic IP](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html) - Create and assign it to your EC2 instance in AWS. Your Elatic IP will never change, but you will get charged for it when it is *not in use* ($0.001/hour or $3.60/month if never used).  This method also allows you to use your own custom domain address if wish.
2. Dynamic DNS - Free dynamic DNS services like [DuckDns](https://www.duckdns.org/) provide a way to automatically manage when the IP address changes. Once setup, you just use their url and they handle everything else behind the scenes. This method may not allow you to use a custom domain.

## Starting the server

After deploying, there will be a Lambda function setup through API Gateway.  This provides a URL that players can go to from any browser to start the server when needed. To find this URL, navigate in AWS to API Gateway -> SatisfactoryHostingStartServerApi -> Dashboard (lefthand menu). The URL is at the top next to "Invoke this API at".
