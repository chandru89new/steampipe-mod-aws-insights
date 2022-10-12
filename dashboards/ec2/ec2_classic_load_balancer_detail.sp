dashboard "aws_ec2_classic_load_balancer_detail" {
  title         = "AWS EC2 Classic Load Balancer Detail"
  documentation = file("./dashboards/ec2/docs/ec2_classic_load_balancer_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "clb" {
    title = "Select a Classic Load balancer:"
    query = query.aws_clb_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_clb_scheme
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.aws_clb_instances
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.aws_clb_logging_enabled
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.aws_clb_az_zone
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.aws_clb_cross_zone_enabled
      args = {
        arn = self.input.clb.value
      }
    }

  }

  container {
    graph {
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_ec2_classic_load_balancer_node,
        node.aws_ec2_clb_to_ec2_instance_node,
        node.aws_ec2_clb_to_s3_bucket_node,
        node.aws_ec2_clb_to_vpc_security_group_node,
        node.aws_ec2_clb_vpc_security_group_to_vpc_node,
        node.aws_ec2_lb_from_ec2_load_balancer_listener_node
      ]

      edges = [
        edge.aws_ec2_clb_to_ec2_instance_edge,
        edge.aws_ec2_clb_to_s3_bucket_edge,
        edge.aws_ec2_clb_to_vpc_security_group_edge,
        edge.aws_ec2_clb_vpc_security_group_to_vpc_edge,
        edge.aws_ec2_lb_from_ec2_load_balancer_listener_edge
      ]

      args = {
        arn = self.input.clb.value
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.aws_ec2_clb_overview
      args = {
        arn = self.input.clb.value
      }

    }

    table {
      title = "Tags"
      width = 3
      query = query.aws_ec2_clb_tags
      args = {
        arn = self.input.clb.value
      }
    }
  }

}

query "aws_clb_input" {
  sql = <<-EOQ
    select
      title as label,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_ec2_classic_load_balancer
    order by
      title;
  EOQ
}

query "aws_ec2_clb_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      created_time as "Created Time",
      dns_name as "DNS Name",
      canonical_hosted_zone_name_id as "Route 53 Hosted Zone ID",
      account_id as "Account ID",
      region as "Region",
      arn as "ARN"
    from
      aws_ec2_classic_load_balancer
    where
      aws_ec2_classic_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_clb_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ec2_classic_load_balancer,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}

query "aws_clb_logging_enabled" {
  sql = <<-EOQ
    select
      'Logging' as label,
      case when access_log_enabled = 'false' then 'Disabled' else 'Enabled' end as value,
      case when access_log_enabled = 'false' then 'alert' else 'ok' end as type
    from
      aws_ec2_classic_load_balancer
    where
      aws_ec2_classic_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_clb_az_zone" {
  sql = <<-EOQ
    select
      'Availibility Zones' as label,
      count(az ->> 'ZoneName') as value,
      case when count(az ->> 'ZoneName') > 1 then 'ok' else 'alert' end as type
    from
      aws_ec2_classic_load_balancer
      cross join jsonb_array_elements(availability_zones) as az
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_clb_cross_zone_enabled" {
  sql = <<-EOQ
    select
      'Cross Zone' as label,
      case when cross_zone_load_balancing_enabled then 'Enabled' else 'Disabled' end as value,
      case when cross_zone_load_balancing_enabled then 'ok' else 'alert' end as type
    from
      aws_ec2_classic_load_balancer
      cross join jsonb_array_elements(availability_zones) as az
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_clb_instances" {
  sql = <<-EOQ
    select
      'Instances' as label,
      count(i) as value,
      case when count(i) >= 1 then 'ok' else 'alert' end as type
    from
      aws_ec2_classic_load_balancer
      cross join jsonb_array_elements(instances) as i
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_clb_scheme" {
  sql = <<-EOQ
    select
      'Scheme' as label,
      initcap(scheme) as value
    from
      aws_ec2_classic_load_balancer
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ec2_classic_load_balancer_node" {
  category = category.aws_ec2_classic_load_balancer

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Security Groups', clb.security_groups,
        'Scheme', clb.scheme
      ) as properties
    from
      aws_ec2_classic_load_balancer
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ec2_clb_to_ec2_instance_node" {
  category = category.aws_ec2_instance

  sql = <<-EOQ
    select
      instances.arn as id,
      instances.title as title,
      jsonb_build_object(
        'Instance ID', instances.instance_id,
        'ARN', instances.arn,
        'Account ID', instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_classic_load_balancer as clb
      cross join jsonb_array_elements(clb.instances) as i
    left join
      aws_ec2_instance instances
      on instances.instance_id = i ->> 'InstanceId'
    where
      clb.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ec2_clb_to_ec2_instance_edge" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      clb.arn as from_id,
      instances.arn as to_id,
      jsonb_build_object(
        'Account ID', instances.account_id
      ) as properties
    from
      aws_ec2_classic_load_balancer as clb
      cross join jsonb_array_elements(clb.instances) as i
    left join
      aws_ec2_instance instances
      on instances.instance_id = i ->> 'InstanceId'
    where
      clb.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ec2_clb_to_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      buckets.arn as id,
      buckets.title as title,
      jsonb_build_object(
        'Name', buckets.name,
        'ARN', buckets.arn,
        'Account ID', buckets.account_id,
        'Region', buckets.region,
        'Logs to', clb.access_log_s3_bucket_name
      ) as properties
    from
      aws_s3_bucket buckets,
      aws_ec2_classic_load_balancer as clb
    where
      clb.arn = $1
      and buckets.name = clb.access_log_s3_bucket_name;
  EOQ

  param "arn" {}
}

edge "aws_ec2_clb_to_s3_bucket_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      clb.arn as from_id,
      buckets.arn as to_id,
      jsonb_build_object(
        'Account ID', buckets.account_id,
        'Log Prefix', clb.access_log_s3_bucket_prefix
      ) as properties
    from
      aws_s3_bucket buckets,
      aws_ec2_classic_load_balancer as clb
    where
      clb.arn = $1
      and buckets.name = clb.access_log_s3_bucket_name;
  EOQ

  param "arn" {}
}

node "aws_ec2_clb_to_vpc_security_group_node" {
  category = category.aws_vpc_security_group

  sql = <<-EOQ
    select
      sg.arn as id,
      sg.title as title,
      jsonb_build_object(
        'Group Name', sg.group_name,
        'Group ID', sg.group_id,
        'ARN', sg.arn,
        'Account ID', sg.account_id,
        'Region', sg.region,
        'VPC ID', sg.vpc_id
      ) as properties
    from
      aws_vpc_security_group sg,
      aws_ec2_classic_load_balancer as clb
    where
      clb.arn = $1
      and sg.group_id in
      (
        select
          jsonb_array_elements_text(clb.security_groups)
      );
  EOQ

  param "arn" {}
}

edge "aws_ec2_clb_to_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      clb.arn as from_id,
      sg.arn as to_id,
      jsonb_build_object(
        'Account ID', sg.account_id
      ) as properties
    from
      aws_vpc_security_group sg,
      aws_ec2_classic_load_balancer as clb
    where
      clb.arn = $1
      and sg.group_id in
      (
        select
          jsonb_array_elements_text(clb.security_groups)
      );
  EOQ

  param "arn" {}
}

node "aws_ec2_clb_vpc_security_group_to_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      vpc.vpc_id as id,
      vpc.title as title,
      jsonb_build_object(
        'VPC ID', vpc.vpc_id,
        'Account ID', vpc.account_id,
        'Region', vpc.region,
        'CIDR Block', vpc.cidr_block
      ) as properties
    from
      aws_vpc vpc,
      aws_ec2_classic_load_balancer as clb
    where
      clb.arn = $1
      and clb.vpc_id = vpc.vpc_id;
  EOQ

  param "arn" {}
}

edge "aws_ec2_clb_vpc_security_group_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      sg.arn as from_id,
      vpc.vpc_id as to_id,
      jsonb_build_object(
        'Account ID', vpc.account_id
      ) as properties
    from
      aws_vpc vpc,
      aws_ec2_classic_load_balancer as clb
      left join 
        aws_vpc_security_group sg 
        on sg.group_id in 
        (
          select 
            jsonb_array_elements_text(clb.security_groups)
        )
    where
      clb.arn = $1
      and clb.vpc_id = vpc.vpc_id;
  EOQ

  param "arn" {}
}
