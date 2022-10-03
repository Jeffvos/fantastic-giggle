variable "cloud" {
  type = string
  
  validation {
    condition = contains(["aws", "azure", "gcp", "vmware"], lower(var.cloud))
    error_message = "please use an approved cloud "
  }
  validation {
    condition = lower(var.cloud) == var.cloud
    error_message = "the please use lower case"
  }
}