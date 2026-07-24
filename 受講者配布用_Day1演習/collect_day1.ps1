# Day1 提出物収集スクリプト（提出物作成.bat から呼ばれます）
# 実行結果（フォルダ構成・件数・処理ログ）と、手動で保存したフローのテキストを
# 1 枚のレポートにまとめて、デスクトップに出力します。

$ErrorActionPreference = 'Stop'

# 文字コードを問わず安全にテキストを読む
function Read-TextSmart([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
    }
    try {
        $u = New-Object System.Text.UTF8Encoding($false, $true)
        return $u.GetString($bytes)
    } catch {
        return [System.Text.Encoding]::GetEncoding(932).GetString($bytes)
    }
}

$base = Join-Path $env:USERPROFILE 'Desktop\PAD演習_Day1'

Write-Host ''
Write-Host '==== Day1 提出物作成ツール ===='
Write-Host ''

if (-not (Test-Path $base)) {
    Write-Host "エラー: $base が見つかりません。" -ForegroundColor Red
    Write-Host '先に演習（ダミーファイル生成とフロー作成）を終えてから実行してください。'
    Read-Host '（Enter で終了）'
    exit 1
}

$name = Read-Host '氏名を入力してください（例: 山田太郎）'
if ([string]::IsNullOrWhiteSpace($name)) { $name = '氏名未入力' }

$lines = New-Object System.Collections.Generic.List[string]
function Add-Line([string]$s = '') { $lines.Add($s) }
function Count-Files([string]$p) {
    if (Test-Path $p) { @(Get-ChildItem -Path $p -File -ErrorAction SilentlyContinue).Count } else { -1 }
}

Add-Line '========================================'
Add-Line ' Day1 提出物レポート（PAD ファイル整理）'
Add-Line '========================================'
Add-Line ("氏名        : {0}" -f $name)
Add-Line ("作成日時    : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line ("PC/ユーザー : {0} / {1}" -f $env:COMPUTERNAME, $env:USERNAME)
Add-Line ("対象フォルダ: {0}" -f $base)
Add-Line ''

# 1. 実行結果（フォルダ別ファイル数）と自己チェック
Add-Line '---- 1. 実行結果（フォルダ別ファイル数） ----'
$checks = @(
    @{ Label = '01_受信フォルダ';   Path = (Join-Path $base '01_受信フォルダ');   Expect = 0 },
    @{ Label = '02_整理済\図面';    Path = (Join-Path $base '02_整理済\図面');    Expect = 8 },
    @{ Label = '02_整理済\検討書';  Path = (Join-Path $base '02_整理済\検討書');  Expect = 5 },
    @{ Label = '02_整理済\帳票';    Path = (Join-Path $base '02_整理済\帳票');    Expect = 5 },
    @{ Label = '03_バックアップ';   Path = (Join-Path $base '03_バックアップ');   Expect = 18 }
)
foreach ($c in $checks) {
    $n = Count-Files $c.Path
    if ($n -lt 0) {
        Add-Line ("  {0,-20} : {1,4}  {2}" -f $c.Label, '-', '(未作成)')
    } else {
        $mark = if ($n -eq $c.Expect) { 'OK' } else { ("要確認（期待 {0} 件）" -f $c.Expect) }
        Add-Line ("  {0,-20} : {1,3} 件  {2}" -f $c.Label, $n, $mark)
    }
}
Add-Line ''

# 1-2. 応用課題: 案件コード別
$seiri = Join-Path $base '02_整理済'
$projExpect = [ordered]@{ P001 = 4; P002 = 4; P003 = 3; P004 = 3; P005 = 1; P006 = 3 }
$hasProj = $false
foreach ($p in $projExpect.Keys) { if (Test-Path (Join-Path $seiri $p)) { $hasProj = $true } }
if ($hasProj) {
    Add-Line '---- 1-2. 応用課題: 案件コード別（02_整理済） ----'
    foreach ($p in $projExpect.Keys) {
        $n = Count-Files (Join-Path $seiri $p)
        if ($n -lt 0) {
            Add-Line ("  {0} : (未作成)" -f $p)
        } else {
            $mark = if ($n -eq $projExpect[$p]) { 'OK' } else { ("要確認（期待 {0} 件）" -f $projExpect[$p]) }
            Add-Line ("  {0} : {1,2} 件  {2}" -f $p, $n, $mark)
        }
    }
    Add-Line ''
}

# 2. 処理ログ
Add-Line '---- 2. 処理ログ ----'
$log = Get-ChildItem -Path $base -File -Filter '*ログ*.txt' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($log) {
    Add-Line ("  ファイル: {0}" -f $log.Name)
    foreach ($ln in (Read-TextSmart $log.FullName) -split "\r?\n") { Add-Line ("    {0}" -f $ln) }
} else {
    Add-Line '  （処理ログ *.txt が見つかりません。応用課題3で作成します）'
}
Add-Line ''

# 3. フォルダ構成
Add-Line '---- 3. フォルダ構成 ----'
function Write-Tree([string]$path, [string]$indent) {
    Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
        Add-Line ("{0}[{1}]" -f $indent, $_.Name)
        Write-Tree $_.FullName ($indent + '    ')
        Get-ChildItem -Path $_.FullName -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
            Add-Line ("{0}    {1}" -f $indent, $_.Name)
        }
    }
}
Add-Line ("[{0}]" -f (Split-Path $base -Leaf))
Write-Tree $base '    '
Add-Line ''

# 4. 提出フロー（手動で保存したテキスト）
Add-Line '---- 4. 提出フロー（PAD から Ctrl+A → Ctrl+C で貼り付けたテキスト） ----'
$flows = Get-ChildItem -Path $base -File -Filter 'Day1_*.txt' -ErrorAction SilentlyContinue | Sort-Object Name
if ($flows) {
    foreach ($f in $flows) {
        Add-Line ''
        Add-Line ("======== {0} ========" -f $f.Name)
        foreach ($ln in (Read-TextSmart $f.FullName) -split "\r?\n") { Add-Line $ln }
    }
} else {
    Add-Line ''
    Add-Line '  警告: Day1_*.txt のフローテキストが見つかりません。'
    Add-Line '  → PAD でフローを開き Ctrl+A → Ctrl+C、メモ帳に貼り付けて、'
    Add-Line '     PAD演習_Day1 フォルダ内に「Day1_ファイル整理.txt」等の名前で保存し、'
    Add-Line '     もう一度このツールを実行してください。'
}
Add-Line ''
Add-Line '---- 以上 ----'

$outPath = Join-Path ([Environment]::GetFolderPath('Desktop')) ("提出_Day1_{0}.txt" -f $name)
$enc = New-Object System.Text.UTF8Encoding($true)   # UTF-8 (BOM付き) でメモ帳でも文字化けしない
[System.IO.File]::WriteAllLines($outPath, $lines, $enc)

Write-Host ''
Write-Host '提出レポートを作成しました:' -ForegroundColor Green
Write-Host ("  {0}" -f $outPath)
Write-Host ''
Write-Host 'このファイル1枚を提出してください（スクリーンショットは不要です）。'
Start-Process notepad.exe $outPath
Read-Host '（Enter で終了）'
