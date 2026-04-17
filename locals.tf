locals {
  nodes = {
    vm0 = { region = var.region_a, role = "control" }
    vm1 = { region = var.region_a, role = "worker"  }
    vm2 = { region = var.region_a, role = "worker"  }
    vm3 = { region = var.region_b, role = "worker"  }
    vm4 = { region = var.region_b, role = "worker"  }
  }
  
  k3s_nsg_rules = [
    {
      name     = "allow-ssh"
      priority = 100
      protocol = "Tcp"
      port     = "22"
      source   = "*"
    },
    {
      name     = "allow-k3s-api"
      priority = 110
      protocol = "Tcp"
      port     = "6443"
      source   = "VirtualNetwork"
    },
    {
      name     = "allow-flannel"
      priority = 120
      protocol = "Udp"
      port     = "8472"
      source   = "VirtualNetwork"
    },
    {
      name     = "allow-kubelet"
      priority = 130
      protocol = "Tcp"
      port     = "10250"
      source   = "VirtualNetwork"
    }
  ]

  nodes_a = { for k, v in local.nodes : k => v if v.region == var.region_a }
  nodes_b = { for k, v in local.nodes : k => v if v.region == var.region_b }
}
