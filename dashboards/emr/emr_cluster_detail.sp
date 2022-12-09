dashboard "emr_cluster_detail" {
  title         = "AWS EMR Cluster Detail"
  documentation = file("./dashboards/emr/docs/emr_cluster_detail.md")

  tags = merge(local.emr_common_tags, {
    type = "Detail"
  })

  input "emr_cluster_arn" {
    title = "Select a cluster:"
    query = query.emr_cluster_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.emr_cluster_auto_termination
      args = {
        arn = self.input.emr_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.emr_cluster_state
      args = {
        arn = self.input.emr_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.emr_cluster_logging
      args = {
        arn = self.input.emr_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.emr_cluster_log_encryption
      args = {
        arn = self.input.emr_cluster_arn.value
      }
    }

  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "ec2_amis" {
        sql = <<-EOQ
          select
            custom_ami_id as image_id
          from
            aws_emr_cluster
          where
            custom_ami_id is not null
            and cluster_arn = $1;
        EOQ

        args = [self.input.emr_cluster_arn.value]
      }

      with "iam_roles" {
        sql = <<-EOQ
          select
            r.arn as role_arn
          from
            aws_iam_role as r,
            aws_emr_cluster as c
          where
            c.cluster_arn = $1
            and r.name = c.service_role;
        EOQ

        args = [self.input.emr_cluster_arn.value]
      }

      with "s3_buckets" {
        sql = <<-EOQ
          select
            b.arn as s3_bucket_arn
          from
            aws_emr_cluster as c
          left join
            aws_s3_bucket as b
            on split_part(log_uri, '/', 3) = b.name
          where
            cluster_arn = $1;
        EOQ

        args = [self.input.emr_cluster_arn.value]
      }

      nodes = [
        node.ec2_ami,
        node.emr_cluster,
        node.emr_instance,
        node.emr_instance_fleet,
        node.emr_instance_group,
        node.iam_role,
        node.s3_bucket
      ]

      edges = [
        edge.emr_cluster_to_ec2_ami,
        edge.emr_cluster_to_emr_instance_fleet,
        edge.emr_cluster_to_emr_instance_group,
        edge.emr_cluster_to_iam_role,
        edge.emr_cluster_to_s3_bucket,
        edge.emr_instance_fleet_to_emr_instance,
        edge.emr_instance_group_to_emr_instance

      ]

      args = {
        ec2_ami_image_ids = with.ec2_amis.rows[*].image_id
        emr_cluster_arns  = [self.input.emr_cluster_arn.value]
        iam_role_arns     = with.iam_roles.rows[*].role_arn
        s3_bucket_arns    = with.s3_buckets.rows[*].s3_bucket_arn
      }
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.emr_cluster_overview
        args = {
          arn = self.input.emr_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.emr_cluster_tags
        args = {
          arn = self.input.emr_cluster_arn.value
        }
      }
    }
    container {
      width = 6

      table {
        title = "Status"
        query = query.emr_cluster_status
        args = {
          arn = self.input.emr_cluster_arn.value
        }
      }

      table {
        title = "Instances"
        query = query.emr_cluster_instance
        args = {
          arn = self.input.emr_cluster_arn.value
        }

        column "ARN" {
          display = "none"
        }

        column "EC2 Instance ID" {
          href = "${dashboard.ec2_instance_detail.url_path}?input.instance_arn={{.'ARN' | @uri}}"
        }
      }

    }

  }

  container {
    table {
      title = "Applications"
      width = 6
      query = query.emr_cluster_applications
      args = {
        arn = self.input.emr_cluster_arn.value
      }

    }

    table {
      title = "EC2 Instance Attributes"
      width = 6
      query = query.emr_cluster_ec2_instance_attributes
      args = {
        arn = self.input.emr_cluster_arn.value
      }

    }
  }
}

query "emr_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      cluster_arn as value,
      json_build_object(
        'id', id,
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_emr_cluster
    order by
      title;
EOQ
}

query "emr_cluster_auto_termination" {
  sql = <<-EOQ
    select
      'Auto Termination' as label,
      case when auto_terminate then 'Enabled' else 'Disabled' end as value
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "emr_cluster_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(state) as value,
      case when state = 'TERMINATED_WITH_ERRORS' then 'alert' else 'ok' end as type
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "emr_cluster_logging" {
  sql = <<-EOQ
    select
      'Logging' as label,
      case when log_uri is null then 'Disabled' else 'Enabled' end as value,
      case when log_uri is null then 'alert' else 'ok' end as type
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "emr_cluster_log_encryption" {
  sql = <<-EOQ
    select
      'Log Encryption' as label,
      case when log_encryption_kms_key_id is null then 'Disabled' else 'Enabled' end as value,
      case when log_encryption_kms_key_id is null then 'alert' else 'ok' end as type
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "emr_cluster_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      id as "ID",
      instance_collection_type as "Instance Collection Type",
      region as "Region",
      account_id as "Account ID",
      cluster_arn as "ARN"
    from
      aws_emr_cluster
    where
      cluster_arn = $1
  EOQ

  param "arn" {}
}

query "emr_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_emr_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      cluster_arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}

query "emr_cluster_instance" {
  sql = <<-EOQ
    select
      i.id as "ID",
      i.ec2_instance_id as "EC2 Instance ID",
      i.state as "State",
      i.instance_fleet_id as "Instance Fleet ID",
      i.instance_group_id as "Instance Group ID",
      ec2i.arn as "ARN"
    from
      aws_emr_instance as i,
      aws_emr_cluster as c,
      aws_ec2_instance as ec2i
    where
      i.cluster_id = c.id
      and i.ec2_instance_id = ec2i.instance_id
      and cluster_arn = $1;
    EOQ

  param "arn" {}
}

query "emr_cluster_status" {
  sql = <<-EOQ
    select
      status -> 'StateChangeReason' ->> 'Code' as "Code",
      status -> 'StateChangeReason' ->> 'Message' as "Message",
      status -> 'Timeline' ->> 'CreationDateTime' as "Creation Time",
      status -> 'Timeline' ->> 'ReadyDateTime' as "Ready Time",
      status -> 'Timeline' ->> 'EndDateTime' as "End Time"
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
    EOQ

  param "arn" {}
}

query "emr_cluster_applications" {
  sql = <<-EOQ
    select
      app ->> 'Name' as "Name",
      app ->> 'Version' as "Version",
      app -> 'Args' as "Args",
      app -> 'AdditionalInfo' as "Additional Info"
    from
      aws_emr_cluster,
      jsonb_array_elements(applications) as app
    where
      cluster_arn = $1;
    EOQ

  param "arn" {}
}

query "emr_cluster_ec2_instance_attributes" {
  sql = <<-EOQ
    select
      ec2_instance_attributes ->> 'Ec2KeyName' as "Ec2 Key Name",
      ec2_instance_attributes ->> 'Ec2SubnetId' as "Ec2 Subnet Id",
      ec2_instance_attributes ->> 'IamInstanceProfile' as "Iam Instance Profile",
      ec2_instance_attributes ->> 'Ec2AvailabilityZone' as "Ec2 Availability Zone",
      ec2_instance_attributes ->> 'ServiceAccessSecurityGroup' as "Service Access Security Group",
      ec2_instance_attributes ->> 'EmrManagedSlaveSecurityGroup' as "Emr Managed Slave Security Group",
      ec2_instance_attributes ->> 'EmrManagedMasterSecurityGroup' as "Emr Managed Master Security Group"
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
    EOQ

  param "arn" {}
}
