region_a            = "northcentralus"
region_b            = "mexicocentral"
prefix              = "k3s"
admin_username      = "ubuntu"
ssh_pub_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyj9rLlhCHp8f2dCtiXzDQRfKTxnz6YogyDIeCc5yr2iSPhseHGT9nnbBAc38yI92lL0XAu3SPr6yvJDzsvyxwI2zlEf2jbB5aNMK77XXlnpCbEFPiyZjbeYs+poztkUHPxWxXAg8OBaa1SdVN/iQ38xaPsSAGBf0yqnym/CcfRY7JGbn5j3Sf/R5l4C0HxSFYg4Q7lSLamKVuFr0hHkZo/QF/52rF5WTJzRYBxS25FiVXZkbj9BceVvHZm6Nowd/UZpgl7gBljcR3aWOcYq9T0/APThOdlsom+7sguG527MZTilYT5cXhAGk1SvqU1ZwTsY/dWNxBsS9vm9+2H2IHeT/5PfSqOJQXO7qXCgcR2Zg3bbWuRawXHYAU+sqmg+O/nLJYlnoALWRki6jDLvrVPt7B65UBnlvEv+Xfnbsgy0nSVBG+QtumYTaZpcjNCpVdz6U5qkfeEn/hFPwLPtmAr56205hUyWB5IceBSoISk7VJ2stSbyQF7dRAIJYG+wc4mgXlOr1M+irdGjq61zaNhu0a7RYuzsYPIVM6rwkQUie0Drn5KMElkJ1H7C7lI5SiocpoC+3JUGrQxOiL8CPUIkHg2Ll8vEyXLaYnVdPPZQOXiOwuDCuW8/bvlr9cibQibxVls0E6BrGZFlyfIu0grPl1lqVGol03nMS2Lpcnow== k3s-cluster"
vm_size             = "Standard_B2ats_v2"
control_plane_size  = "Standard_B2als_v2"
image               = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
}