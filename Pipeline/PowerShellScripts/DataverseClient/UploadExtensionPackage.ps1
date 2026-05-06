<#
.SYNOPSIS
    Uploads an e-commerce extension package to Dataverse.

.DESCRIPTION
    Connects to the specified Dataverse environment, reads package metadata from
    the zip filename (name and version), creates an e-commerce extension package
    record in the same table as CSU packages (msprov_commerceextensionassets)
    with asset type 1, and uploads the zip file in chunked mode.

.PARAMETER PackageFilePath
    Full path to the e-commerce extension package zip file (e.g. Msdyn365.Commerce.Online-1.0.0.zip).

.PARAMETER EnvironmentUrl
    The Dataverse environment URL (e.g., https://myorg.crm.dynamics.com/).

.PARAMETER TenantId
    Azure AD tenant ID.

.PARAMETER ClientId
    Azure AD application (client) ID.

.PARAMETER ClientSecret
    Azure AD application client secret. Required if CertificateThumbprint is not provided.

.PARAMETER CertificateThumbprint
    Thumbprint of a certificate for authentication. Preferred over ClientSecret when both are provided.

.PARAMETER PackageName
    Optional override for the package name. If not provided, it is extracted from the zip filename or package.json.

.PARAMETER ValidationStatus
    Validation status to stamp on the package record. Valid values: 'Valid', 'Invalid'.
    Defaults to 'Valid'.
#>
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String]
    $PackageFilePath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $EnvironmentUrl,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $TenantId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ClientId,

    [Parameter()]
    [String]
    $ClientSecret,

    [Parameter()]
    [String]
    $CertificateThumbprint,

    [Parameter()]
    [String]
    $PackageName,

    [Parameter()]
    [String]
    $PackagePublisher,

    [ValidateSet('Valid', 'Invalid')]
    [String]
    $ValidationStatus = 'Valid'
)

$ErrorActionPreference = 'Stop'

Write-Host "Starting e-commerce extension package upload...`n`n"

# ── Load Dataverse client modules ────────────────────────────────────────────
. $PSScriptRoot\Common\Core.ps1
. $PSScriptRoot\Common\CommonFunctions.ps1
. $PSScriptRoot\Operations\ExtensionPackageOperations.ps1

# ── Resolve package metadata ─────────────────────────────────────────────────
$packageFile = Get-Item $PackageFilePath

if ($packageFile.Extension -ne '.zip') {
    throw "PackageFilePath must be a .zip file. Got: $PackageFilePath"
}

# Extract package name and version from zip filename (e.g. Msdyn365.Commerce.Online-1.0.0.zip)
# Also try pattern with underscore from build pipeline (e.g. Msdyn365.Commerce.Online_20260401.1.zip)
if ($packageFile.BaseName -match '^(.+)-(\d+\.\d+\.\d+.*)$') {
    if (-not $PackageName) { $PackageName = $Matches[1] }
    $packageVersion = $Matches[2]
}
elseif ($packageFile.BaseName -match '^(.+)_(.+)$') {
    if (-not $PackageName) { $PackageName = $Matches[1] }
    $packageVersion = $Matches[2]
}
else {
    if (-not $PackageName) { $PackageName = $packageFile.BaseName }
    $packageVersion = '1.0.0'
    Write-Host "Could not parse version from filename, defaulting to 1.0.0" -ForegroundColor Yellow
}

# Try to extract version.json from the zip for SDK version info
$sdkVersion = ''
$tempDir = Join-Path $env:TEMP "ecom_pkg_$(Get-Date -Format 'yyyyMMddHHmmss')"
try {
    Expand-Archive -Path $packageFile.FullName -DestinationPath $tempDir -Force

    $versionJsonPath = Join-Path $tempDir 'version.json'
    if (Test-Path $versionJsonPath) {
        $versionInfo = Get-Content $versionJsonPath -Raw | ConvertFrom-Json
        $sdkVersion = $versionInfo.sdkVersion
        $sskVersion = $versionInfo.sskVersion
    }

    $packageJsonPath = Join-Path $tempDir 'package.json'
    if (Test-Path $packageJsonPath) {
        $packageInfo = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
        if (-not $PackageName -and $packageInfo.name) { $PackageName = $packageInfo.name }
        if ($packageInfo.version) { $packageVersion = $packageInfo.version }
        if (-not $PackagePublisher -and $packageInfo.author) { $PackagePublisher = $packageInfo.author }
    }
}
catch {
    Write-Host "Could not extract metadata from package zip: $($_.Exception.Message)" -ForegroundColor Yellow
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Package file: $($packageFile.Name) ($([Math]::Round($packageFile.Length / 1MB, 2)) MB)"

if ($packageFile.Length -gt 1GB) {
    throw "Package file size exceeds 1 GB limit"
}

if (-not $PackagePublisher) {
    throw "PackagePublisher must be provided either as a parameter or via the 'author' field in package.json"
}

Write-Host "Package info:"
Write-Host "  Name:        $PackageName"
Write-Host "  Publisher:   $PackagePublisher"
Write-Host "  Version:     $packageVersion"
Write-Host "  SDK Version: $sdkVersion"
Write-Host "  SSK Version: $sskVersion"
Write-Host "`n"

# ── Connect to Dataverse ─────────────────────────────────────────────────────
$connectParams = @{
    environmentUrl = $EnvironmentUrl
    tenantId       = $TenantId
    clientId       = $ClientId
}
if ($CertificateThumbprint) { $connectParams.certificateThumbprint = $CertificateThumbprint }
elseif ($ClientSecret)      { $connectParams.clientSecret = $ClientSecret }

Connect @connectParams | Out-Null

Write-Host "Connected as: $((Get-WhoAmI).UserId)`n`n"

# ── Create package record and upload file ────────────────────────────────────
$params = @{
    PackageName      = $PackageName
    PackagePublisher = $PackagePublisher
    PackageVersion   = $packageVersion
    SdkVersion       = $sdkVersion
    SskVersion       = $sskVersion
    ValidationStatus = $ValidationStatus
}

$packageId = New-EcomExtensionPackage @params
Set-EcomExtensionPackageFile -PackageId $packageId -FilePath $packageFile.FullName

Write-Host "SUCCESS: E-commerce extension package uploaded - $PackageName ($packageVersion)`n`n" -ForegroundColor Green
