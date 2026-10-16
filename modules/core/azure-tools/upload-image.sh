#!/usr/bin/env bash


####################################################
# AZ LOGIN CHECK                                   #
####################################################

# Making  sure  that  one   is  logged  in  (to  avoid
# surprises down the line).
if [ $(az account list | jq -r 'length') -eq 0 ]
then
  echo
  echo '********************************************************'
  echo '* Please log  in to  Azure by  typing "az  login", and *'
  echo '* repeat the "./upload-image.sh" command.              *'
  echo '********************************************************'
  exit 1
fi

####################################################
# HELPERS                                          #
####################################################

show_id() {
  az $1 show \
    --resource-group "${resource_group}" \
    --name "${img_name}"        \
    --query "[id]"              \
    --output tsv
}

usage() {
  echo ''
  echo 'USAGE: (Every switch requires an argument)'
  echo ''
  echo '-g --resource-group REQUIRED Created if does  not exist. Will'
  echo '                             house a new disk and the created'
  echo '                             image.'
  echo ''
  echo '-n --image-name     REQUIRED The  name of  the image  created'
  echo '                             (and also of the new disk).'
  echo ''
  echo '-i --img-file       REQUIRED The path to the VHD file to upload.'
  echo ''
  echo '-G --gallery-name  OPTIONAL Create or reuse an Azure Shared Image'
  echo '                             Gallery for the uploaded image.'
  echo ''
  echo '-d --gallery-image-definition OPTIONAL Name of the gallery image'
  echo '                             definition. Defaults to image name.'
  echo ''
  echo '-v --gallery-image-version  OPTIONAL Gallery image version.'
  echo '                             Default value: "1.0.0".'
  echo ''
  echo '--publisher         OPTIONAL Gallery publisher name.'
  echo '                             Default value: "myNixOS".'
  echo ''
  echo '--offer             OPTIONAL Gallery offer name.'
  echo '                             Default value: "myNixOSOffer".'
  echo ''
  echo '--sku               OPTIONAL Gallery SKU name.'
  echo '                             Default value: "myNixOSSku".'
  echo ''
  echo '--storage-account   OPTIONAL Storage account name for VHD upload.'
  echo '                             Defaults to a name derived from the resource group.'
  echo ''
  echo '--container-name    OPTIONAL Blob container name for VHD upload.'
  echo '                             Default: "vhds".'
  echo ''
  echo '-l --location       Values from `az account list-locations`.'
  echo '                    Default value: "westeurope".'
}

####################################################
# SWITCHES                                         #
####################################################

# https://unix.stackexchange.com/a/204927/85131
while [ $# -gt 0 ]; do
  case "$1" in
    -l|--location)
      location="$2"
      ;;
    -g|--resource-group)
      resource_group="$2"
      ;;
    -n|--image-name)
      img_name="$2"
      ;;
    -i|--img-file)
      img_file="$2"
      ;;
    -G|--gallery-name)
      gallery_name="$2"
      ;;
    -a|--architecture)
      architecture="$2"
      ;;
    -d|--gallery-image-definition)
      gallery_image_definition="$2"
      ;;
    -v|--gallery-image-version)
      gallery_image_version="$2"
      ;;
    --publisher)
      publisher="$2"
      ;;
    --offer)
      offer="$2"
      ;;
    --sku)
      sku="$2"
      ;;
    --storage-account)
      storage_account="$2"
      ;;
    --container-name)
      container_name="$2"
      ;;
    -h|--help)
      usage
      exit 1
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument *\n"
      printf "***************************\n"
      usage
      exit 1
  esac
  shift
  shift
 done

if [ -z "${img_name:-}" ] || [ -z "${resource_group:-}" ] || [ -z "${img_file:-}" ]
then
  printf "************************************\n"
  printf "* Error: Missing required argument *\n"
  printf "************************************\n"
  usage
  exit 1
fi

location_d="${location:-"westeurope"}"

architecture="${architecture:-"x64"}"

storage_account="${storage_account:-$(printf '%s' "${resource_group}vhds" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9' | cut -c1-24)}"
container_name="${container_name:-vhds}"

gallery_image_definition="${gallery_image_definition:-${img_name}}"
gallery_image_version="${gallery_image_version:-"1.0.0"}"
publisher="${publisher:-"myNixOS"}"
offer="${offer:-"myNixOSOffer"}"
sku="${sku:-"${img_name}Sku"}"
os_type="${os_type:-"Linux"}"
os_state="${os_state:-"Generalized"}"
hyper_v_generation="${hyper_v_generation:-"V2"}"
target_regions="${target_regions:-${location_d}}"
replica_count="${replica_count:-1}"

####################################################
# PUT IMAGE INTO AZURE CLOUD                       #
####################################################

# https://vaneyckt.io/posts/safer_bash_scripts_with-set_euxo_pipefail/
set -euo pipefail
set -x

# Make resource group exists
if ! az group show --resource-group "${resource_group}" &>/dev/null
then
  az group create     \
    --name "${resource_group}" \
    --location "${location_d}" \
    --output none
fi

# Upload VHD to storage account
echo "Creating storage account and uploading VHD..."
if ! az storage account show --resource-group "${resource_group}" --name "${storage_account}" &>/dev/null; then
  az storage account create \
    --resource-group "${resource_group}" \
    --name "${storage_account}" \
    --location "${location_d}" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --output none
fi

connection_string="$(az storage account show-connection-string \
  --resource-group "${resource_group}" \
  --name "${storage_account}" \
  --query connectionString -o tsv)"

az storage container create \
  --name "${container_name}" \
  --connection-string "${connection_string}" \
  --output none

az storage blob upload \
  --container-name "${container_name}" \
  --file "${img_file}" \
  --name "$(basename "${img_file}")" \
  --connection-string "${connection_string}" \
  --overwrite \
  --output none

# 单独获取已上传 Blob 的 URL
os_vhd_uri="$(az storage blob url \
  --container-name "${container_name}" \
  --name "$(basename "${img_file}")" \
  --connection-string "${connection_string}" \
  --output tsv)"

# 可选：检查是否获取成功
if [ -z "${os_vhd_uri}" ]; then
  echo "错误：无法获取上传的 VHD URL" >&2
  exit 1
fi

os_vhd_storage_account="$(az storage account show \
  --resource-group "${resource_group}" \
  --name "${storage_account}" \
  --query id -o tsv)"

if [ -n "${gallery_name:-}" ]; then
  # Create or reuse Azure Compute Gallery and image definition
  if ! az sig show --resource-group "${resource_group}" --name "${gallery_name}" &>/dev/null; then
    az sig create \
      --resource-group "${resource_group}" \
      --gallery-name "${gallery_name}" \
      --location "${location_d}" \
      --output none
  fi

  if ! az sig image-definition show \
      --resource-group "${resource_group}" \
      --gallery-name "${gallery_name}" \
      --gallery-image-definition "${gallery_image_definition}" &>/dev/null; then
    az sig image-definition create \
      --resource-group "${resource_group}" \
      --gallery-name "${gallery_name}" \
      --gallery-image-definition "${gallery_image_definition}" \
      --publisher "${publisher}" \
      --offer "${offer}" \
      --sku "${sku}" \
      --os-type "${os_type}" \
      --os-state "${os_state}" \
      --hyper-v-generation "${hyper_v_generation}" \
      --architecture "${architecture}" \
      --output none
  fi

  if ! az sig image-version show \
      --resource-group "${resource_group}" \
      --gallery-name "${gallery_name}" \
      --gallery-image-definition "${gallery_image_definition}" \
      --gallery-image-version "${gallery_image_version}" &>/dev/null; then
    az sig image-version create \
      --resource-group "${resource_group}" \
      --gallery-name "${gallery_name}" \
      --gallery-image-definition "${gallery_image_definition}" \
      --gallery-image-version "${gallery_image_version}" \
      --os-vhd-storage-account "${os_vhd_storage_account}" \
      --os-vhd-uri "${os_vhd_uri}" \
      --target-regions "${target_regions}" \
      --replica-count "${replica_count}" \
      --output none
  fi

  gallery_version_id="$(az sig image-version show \
      --resource-group "${resource_group}" \
      --gallery-name "${gallery_name}" \
      --gallery-image-definition "${gallery_image_definition}" \
      --gallery-image-version "${gallery_image_version}" \
      -o tsv --query "id")"

  echo "gallery image version creation completed:"
  echo "gallery_image_version_id: ${gallery_version_id}"
else
  # Create managed image from uploaded VHD blob
  diskid="$(az disk create \
    --resource-group "${resource_group}" \
    --name "${img_name}" \
    --hyper-v-generation "${hyper_v_generation}" \
    --size-gb 8 \
    --architecture "${architecture}" \
    --os-type "linux" \
    --source "${os_vhd_uri}" \
    --query id -o tsv)"

  imageid="$(az image create \
    --resource-group "${resource_group}" \
    --name "${img_name}" \
    --source "${diskid}" \
    --hyper-v-generation "${hyper_v_generation}" \
    --os-type "linux" \
    --query id -o tsv)"

  echo "managed image creation completed:"
  echo "image_id: ${imageid}"
fi
