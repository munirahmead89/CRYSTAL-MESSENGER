
$flutterPath = "C:\src\flutter\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$flutterPath*") {
    $newPath = "$currentPath;$flutterPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added $flutterPath to User PATH."
} else {
    Write-Host "$flutterPath is already in User PATH."
}
