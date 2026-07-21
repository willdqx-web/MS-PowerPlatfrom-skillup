# Day1 演習用ダミーファイル生成スクリプト
#
# デスクトップに「PAD演習_Day1」フォルダを作り、その中の「01_受信フォルダ」に
# 演習用のダミーファイル 18 個を作成します。
#
# 使い方: このファイルを右クリック →「PowerShell で実行」
# ※ 何度実行しても、毎回きれいな初期状態に戻ります（やり直したいときに再実行してください）

$base  = Join-Path $env:USERPROFILE "Desktop\PAD演習_Day1"
$inbox = Join-Path $base "01_受信フォルダ"

# 既にある場合は作り直す（演習をやり直せるように）
if (Test-Path $base) {
    Remove-Item -Path $base -Recurse -Force
}
New-Item -ItemType Directory -Path $inbox -Force | Out-Null

# 受信フォルダに溜まっている想定のファイル群（図面8 / 検討書5 / 帳票5 = 計18）
$files = @(
    "P001_図面_20260601.pdf",
    "P001_図面_20260612.pdf",
    "P002_図面_20260603.pdf",
    "P002_図面_20260615.pdf",
    "P003_図面_20260605.pdf",
    "P004_図面_20260608.pdf",
    "P004_図面_20260618.pdf",
    "P006_図面_20260610.pdf",
    "P001_検討書_20260602.docx",
    "P002_検討書_20260607.docx",
    "P003_検討書_20260609.docx",
    "P005_検討書_20260614.docx",
    "P006_検討書_20260616.docx",
    "P001_帳票_20260604.xlsx",
    "P002_帳票_20260611.xlsx",
    "P003_帳票_20260613.xlsx",
    "P004_帳票_20260617.xlsx",
    "P006_帳票_20260619.xlsx"
)

foreach ($f in $files) {
    $path = Join-Path $inbox $f
    Set-Content -Path $path -Value "これは演習用のダミーファイルです。( $f )" -Encoding UTF8
}

Write-Host ""
Write-Host "作成しました: $inbox"
Write-Host "ファイル数  : $($files.Count) 個"
Write-Host ""
Write-Host "※ これらは中身が空に近いダミーです。拡張子は本物ですが、開いても意味のある内容はありません。"
Write-Host "   演習ではファイルを「開く」のではなく「探す・移動する・名前を変える」ことだけを行います。"
Write-Host ""
