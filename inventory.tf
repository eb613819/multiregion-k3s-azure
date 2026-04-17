resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory.yml"

  content = yamlencode({
    all = {
      children = {
        control_plane = {
          hosts = {
            for k, v in local.nodes :
            k => {
              ansible_host = (
                v.region == var.region_a ?
                azurerm_public_ip.pip_a[k].ip_address :
                azurerm_public_ip.pip_b[k].ip_address
              )

              ansible_user               = var.admin_username
              ansible_python_interpreter = "/usr/bin/python3"
            } if v.role == "control"
          }
        }

        workers = {
          hosts = {
            for k, v in local.nodes :
            k => {
              ansible_host = (
                v.region == var.region_a ?
                azurerm_public_ip.pip_a[k].ip_address :
                azurerm_public_ip.pip_b[k].ip_address
              )

              ansible_user               = var.admin_username
              ansible_python_interpreter = "/usr/bin/python3"
            } if v.role == "worker"
          }
        }

        k3s_cluster = {
          children = {
            control_plane = {}
            workers       = {}
          }
        }
      }
    }
  })
}