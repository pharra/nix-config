#!/bin/bash

# Parse input arguments
while getopts ":g:n:r:d:z:" opt; do
  case $opt in
    g) resource_group="$OPTARG"
    ;;
    n) vm_name="$OPTARG"
    ;;
    r) record_name="$OPTARG"
    ;;
    d) dns_resource_group="$OPTARG"
    ;;
    z) zone_name="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# 定义 IPv4 和 IPv6 的命名规则
random_prefix=$RANDOM
ipv4_name="$vm_name-ipv4-$(date +%Y%m%d%H%M%S)-$random_prefix"
ipv6_name="$vm_name-ipv6-$(date +%Y%m%d%H%M%S)-$random_prefix"
echo "random ipv4 name: $ipv4_name, ipv6 name: $ipv6_name"

# 获取 VM 的 NIC 名称
nic_name=$(az vm show -g $resource_group -n $vm_name --query 'networkProfile.networkInterfaces[0].id' -o tsv | awk -F / '{print $NF}')
echo "nic name: $nic_name"


# 获取之前的 IPv4 和 IPv6 的 IP CONFIG
ipv4_config=$(az network nic ip-config list -g $resource_group --nic-name $nic_name --query '[?primary].name' -o tsv)
ipv6_config=$(az network nic ip-config list -g $resource_group --nic-name $nic_name --query '[?!primary].name' -o tsv)
echo "ipv4 config: $ipv4_config, ipv6 config: $ipv6_config"

# 获取之前的 IPv4 和 IPv6 的公共 IP ID
old_ipv4_id=$(az network nic ip-config list -g $resource_group --nic-name $nic_name --query '[?primary].publicIPAddress.id' -o tsv)
old_ipv6_id=$(az network nic ip-config list -g $resource_group --nic-name $nic_name --query '[?primary].publicIPAddress.id' -o tsv)
echo "old ipv4 id: $old_ipv4_id, old ipv6 id: $old_ipv6_id"

# 创建 IPv4 和 IPv6 的公共 IP
new_ipv4_address=$(az network public-ip create --resource-group $resource_group --name $ipv4_name --sku Standard --allocation-method Static --version IPv4 --zone 1 2 3 --query "publicIp.ipAddress" -o tsv)
new_ipv6_address=$(az network public-ip create --resource-group $resource_group --name $ipv6_name --sku Standard --allocation-method Static --version IPv6 --zone 1 2 3 --query "publicIp.ipAddress" -o tsv)
echo "new_ipv4_address: $new_ipv4_address, new_ipv6_address: $new_ipv6_address"


# 将 IPv4 和 IPv6 的公共 IP 挂载到 VM 的 NIC 上
az network nic ip-config update -g $resource_group --nic-name $nic_name --name $ipv4_config --public-ip-address $ipv4_name
az network nic ip-config update -g $resource_group --nic-name $nic_name --name $ipv6_config --public-ip-address $ipv6_name

# 删除之前的 IPv4 和 IPv6 的公共 IP
az network public-ip delete --ids $old_ipv4_id
az network public-ip delete --ids $old_ipv6_id

# 获取旧的DNS记录
old_ipv4_address=$(az network dns record-set list --resource-group $dns_resource_group --zone-name $zone_name --query "[?name == '$record_name'].ARecords[0].ipv4Address" -o tsv)
old_ipv6_address=$(az network dns record-set list --resource-group $dns_resource_group --zone-name $zone_name --query "[?name == '$record_name'].AAAARecords[0].ipv6Address" -o tsv)
echo "old_ipv4_address: $old_ipv4_address, old_ipv6_address: $old_ipv6_address"

# 更新IPV4 DNS记录
az network dns record-set a add-record --resource-group $dns_resource_group --zone-name $zone_name --record-set-name $record_name --ipv4-address $new_ipv4_address
az network dns record-set a remove-record --resource-group $dns_resource_group --zone-name $zone_name --record-set-name $record_name --ipv4-address $old_ipv4_address

# 更新IPV6 DNS记录
az network dns record-set aaaa add-record --resource-group $dns_resource_group --zone-name $zone_name --record-set-name $record_name --ipv6-address $new_ipv6_address
az network dns record-set aaaa remove-record --resource-group $dns_resource_group --zone-name $zone_name --record-set-name $record_name --ipv6-address $old_ipv6_address