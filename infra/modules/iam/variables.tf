variable "name_prefix" {
  description = "Prefix applied to resource names (e.g. <project>-<environment>)."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources in this module."
  type        = map(string)
}
