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

```powershell
hugo new 408/your-topic.md
hugo new cpp/your-topic.md
hugo new linux/your-topic.md
```

Remember to change `draft = true` to `draft = false` when ready.

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
