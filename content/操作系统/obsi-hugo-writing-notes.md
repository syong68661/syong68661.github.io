+++
title = "Obsidian 到 Hugo 的写作注意事项"
date = 2026-05-16T21:55:00+08:00
lastmod = 2026-05-16T21:55:00+08:00
draft = true
slug = "obsidian-to-hugo-writing-notes"
summary = "记录 Obsidian 写作迁移到 Hugo 时最常见的格式差异和推荐替代写法。"
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

## 不能直接依赖的

- `[[双链]]`
- `![[嵌入]]`

这两类是 Obsidian 语法，Hugo 默认不会把它们当成标准链接来渲染。

## 推荐替代写法

把双链：

```md
[[哈希算法]]
```

改成标准 Markdown：

```md
[哈希算法](/some-path/)
```

把嵌入：

```md
![[image.png]]
```

改成：

```md
![image](./image.png)
```

## 文章时间怎么改

每篇文章最上面的 front matter 里：

```toml
date = 2026-05-16T21:40:00+08:00
lastmod = 2026-05-16T21:40:00+08:00
```

- `date` 控制文章显示时间
- `lastmod` 控制最近修改时间
