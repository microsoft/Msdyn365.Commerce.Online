. $PSScriptRoot\TableOperations.ps1
. $PSScriptRoot\FileOperations.ps1

function New-EcomExtensionPackage {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackagePublisher,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageVersion,

        [Parameter()]
        [String]
        $SdkVersion,

        [Parameter()]
        [String]
        $SskVersion,

        [Parameter()]
        [ValidateSet('Valid', 'Invalid')]
        [String]
        $ValidationStatus,

        [Parameter()]
        [String]
        $PackageDescription
    )

    try {
        $body = @{
            msprov_name       = $PackageName
            msprov_publisher  = $PackagePublisher
            msprov_version    = $PackageVersion
            msprov_sdkversion = $SdkVersion
            msprov_assettype  = 1 # E-Commerce Extension Package
        }

        # Store sskVersion in Additional Properties as JSON
        if ($SskVersion) {
            $body['msprov_additionalproperties'] = (@{ sskversion = $SskVersion } | ConvertTo-Json -Compress)
        }

        # Add optional fields if provided
        if ($ValidationStatus) {
            $statusValue = switch ($ValidationStatus) {
                'Valid'   { 202570000 }
                'Invalid' { 202570001 }
            }
            $body['msprov_commerceextensionasset_validationstatus'] = $statusValue
        }

        if ($PackageDescription) {
            $body['msprov_description'] = $PackageDescription
        }

        Write-Host "Creating e-commerce extension package record: $PackageName ($PackageVersion)"

        $recordId = New-Record -setName 'msprov_commerceextensionassets' -body $body

        Write-Host "Successfully created e-commerce extension package record with ID: $recordId`n`n" -ForegroundColor Green
        return $recordId
    }
    catch {
        Write-Error "Failed to create e-commerce extension package record $PackageName ($PackageVersion): $($_.Exception.Message)`n`n"
        throw
    }
}

function Set-EcomExtensionPackageFile {
    param (
        [Parameter(Mandatory)]
        [System.Guid]
        $PackageId,

        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [String]
        $FilePath,

        [Parameter()]
        [String]
        $ColumnName = 'msprov_payload'
    )

    try {
        $fileInfo = Get-Item -Path $FilePath
        $fileSizeMB = [Math]::Round($fileInfo.Length / 1MB, 2)

        Write-Host "Uploading e-commerce extension package file: $($fileInfo.Name) ($fileSizeMB MB)"

        Set-FileColumnInChunks -setName 'msprov_commerceextensionassets' `
            -id $PackageId `
            -columnName $ColumnName `
            -file $fileInfo

        Write-Host "Successfully uploaded e-commerce extension package file to record: $PackageId`n`n" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to upload e-commerce extension package file: $($_.Exception.Message)`n`n"
        throw
    }
}

function Get-EcomExtensionPackage {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageVersion
    )

    try {
        Write-Host "Querying e-commerce extension package: $PackageName ($PackageVersion)"

        $filter = "?`$filter=msprov_name eq '$PackageName' and msprov_version eq '$PackageVersion' and msprov_assettype eq 1"
        $response = Get-Records -setName 'msprov_commerceextensionassets' -query $filter

        $records = $response.value

        if (-not $records -or $records.Count -eq 0) {
            Write-Host "No e-commerce extension package found: $PackageName ($PackageVersion)" -ForegroundColor Yellow
            return $null
        }

        Write-Host "Found $($records.Count) e-commerce extension package record(s): $PackageName ($PackageVersion)`n`n" -ForegroundColor Green
        return $records
    }
    catch {
        Write-Error "Failed to query e-commerce extension package $PackageName ($PackageVersion): $($_.Exception.Message)`n`n"
        throw
    }
}

function Get-EcomExtensionPackageFile {
    param (
        [Parameter(Mandatory)]
        [System.Guid]
        $PackageId,

        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [String]
        $OutputDirectory,

        [Parameter()]
        [String]
        $ColumnName = 'msprov_payload'
    )

    try {
        Write-Host "Downloading e-commerce extension package file from record: $PackageId"

        $file = Get-FileColumnInChunks -setName 'msprov_commerceextensionassets' `
            -id $PackageId `
            -columnName $ColumnName `
            -outputDirectory $OutputDirectory

        Write-Host "Successfully downloaded e-commerce extension package file: $($file.Name)`n`n" -ForegroundColor Green
        return $file
    }
    catch {
        Write-Error "Failed to download e-commerce extension package file: $($_.Exception.Message)`n`n"
        throw
    }
}
