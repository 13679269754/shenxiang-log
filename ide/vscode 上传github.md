
# 怎么将vscode的代码同步到github，进行开源
==========================

[toc]

[zhuanlan.zhihu.com](https://zhuanlan.zhihu.com/p/678233404)余汉波经济专业技术资格证持证人关注他

将 VS Code 中的代码同步到 GitHub 需要几个步骤。这里假设你已经有一个 GitHub 账户，并且在你的电脑上已经安装了 Git。以下是同步代码到 GitHub 的基本步骤：

## 一.在 GitHub 上创建一个新仓库

--------------------

1. 登录你的 GitHub 账户。

2. 在右上角，点击 "+" 图标，然后选择 "New repository"。

3. 填写仓库名称，可选择是否添加描述。

4. 选择是否要将仓库设为公开或私有。

5. 可选地，你可以初始化仓库，添加 README 文件、.gitignore 或选择许可证。

6. 点击 "Create repository"。

## 二. 在本地初始化 Git 仓库
----------------

在 VS Code 中，打开你想要上传到 GitHub 的项目文件夹，然后打开终端（通常是在菜单栏中的"视图"-\>"终端"），执行以下命令：
```bash
    git init
    git add .
    git commit -m "Initial commit"
```
这些命令会初始化一个新的 Git 仓库，添加所有文件，并进行首次提交。
![](https://cubox.pro/c/filters:no_upscale()?imageUrl=https%3A%2F%2Fpic2.zhimg.com%2Fv2-aba02363cac7e0d4cad7262b62dead4d_b.jpg&valid=true)

## 三. 将本地仓库与 GitHub 仓库关联
---------------------

在你的 GitHub 仓库页面，你会找到用来关联本地仓库的 URL。复制它，然后在 VS Code 的终端中执行以下命令（请替换 \<your-repository-url\> 为你的实际仓库 URL）：
```bash
    git remote add origin <your-repository-url>（https://github.com/13679269754/sx-log.git）
    git branch -M main
    git push -u origin main
```
这些命令将本地仓库关联到 GitHub 上的仓库，并将代码推送到 GitHub。

## 四. 今后的同步
--------

在未来，每当你完成代码更改并希望同步到 GitHub 时，只需执行以下命令：

```bash
    git add .
    git commit -m "Your commit message"
    git push
```
这些命令将新更改添加到本地 Git 仓库，创建一个新的提交，并将这些更改推送到 GitHub。

注意事项
----git push

* 确保你在本地仓库的根目录下执行这些命令。

* 提交信息应该是描述性的，让其他人知道你做了什么更改。

* 如果你的 GitHub 仓库不是空的（例如，如果你初始化时添加了 README），你可能需要先拉取远程仓库的内容，使用命令 git pull origin main。

如果你还没有在电脑上配置 Git，你需要先设置你的 Git 用户名和邮箱：

```bash

    git config --global user.name "Your Name"
    git config --global user.email "youremail@example.com"

```

这些是将 VS Code 中的代码同步到 GitHub 的基本步骤。如果你在操作过程中遇到任何问题，可以查阅 Git 和 GitHub 的官方文档，或者在社区寻求帮助。


## 报错处理

**报错1**
```bash
To https://github.com/13679269754/sx-log.git  ! [rejected]    main -> main (fetch first) error: failed to push some refs to 'https://github.com/13679269754/sx-log.git' hint: Updates were rejected because the remote contains work that you do hint: not have locally. This is usually caused by another repository pushing hint: to the same ref. You may want to first integrate the remote changes hint: (e.g., 'git pull ...') before pushing again. hint: See the 'Note about fast-forwards' in 'git push --help' for details.

```

你可以按照以下步骤解决这个问题：

1. 首先，使用git pull命令将远程仓库的更改集成到你的本地仓库中。  
`git pull origin main`
2. 这将从远程仓库的main分支拉取最新的更改并尝试合并到你的本地main分支。  
3. 如果有冲突，你需要手动解决冲突。Git会在冲突的文件中添加标记，告诉你需要手动解决冲突的部分。打开冲突文件，并根据需要修改它们。  

---

**报错2**

```bash

From https://github.com/13679269754/shenxiang-log  * branch      main    -> FETCH_HEAD fatal: refusing to merge unrelated histories

```

使用以下命令强制合并远程仓库的main分支到你的本地仓库的main分支：  
`git merge --allow-unrelated-histories origin/main`

**错误3** 

```bash

remote: error: Trace: a3fc82589ed79daefe85319f76f7d79694ff50ca3b48085fd431fd86c14a71ce
remote: error: See https://gh.io/lfs for more information.
remote: error: File PDF/社会心理学 (戴维·迈尔斯,David Myers,侯玉波,乐国安,张智勇) (Z-Library).pdf is 242.45 MB; this exceeds GitHub's file size limit of 100.00 MB
remote: error: File PDF/MySQL技术内幕InnoDB存储引擎第五版.pdf is 209.99 MB; this exceeds GitHub's file size limit of 100.00 MB
remote: error: GH001: Large files detected. You may want to try Git Large File Storage - https://git-lfs.github.com.
To https://github.com/13679269754/shenxiang-log.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'https://github.com/13679269754/shenxiang-log.git'

```

1. 安装Git Large File Storage。你可以按照Git Large File Storage的官方文档进行安装。  
初始化Git Large File Storage。在你的仓库目录中，运行以下命令：
`git lfs install`
这将初始化Git Large File Storage并配置你的仓库。  

2. 将你的大文件添加到Git Large File Storage中。运行以下命令将你的大文件添加到Git Large File Storage中：
`git lfs track "*.pdf"`
这将告诉Git Large File Storage跟踪所有以.pdf结尾的文件。你可以根据需要调整文件模式。  

3. 提交你的更改。使用以下命令提交你的更改：
```bash
git add .gitattributes
git add --force "*.pdf"
git commit -m "Add large files to Git Large File Storage"
```
这将将你的大文件添加到Git Large File Storage中，并将它们添加到你的仓库中。

4. 最后，推送你的仓库到GitHub。使用以下命令推送你的仓库到GitHub：
`git push origin main`

---


[跳转到 Cubox 查看](https://cubox.pro/my/card?id=7176903205958190342)
