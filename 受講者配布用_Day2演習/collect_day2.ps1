# Day2 提出物収集スクリプト（提出物作成.bat から呼ばれます）
# 出力CSV（申請一覧・申請中一覧）、判断メモ、手動保存したフローのテキストを
# 1 枚のレポートにまとめて、デスクトップに出力します。

$ErrorActionPreference = 'Stop'

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

Write-Host ''
Write-Host '==== Day2 提出物作成ツール ===='
Write-Host ''

# 作業フォルダを探す（手順書の C:\PAD_Day2 を優先。デスクトップ版もフォールバックで許容）
$candidates = @(
    'C:\PAD_Day2',
    (Join-Path $env:USERPROFILE 'Desktop\PAD演習_Day2')
)
$base = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $base) {
    Write-Host 'エラー: 作業フォルダが見つかりません。' -ForegroundColor Red
    Write-Host '次のいずれかに、出力CSV・フローのテキスト・判断メモを置いてください:'
    foreach ($c in $candidates) { Write-Host ("  - {0}" -f $c) }
    Read-Host '（Enter で終了）'
    exit 1
}

$name = Read-Host '氏名を入力してください（例: 山田太郎）'
if ([string]::IsNullOrWhiteSpace($name)) { $name = '氏名未入力' }

$lines = New-Object System.Collections.Generic.List[string]
function Add-Line([string]$s = '') { $lines.Add($s) }

Add-Line '========================================'
Add-Line ' Day2 提出物レポート（PAD Web自動化）'
Add-Line '========================================'
Add-Line ("氏名        : {0}" -f $name)
Add-Line ("作成日時    : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line ("PC/ユーザー : {0} / {1}" -f $env:COMPUTERNAME, $env:USERNAME)
Add-Line ("対象フォルダ: {0}" -f $base)
Add-Line ''

# 1. 出力CSV
Add-Line '---- 1. 出力CSV（データ行数の自己チェック） ----'
$csvChecks = @(
    @{ Name = '申請一覧.csv';     Expect = 12 },
    @{ Name = '申請中一覧.csv';   Expect = 4 }
)
foreach ($c in $csvChecks) {
    $path = Join-Path $base $c.Name
    if (Test-Path $path) {
        $rows = @((Read-TextSmart $path) -split "\r?\n" | Where-Object { $_.Trim() -ne '' })
        $dataRows = [Math]::Max(0, $rows.Count - 1)   # 先頭は見出し行
        $mark = if ($dataRows -eq $c.Expect) { 'OK' } else { ("要確認（期待 {0} 行）" -f $c.Expect) }
        Add-Line ("  {0,-16} : {1,2} 行  {2}" -f $c.Name, $dataRows, $mark)
    } else {
        Add-Line ("  {0,-16} : (未作成)" -f $c.Name)
    }
}
Add-Line ''

# 2. CSVの中身
foreach ($c in $csvChecks) {
    $path = Join-Path $base $c.Name
    if (Test-Path $path) {
        Add-Line ("---- 2. {0} の中身 ----" -f $c.Name)
        foreach ($ln in (Read-TextSmart $path) -split "\r?\n") { Add-Line ("  {0}" -f $ln) }
        Add-Line ''
    }
}

# 3. 判断メモ（応用課題4）
Add-Line '---- 3. 判断メモ（応用課題4: PAD とクラウドの使い分け） ----'
$memo = Get-ChildItem -Path $base -File -Filter '*メモ*.txt' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($memo) {
    Add-Line ("  ファイル: {0}" -f $memo.Name)
    foreach ($ln in (Read-TextSmart $memo.FullName) -split "\r?\n") { Add-Line ("    {0}" -f $ln) }
} else {
    Add-Line '  警告: 判断メモ（*メモ*.txt）が見つかりません。'
    Add-Line '  → 応用課題4の判断を「判断メモ.txt」として PAD演習_Day2 フォルダに保存してください。'
}
Add-Line ''

# 4. 提出フロー
Add-Line '---- 4. 提出フロー（PAD から Ctrl+A → Ctrl+C で貼り付けたテキスト） ----'
$flows = Get-ChildItem -Path $base -File -Filter 'Day2_*.txt' -ErrorAction SilentlyContinue | Sort-Object Name
if ($flows) {
    foreach ($f in $flows) {
        Add-Line ''
        Add-Line ("======== {0} ========" -f $f.Name)
        foreach ($ln in (Read-TextSmart $f.FullName) -split "\r?\n") { Add-Line $ln }
    }
} else {
    Add-Line ''
    Add-Line '  警告: Day2_*.txt のフローテキストが見つかりません。'
    Add-Line '  → PAD でフローを開き Ctrl+A → Ctrl+C、メモ帳に貼り付けて、'
    Add-Line '     PAD演習_Day2 フォルダ内に「Day2_Web自動化.txt」等の名前で保存し、'
    Add-Line '     もう一度このツールを実行してください。'
}
Add-Line ''
Add-Line '---- 以上 ----'

$outPath = Join-Path ([Environment]::GetFolderPath('Desktop')) ("提出_Day2_{0}.txt" -f $name)
$enc = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllLines($outPath, $lines, $enc)

Write-Host ''
Write-Host '提出レポートを作成しました:' -ForegroundColor Green
Write-Host ("  {0}" -f $outPath)
Write-Host ''
Write-Host 'このファイル1枚を提出してください（スクリーンショットは不要です）。'
Start-Process notepad.exe $outPath
Read-Host '（Enter で終了）'
