# Personal Blog

A Hugo-based technical blog designed for long-term growth in:

- 408
- C++
- Linux
- Network
- AI Infra
- Projects
- Source Code Reading

## Local development

Use the installed Hugo binary:

```powershell
& "C:\Users\久居白昼\AppData\Local\Microsoft\WinGet\Packages\Hugo.Hugo.Extended_Microsoft.Winget.Source_8wekyb3d8bbwe\hugo.exe" server -D
```

After you restart your terminal, you should be able to run:

```powershell
hugo server -D
```

Open `http://localhost:1313`.

## Create a new article

See [博客常用操作](#博客常用操作). Use the current leaf bundle format:

```powershell
hugo new "数据结构/1-2 线性表/index.md"
```

## Deploy

1. Create a GitHub repository.
2. Push this project to the `main` branch.
3. In GitHub, go to `Settings > Pages`.
4. Set the source to `GitHub Actions`.
5. The workflow in `.github/workflows/hugo.yaml` will build and deploy the site automatically.

## Before first public launch

Update these fields in `hugo.toml`:

- `baseURL`
- `title`
- `params.author`
- `params.email`
- `params.github`
- `params.location`
- `params.school`

## 博客常用操作

### 创建文章

本博客文章建议使用 leaf bundle 结构：每篇文章一个目录，正文文件固定为 `index.md`，图片放在同一目录下。

```powershell
hugo new "数据结构/1-2 线性表/index.md"
hugo new "计算机网络/4-2 路由算法/index.md"
hugo new "操作系统/3-6 磁盘管理/index.md"
hugo new "计算机组成原理/2-1 数据表示/index.md"
```

常用分类目录：

- `content/数据结构`
- `content/计算机网络`
- `content/操作系统`
- `content/计算机组成原理`

文章写好后，检查 front matter：

```toml
draft = false
slug = "your-article-slug"
summary = "文章摘要"
tags = ["408"]
categories = ["数据结构"]
```

其中 `draft = true` 表示草稿，正式发布前改为 `draft = false`。

### 清理缓存

运行项目自带的清理脚本：

```powershell
.\scripts\clean.ps1
```

该脚本会删除以下 Hugo 生成内容和缓存：

- `.hugo-content`
- `public`
- `public-test`
- `resources`
- `.hugo_build.lock`

如果页面预览异常、Obsidian 链接或图片转换结果不符合预期，可以先清理缓存，再重新启动：

```powershell
.\scripts\clean.ps1
.\scripts\dev.ps1
```
