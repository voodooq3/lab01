---

 host_key_checking : False
 ansible_user : centos
 ansible_ssh_private_key_file : ~/.ssh/id_rsa
 ansible_ssh_common_args : '-o ProxyCommand="ssh -W %h:%p -q centos@${bastion_ip_adr}"'