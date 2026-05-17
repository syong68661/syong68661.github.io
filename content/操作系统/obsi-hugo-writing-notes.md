+++
title = "Obsidian 到 Hugo 的写作注意事项"
date = 2026-05-16T21:55:00+08:00
lastmod = 2026-05-16T21:55:00+08:00
draft = false
slug = "obsidian-to-hugo-writing-notes"
summary = "记录 Obsidian 写作迁移到 Hugo 时常见语法差异，以及当前项目已支持的兼容方式。"
tags = ["Hugo", "Obsidian", "写作"]
categories = ["操作系统"]
+++

## 可以直接用的

- `#` 到 `######` 标题
- `**加粗**`
- `*斜体*`
- `-` 和 `1.` 列表
- 代码块
- 表格
- `==高亮==`

## 当前项目已兼容的 Obsidian 语法

- `[[双链]]`
- `[[页面名|别名]]`
- `[[页面名#标题]]`
- `[[页面名#标题|别名]]`
- `![[image.png]]`
- `> [!note]`
- `> [!tip]`
- `> [!warning]`

## 它是怎么工作的

当前项目在构建前会运行：

- [scripts/convert-obsidian.ps1](/e:/software/my-blog/scripts/convert-obsidian.ps1)

它会自动做这些转换：

- `![[image.png]]` -> `![image](image.png)`
- `[[页面名]]` -> 解析成站内链接
- `[[页面名|别名]]` -> 解析成带别名的站内链接
- `[[页面名#标题]]` -> 解析成带锚点的站内链接
- `> [!note]` -> 解析成提示块

## 推荐写法示例

双链：

```md
[[3.2 内存分区管理]]
[[3.2 内存分区管理|内存分区]]
[[3.2 内存分区管理#2. 结构/组成]]
```

图片嵌入：

```md
![[IMG_20260516_172639.jpg]]
```

Callout：

```md
> [!note] 重点
> 这是一个提示块
```

## 文章时间怎么改

每篇文章最上面的 front matter 里：

```toml
date = 2026-05-16T21:40:00+08:00
lastmod = 2026-05-16T21:40:00+08:00
```

- `date` 控制文章显示时间
- `lastmod` 控制最近修改时间

## 本地预览

如果你想在启动 Hugo 前自动转换 Obsidian 语法，可以执行：

```powershell
.\scripts\dev.ps1
```
