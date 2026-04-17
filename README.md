# k3s-multiregion-azure
### Multi-Region Kubernetes Cluster on Azure as a Testbed for RL-Driven Microservice Scheduling

This project builds a self-managed Kubernetes cluster spanning two Azure regions as a controlled environment for experimenting with topology-aware microservice scheduling. The long-term goal is to develop a machine learning-based scheduler that predicts which microservices communicate frequently and places them physically closer together to reduce accumulated network latency.

---

# Table of Contents

1. [Overview](#1-overview)
   - [1.1 Project Goals](#11-project-goals)
   - [1.2 Non-Goals](#12-non-goals)
   - [1.3 Future Work](#13-future-work)

2. [Tooling](#2-tooling)

3. [Architecture](#3-architecture)
   - [3.1 Cluster Design](#31-cluster-design)
   - [3.2 Why Self-Managed k3s Instead of AKS](#32-why-self-managed-k3s-instead-of-aks)
   - [3.3 Region Selection and Latency](#33-region-selection-and-latency)

4. [Running It](#4-running-it)
   - [4.1 Prerequisites](#41-prerequisites)
   - [4.2 Configuration](#42-configuration)
   - [4.3 Provisioning](#43-provisioning)
   - [4.4 Teardown](#44-teardown)

5. [Development: Infrastructure](#5-development-infrastructure)
   - [5.1 Repository Structure](#51-repository-structure)
   - [5.2 Variable Design](#52-variable-design)
   - [5.3 Networking](#53-networking)
   - [5.4 Virtual Machines](#54-virtual-machines)
   - [5.5 Outputs](#55-outputs)
   - [5.6 Baseline Latency Measurements](#56-baseline-latency-measurements)
   - [5.7 Challenges and Observations](#57-challenges-and-observations)

6. [Development: Cluster](#6-development-cluster)
   - [6.1 Ansible Directory Structure](#61-ansible-directory-structure)
   - [6.2 Inventory Generation](#62-inventory-generation)
   - [6.3 Control Plane Installation](#63-control-plane-installation)
   - [6.4 Worker Node Installation](#64-worker-node-installation)
   - [6.5 Cluster Validation](#65-cluster-validation)
   - [6.6 Challenges and Observations](#66-challenges-and-observations)

7. [Development: Application](#7-development-application)
   - [7.1 Application Overview](#71-application-overview)
   - [7.2 Services](#72-services)
   - [7.3 Deployment](#73-deployment)
   - [7.4 Validating Cross-Region Scheduling](#74-validating-cross-region-scheduling)
   - [7.5 Challenges and Observations](#75-challenges-and-observations)

---

# 1. Overview

Modern cloud applications consist of many constantly communicating microservices. When two services exchange frequent communication, they are described as *chatty*. The physical placement of chatty services has significant performance implications. If they are placed far apart, network latency accumulates across every internal call, degrading system responsiveness.

This project builds the infrastructure foundation for a future RL-driven Kubernetes scheduler that predicts which microservices are chatty and co-locates them to minimize latency. The cluster spans two Azure regions, where each region acts as a proxy for a rack in a datacenter: nodes within a region are treated as "close," while nodes across regions are "far," introducing measurable latency differences.

### What It Does

1. Provisions 5 virtual machines across two Azure regions using OpenTofu
2. Connects the regions via VNet peering for private IP communication
3. Installs k3s across all nodes to form a single multi-region Kubernetes cluster
4. Deploys a containerized multi-service application to validate cross-region scheduling

### Research Question

> Can a multi-region Kubernetes cluster provide a sufficiently controlled latency environment to serve as a testbed for RL-driven microservice scheduling experiments?

## 1.1 Project Goals

- Provision a multi-region Azure VM cluster using infrastructure-as-code
- Connect the two regions via VNet peering so nodes communicate over private IPs
- Demonstrate measurable, consistent latency differences between intra-region and cross-region communication
- Install k3s across all nodes to form a single unified cluster spanning both regions
- Deploy a multi-service application and verify that pods are scheduled across nodes in both regions
- Verify the cluster operates reliably as a unified system and the application is externally accessible

## 1.2 Non-Goals

- This project does not implement the RL scheduler itself
- No application workload is instrumented for latency measurement in this phase
- No managed Kubernetes service (AKS) is used

## 1.3 Future Work

- Instrument inter-service communication to measure latency by pod placement
- Develop and integrate a custom RL-based scheduler that replaces `kube-scheduler`
- Use placement decisions and measured latency to train and evaluate scheduling models

---

# 2. Tooling

**OpenTofu** is used to provision all infrastructure:
- Virtual machines across two Azure regions
- Virtual networks and subnets per region
- VNet peering between regions
- Network security groups
- Public and private IP allocation

**Ansible** is used to configure the cluster after provisioning:
- Install k3s server on the control plane node
- Join worker nodes across both regions to the cluster
- Deploy the test application to validate scheduling

**k3s** is the chosen Kubernetes distribution. It is lightweight and exposes the control plane components, allowing future replacement of `kube-scheduler` with a custom RL-based implementation. It also allows all nodes across both regions to participate in a single cluster without the federation complexity that multi-region AKS deployments require.

---

# 3. Architecture

## 3.1 Cluster Design

The cluster consists of 5 nodes distributed across two Azure regions:

| Node | Region | Role |
|------|--------|------|
| vm0 | northcentralus | Control Plane |
| vm1 | northcentralus | Worker |
| vm2 | northcentralus | Worker |
| vm3 | mexicocentral | Worker |
| vm4 | mexicocentral | Worker |

The control plane runs in Region A (`northcentralus`). Worker nodes are distributed across both regions. All nodes participate in a single k3s cluster connected via Azure VNet peering.

![architecture diagram](./images/azure_k3s.png)

## 3.2 Why Self-Managed k3s Instead of AKS

Azure Kubernetes Service (AKS) abstracts away control plane components including `kube-scheduler`. Because this component cannot be easily replaced or modified in AKS, it is not suitable for experimentation with custom scheduling algorithms.

A self-managed k3s cluster deployed on Azure VMs provides full control over the control plane, allowing future integration of a custom RL-based scheduler. Additionally, this approach allows all nodes across both regions to participate in a single cluster without the federation complexity that multi-region AKS deployments require.

## 3.3 Region Selection and Latency

Regions were selected based on subscription availability and geographic distance. `northcentralus` (Chicago) and `mexicocentral` (Querétaro) provide meaningful physical separation while remaining within the same subscription quota.

Baseline latency measurements confirmed the expected topology:

| Source | Destination | Relationship | Avg Latency |
|--------|-------------|--------------|-------------|
| vm0 | vm1 | Intra-region (northcentralus) | < 1ms |
| vm0 | vm2 | Intra-region (northcentralus) | < 1ms |
| vm0 | vm3 | Cross-region | ~52ms |
| vm0 | vm4 | Cross-region | ~52ms |

---

# 4. Running It

## 4.1 Prerequisites

- [OpenTofu](https://opentofu.org/docs/) installed
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in
- [Ansible](https://docs.ansible.com/) installed
- An SSH RSA key pair (Azure requires RSA; ed25519 is not supported for all VM series)

### Install OpenTofu
1.) Download the installer script:
  ```bash
  curl -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
  ```
2.) Grant execute permissions and review the script:
  ```bash
  chmod +x install-opentofu.sh && less install-opentofu.sh
  ```
3.) Install using the script:
  ```bash
  ./install-opentofu.sh --install-method standalone
  ```
4.) Check that OpenTofu is installed:
  ```bash
  tofu version
  ```
  ```console
  OpenTofu v1.11.4
  on linux_amd64
  ```
5.) Remove the installer:
  ```bash
  rm -f install-opentofu.sh
  ```
6.) To set up auto-completion, run the following:
```bash
tofu -install-autocomplete
```

### Install Azure CLI
1.) Install Azure CLI
```bash
curl -sL https://aka.ms InstallAzureCLIDeb
```
2.) Authenticate with:
```bash
az login
```
3.) If you have access to multiple subscriptions, ensure the correct one is selected:
```bash
az account set --subscription 00000000-0000-0000-0000-000000000000
```
You can confirm the active subscription again with:
```powershell
az account show
```

### Install Ansible
```bash
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt update
sudo apt install -y ansible software-properties-common python-is-python3 python3-pip python3-tabulate python3-lxml

pip install pydantic==1.9 --break-system-packages
```

### Generate an SSH Key
1.) Generate the key
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k3s_azure -C "k3s-cluster"
```

2.) Get the public key and paste into `terraform.tfvars`:
```bash
cat ~/.ssh/k3s_azure.pub
```

## 4.2 Configuration
### Subscription ID
Copy the example secrets file and fill in your subscription ID:
```bash
cp secrets.auto.tfvars.example secrets.auto.tfvars
```
`secrets.auto.tfvars` is gitignored.
Your subscription ID can be found with:
```bash
az account show --query id -o tsv
```

### Non-sensitive Configuration
`terraform.tfvars` is committed to the repository and contains all non-sensitive configuration. Edit it if you need to change regions, VM size, or image:

```hcl
region_a       = "northcentralus"
region_b       = "mexicocentral"
prefix         = "k3s"
admin_username = "ubuntu"
ssh_pub_key    = "ssh-rsa AAAA..."
vm_size        = "Standard_B2ats_v2"
image = {
  publisher = "Canonical"
  offer     = "ubuntu-24_04-lts"
  sku       = "server"
  version   = "latest"
}
```

## 4.3 Provisioning

```bash
tofu init
tofu plan
tofu apply
```

After apply completes, OpenTofu outputs all IP addresses:

```bash
tofu output vm_public_ips
tofu output vm_private_ips
tofu output control_plane_private_ip
```

SSH into any node:
```bash
ssh -i ~/.ssh/k3s_azure ubuntu@<public-ip>
```

For convenience, add entries to `~/.ssh/config`:
```
Host k3s-control
    HostName <vm0-public-ip>
    User ubuntu
    IdentityFile ~/.ssh/k3s_azure

Host k3s-worker1
    HostName <vm1-public-ip>
    User ubuntu
    IdentityFile ~/.ssh/k3s_azure
```

## 4.4 Teardown

```bash
tofu destroy
```

Note: public IPs are dynamically assigned and will change after each destroy and re-apply.

---

# 5. Development: Infrastructure

## 5.1 Repository Structure

```
k3s-multiregion-azure/
├── providers.tf                # Provider
├── locals.tf                   # Locals
├── main.tf                     # Resource group, VNets, peering, NSGs
├── variables.tf                # All variable declarations
├── vms.tf                      # Public IPs, NICs, NSG associations, VMs
├── outputs.tf                  # Public IPs, private IPs, control plane IP
├── inventory.tf                # Generates an Ansible inventory
├── terraform.tfvars            # Non-sensitive configuration values
├── secrets.auto.tfvars         # gitignored — subscription ID
├── secrets.auto.tfvars.example # Committed template for secrets file
├── .gitignore
└── ansible/                    # Cluster configuration (see Section 6)
```

## 5.2 Variable Design

Variables are split across two files:

- `terraform.tfvars` — all non-sensitive configuration, committed to version control
- `secrets.auto.tfvars` — subscription ID only, gitignored

Region variables (`region_a`, `region_b`) are defined as top-level variables. The node map is defined as a `local` rather than a variable so that node-to-region assignments are expressed in terms of `var.region_a` and `var.region_b` directly, avoiding the HCL limitation that prevents variable references inside `tfvars` values:

```hcl
locals {
  nodes = {
    vm0 = { region = var.region_a, role = "control" }
    vm1 = { region = var.region_a, role = "worker"  }
    vm2 = { region = var.region_a, role = "worker"  }
    vm3 = { region = var.region_b, role = "worker"  }
    vm4 = { region = var.region_b, role = "worker"  }
  }
}
```

This ensures that changing `region_a` or `region_b` in `tfvars` automatically flows through to all node assignments with no risk of them getting out of sync.

The `role` tag on each node has no meaning to OpenTofu. It is carried through as an Azure resource tag and will be used by Ansible to distinguish the control plane node from workers during k3s installation.

## 5.3 Networking

Each region has its own VNet with a non-overlapping address space:

| | VNet CIDR | Subnet |
|-|-----------|--------|
| Region A | 10.0.0.0/16 | 10.0.1.0/24 |
| Region B | 10.1.0.0/16 | 10.1.1.0/24 |

Non-overlapping ranges are required because once the VNets are peered, Azure routes traffic between them. Overlapping CIDRs would make routing ambiguous and cause the peering to fail.

VNet peering is configured bidirectionally — a peering from A to B and a separate peering from B to A. This allows all nodes to communicate over private IPs using Azure’s backbone network rather than the public internet.

This design is important for three reasons:

- k3s requires worker nodes to reach the control plane’s private IP when joining the cluster  
- Kubernetes workloads can communicate across regions as if they were on the same private network  
- Cross-region latency reflects physical datacenter distance rather than internet routing variability  

To support multi-node Kubernetes networking, peering is configured with forwarded traffic enabled, ensuring that VXLAN-encapsulated pod traffic is allowed between VNets.

Each region has its own Network Security Group. Instead of exposing services broadly or relying on public IP ranges, all NSG rules restrict traffic to the Azure `VirtualNetwork` source tag. This ensures that only traffic originating from within the peered VNets is allowed.

The following inbound ports are explicitly allowed:

- **22/TCP** — SSH access for node administration  
- **6443/TCP** — Kubernetes API server (k3s control plane)  
- **8472/UDP** — Flannel VXLAN overlay network for pod-to-pod communication across nodes  
- **10250/TCP** — Kubelet API used for node management, logs, and exec operations  

## 5.4 Virtual Machines

VMs are created using `for_each` over two locals that split the node map by region:

```hcl
locals {
  nodes_a = { for k, v in local.nodes : k => v if v.region == var.region_a }
  nodes_b = { for k, v in local.nodes : k => v if v.region == var.region_b }
}
```

This drives two separate VM resource blocks, each creating only the nodes assigned to that region. Adding a node requires only adding an entry to the `nodes` local.

### VM Size and Image

| Setting | Value |
|---------|-------|
| VM Size | Standard_B2ats_v2 |
| Image | Canonical ubuntu-24_04-lts / server |
| Auth | RSA SSH key only, password auth disabled |

VM size selection was constrained by regional capacity availability. `Standard_B2pts_v2` (ARM64) was initially used but was unavailable in the required regions. `Standard_B2ats_v2` (AMD64) was available in both `northcentralus` and `mexicocentral`. The image SKU was updated from `server-arm64` to `server` to match.

Azure also rejected ed25519 SSH keys for this VM series despite the same key working in other regions. An RSA key is required.

## 5.5 Outputs

Three outputs are defined:

- `vm_public_ips` — map of all node names to public IPs, used for SSH access
- `vm_private_ips` — map of all node names to private IPs
- `control_plane_private_ip` — private IP of vm0 specifically, used by Ansible when constructing the k3s agent join command for Region B workers

## 5.6 Baseline Latency Measurements

After provisioning, ping was used to measure round-trip latency between nodes. All measurements were taken over private IPs via the VNet peering link.

| Source | Destination | Region Relationship | Avg RTT |
|--------|-------------|---------------------|---------|
| vm0 (northcentralus) | vm1 (northcentralus) | Intra-region | < 1ms |
| vm3 (mexicocentral) | vm4 (mexicocentral) | Intra-region | < 1ms |
| vm0 (northcentralus) | vm3 (mexicocentral) | Cross-region | ~52ms |
| vm0 (northcentralus) | vm4 (mexicocentral) | Cross-region | ~52ms |
| vm3 (mexicocentral) | vm0 (northcentralus) | Cross-region | ~52ms |

The ~52x latency difference between intra-region and cross-region communication confirms that the infrastructure provides a meaningful and measurable topology signal. This is the core property the cluster needs to support future scheduling experiments.

## 5.7 Challenges and Observations

**Regional capacity constraints** — `Standard_B2pts_v2` (ARM64) and `Standard_B2ats_v2` (AMM64) both reported as available via `az vm list-skus` but failed to provision with a capacity error in both `eastus2` and `westus3`. Capacity availability and SKU availability are checked independently by Azure; a SKU can show no restrictions while still having insufficient physical capacity. `northcentralus` and `mexicocentral` were selected after confirming actual provisioning success.

**SSH key type restriction** — Azure rejected ed25519 keys for the `Standard_B2ats_v2` series in these regions. The same ed25519 key worked on the same VM series in `northcentralus` during a previous project. RSA (4096-bit) is required for this deployment.

**Provider version** — upgrading from `azurerm ~> 3.0` to `~> 4.0` introduced a breaking change requiring `subscription_id` to be explicitly declared in the provider block. This value is kept out of version control in `secrets.auto.tfvars`.

**Inconsistent apply failures** — early apply attempts produced `Provider produced inconsistent result after apply` errors on networking resources. These appeared to be caused by Azure transiently failing mid-apply during the capacity error runs, leaving the provider in an inconsistent state. Resolution required deleting the resource group directly via the Azure CLI and removing the state file before re-applying cleanly.

---

# 6. Development: Cluster

*This section will be completed after k3s installation.*

## 6.1 Ansible Directory Structure

## 6.2 Inventory Generation

## 6.3 Control Plane Installation

## 6.4 Worker Node Installation

## 6.5 Cluster Validation

## 6.6 Challenges and Observations

---

# 7. Development: Application

*This section will be completed after application deployment.*

## 7.1 Application Overview

## 7.2 Services

## 7.3 Deployment

## 7.4 Validating Cross-Region Scheduling

## 7.5 Challenges and Observations