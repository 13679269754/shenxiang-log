| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-4月-22 | 2025-4月-22  |
| ... | ... | ... |
---
# aansible-galaxy安装

[toc]


 在安装 `ansible-galaxy` 之前，你需要确保已经安装了 Ansible。通常，`ansible-galaxy` 是作为 Ansible 的一部分被安装的。

  
  

*   **基于 Debian 或 Ubuntu 系统**

  

```
sudo apt update
sudo apt install ansible 
```

  

*   **基于 CentOS 或 RHEL 系统**

  

```
sudo yum install epel-release
sudo yum install ansible 
```

  

安装完成后，你可以通过以下命令验证 `ansible-galaxy` 是否可用：

```bash
ansible-galaxy --version
```
  

`ansible-galaxy` 本身主要用于管理 Ansible 角色（Roles），而不是直接获取完整的 playbook，但它能为你获取别人编写的角色，这些角色可以集成到你的 playbook 中，从而简化 playbook 的编写过程。下面详细介绍具体情况：

  
  

*   **角色（Roles）**：角色是 Ansible 中一种组织和复用代码的方式，它将相关的任务、变量、模板等文件按照特定的目录结构组织在一起。例如，一个管理 Apache 服务的角色可能包含安装 Apache、配置 Apache 以及启动服务等任务。
*   **Playbook**：Playbook 是一个 YAML 文件，用于定义一系列的任务，它可以调用一个或多个角色来完成特定的自动化任务。

  
  
  

*   **搜索角色**：你可以在 [Ansible Galaxy 网站](https://galaxy.ansible.com/)上搜索你需要的角色，也可以使用命令行进行搜索。例如，搜索 `nginx` 相关的角色：

  

```
ansible-galaxy search nginx 
```

  

*   **安装角色**：找到合适的角色后，使用以下命令进行安装。例如，安装 `geerlingguy.nginx` 角色：

  

```
ansible-galaxy install geerlingguy.nginx 
```

默认情况下，角色会被安装到 `/etc/ansible/roles` 目录下。你也可以通过 `--roles-path` 参数指定安装路径：

  

```
ansible-galaxy install geerlingguy.nginx --roles-path ./my_roles 
```

  

安装好角色后，你可以在 playbook 中调用这些角色。以下是一个简单的 playbook 示例，调用 `geerlingguy.nginx` 角色来安装和配置 Nginx：

  

```
---
- name: Install and configure Nginx
  hosts: web_servers
  become: true
  roles:
    - geerlingguy.nginx 
```

在这个示例中，`hosts` 指定了要执行任务的目标主机，`roles` 部分列出了要调用的角色。

虽然 `ansible-galaxy` 不能直接获取完整的 playbook，但通过获取和使用角色，你可以快速搭建起功能丰富的 playbook，提高自动化任务的开发效率。

  