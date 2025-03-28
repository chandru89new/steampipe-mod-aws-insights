## v0.9 [2022-12-02]

_Bug fixes_

- Fixed the `aws_sqs_queue_encryption` query in the `AWS SQS Queue Detail` dashboard to also check if a queue is encrypted by Amazon Managed SQS Key. ([#245](https://github.com/turbot/steampipe-mod-aws-insights/pull/245))

## v0.8 [2022-10-27]

_Enhancements_

- Updated the `aws_ebs_volume_unattached_count` and `aws_ebs_volume_attached_instances_count` queries in `AWS EBS Volume Dashboard` and `AWS EBS Volume Detail` dashboards respectively to handle the `attachments` column correctly when empty in the `aws_ebs_volume` table. ([#206](https://github.com/turbot/steampipe-mod-aws-insights/pull/206))

_Dependencies_

- AWS plugin `v0.80.0` or higher is now required. ([#208](https://github.com/turbot/steampipe-mod-aws-insights/pull/208))

## v0.7 [2022-09-19]

_Bug fixes_

- Fixed `AWS IAM User Detail` dashboard showing access keys for users with same name from other connections' accounts.

## v0.6 [2022-06-01]

_Enhancements_

- Added links in `AWS EC2 Instance Detail` dashboard to `AWS EBS Volume Detail` and `AWS VPC Security Group Detail` dashboards. ([#102](https://github.com/turbot/steampipe-mod-aws-insights/pull/102))
- Added a link in `AWS IAM Access Key Age Report` dashboard to `AWS IAM User Detail` dashboard. ([#103](https://github.com/turbot/steampipe-mod-aws-insights/pull/103))

## v0.5 [2022-05-09]

_Enhancements_

- Updated docs/index.md and README with new dashboard screenshots and latest format. ([#97](https://github.com/turbot/steampipe-mod-aws-insights/pull/97))

## v0.4 [2022-05-04]

_Enhancements_

- Simplified the jq expression in `AWS IAM User Detail` dashboard. ([#94](https://github.com/turbot/steampipe-mod-aws-insights/pull/94))

_Bug fixes_

- Fixed the `aws_vpc_empty_status` query in `AWS VPC Dashboard` dashboard to remove duplicate results. ([#90](https://github.com/turbot/steampipe-mod-aws-insights/pull/90))
- Fixed the `aws_iam_group_direct_attached_policy_count_for_group` and `aws_iam_role_inline_policy_count_for_role` card queries in `AWS IAM Group Detail` and `AWS IAM Role Detail` dashboards respectively to show `0` instead of `null` if there are no attached policies. ([#89](https://github.com/turbot/steampipe-mod-aws-insights/pull/89))
- Fixed the invalid jq expression in the `IAM User Excessive Privilege Report` dashboard. ([#92](https://github.com/turbot/steampipe-mod-aws-insights/pull/92))

## v0.3 [2022-03-31]

_Dependencies_

- AWS plugin `v0.53.0` or higher is now required ([#79](https://github.com/turbot/steampipe-mod-aws-insights/pull/66))

_What's new?_

- New dashboards added:
  - [ACM Certificate Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.acm_certificate_detail) ([#75](https://github.com/turbot/steampipe-mod-aws-insights/pull/75))
  - [DynamoDB Table Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.aws_dynamodb_table_detail) ([#76](https://github.com/turbot/steampipe-mod-aws-insights/pull/76))
  - [RDS DB Cluster Snapshot Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.aws_rds_db_cluster_snapshot_detail) ([#77](https://github.com/turbot/steampipe-mod-aws-insights/pull/77))

_Bug fixes_

- Added the missing document references for S3 dashboards ([#74](https://github.com/turbot/steampipe-mod-aws-insights/pull/74))

## v0.2 [2022-03-18]

_Dependencies_

- Steampipe v0.13.1 or higher is now required ([#66](https://github.com/turbot/steampipe-mod-aws-insights/pull/66))

_What's new?_

- Added: Select cards now include links to respective reports in all dashboards ([#65](https://github.com/turbot/steampipe-mod-aws-insights/pull/65))
- New dashboards added:
  - [IAM User Excessive Privilege Report](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.aws_iam_user_excessive_privilege_report) ([#67](https://github.com/turbot/steampipe-mod-aws-insights/pull/67))
  - [SNS Topic Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.aws_sns_topic_detail) ([#64](https://github.com/turbot/steampipe-mod-aws-insights/pull/64))

## v0.1 [2022-03-10]

_What's new?_

New dashboards, reports, and details for the following services:
- ACM
- CloudTrail
- DynamoDB
- EBS
- EC2
- IAM
- KMS
- Lambda
- RDS
- Redshift
- S3
- SNS
- SQS
- VPC
