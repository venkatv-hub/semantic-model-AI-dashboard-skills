# Install in the Claude apps (web and desktop)

Custom skills are uploaded as ZIP files, one skill per ZIP. Code execution must be enabled
(Settings ▸ Capabilities on individual plans). On Team and Enterprise plans an admin may need
to allow user-created skills.

## Steps

1. Build the ZIPs (one per skill) from the repository root:

   ```bash
   mkdir -p dist
   for d in skills/*/; do (cd skills && zip -rq "../dist/$(basename "$d").zip" "$(basename "$d")"); done
   ```

   On Windows PowerShell:

   ```powershell
   New-Item -ItemType Directory -Force dist | Out-Null
   Get-ChildItem skills -Directory | ForEach-Object {
     Compress-Archive -Path $_.FullName -DestinationPath "dist\$($_.Name).zip" -Force
   }
   ```

2. In Claude, open **Customize ▸ Skills**, click **+**, choose **Create skill ▸ Upload a
   skill**, and upload each ZIP. Start with `bi-dashboard-design`, the builder for your
   platform, and the domain skills you need.
3. Make sure the skills are toggled on.

Common upload errors: the folder name doesn't match the `name` in `SKILL.md`, or the ZIP
doesn't contain the skill folder at its root. The ZIPs built above avoid both.

Reference: [Use skills in Claude](https://support.claude.com/en/articles/12512180-use-skills-in-claude).

## What to expect

In the Claude apps the skills produce the dashboard spec, measures (DAX, Tableau calcs,
LookML), theme files and build sheets. Claude can also generate PBIP, `.tds` or LookML files
for download; open them in your BI tool to finish the build.
