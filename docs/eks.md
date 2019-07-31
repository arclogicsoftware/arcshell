# eks.sh



## Reference


### eks_list_clusters
List names of clusters in the current region.
```bash
> eks_list_clusters
```

### eks_set_cluster
Set the global cluster name variable.
```bash
> eks_set_cluster "cluster_name"
```

### eks_describe_cluster
Describe the current cluster.
```bash
> eks_describe_cluster [cluster_name]
```

### eks_update_kube_config
Updates the ~/.kube/config file with current cluster.
```bash
> eks_update_kube_config
```

### eks_get_cluster_property
Return a specific cluster property.
eks_get_cluster_property property_name

### eks_list_config_maps
Return a list of all config maps.
```bash
> eks_list_config_maps
```

### eks_return_private_endpoint_address

### eks_list_nodes

### eks_cordon_node

```bash
> eks_cordon_node [node_name]
```

### eks_uncordon_node

```bash
> eks_uncordon_node [node_name]
```

### eks_drain_node

```bash
> eks_drain_node [node_name]
```

### eks_list_pods

### eks_nodegroup_yaml

### eks_create_key_pair
Create a new EC2 key pair.
```bash
> eks_create_key_pair "key_pair_name"
```

### eks_delete_key_pair
Delete an existing EC2 key pair.
```bash
> eks_delete_key_pair "key_pair_name"
```

### eks_create_nodegroup

### eks_list_role_arns
Lists the Arns for all roles.
```bash
> eks_list_role_arns
```

### eks_build_aws_auth
Builds the initial aws_auth config map if it doesn't exist.
```bash
> eks_build_aws_auth
```

### eks_add_role_to_aws_auth
Adds a new role mapping to the existing aws-auth config map and updates it.
```bash
> _eks_return_new_aws_auth_body
```

### eks_edit_aws_auth
Manually edit the current aws-auth config map.

### eks_delete_aws_auth
Delete the aws-auth config map.
```bash
> eks_delete_aws_auth
```

### eks_create_bucket
Create an S3 bucket.
```bash
> eks_create_bucket bucket_name
```

### eks_list_auto_scale_groups

