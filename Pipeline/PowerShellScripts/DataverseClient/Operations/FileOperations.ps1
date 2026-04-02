function Set-FileColumnInChunks {
    param (
        [Parameter(Mandatory)]
        [string]
        $setName,

        [Parameter(Mandatory)]
        [System.Guid]
        $id,

        [Parameter(Mandatory)]
        [string]
        $columnName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.IO.FileInfo]
        $file
    )

    $uri = '{0}{1}({2})' -f $baseURI, $setName, $id
    $uri += '/{0}?x-ms-file-name={1}' -f $columnName, $file.Name

    $chunkHeaders = $baseHeaders.Clone()
    $chunkHeaders['x-ms-transfer-mode'] = 'chunked'

    $InitializeChunkedFileUploadRequest = @{
        Uri     = $uri
        Method  = 'Patch'
        Headers = $chunkHeaders
    }

    Invoke-RestMethod @InitializeChunkedFileUploadRequest -ResponseHeadersVariable rhv | Out-Null

    $locationUri = $rhv['Location'][0]
    $chunkSize = [int]$rhv['x-ms-chunk-size'][0]

    Write-Host "Chunk size: $([Math]::Round($chunkSize / 1MB, 2)) MB"

    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $totalChunks = [Math]::Ceiling($bytes.Length / $chunkSize)
    $currentChunk = 0

    for ($offset = 0; $offset -lt $bytes.Length; $offset += $chunkSize) {

        $currentChunk++

        $count = if (($offSet + $chunkSize) -gt $bytes.Length) {
            $bytes.Length % $chunkSize
        }
        else {
            $chunkSize
        }

        $lastByte = $offset + ($count - 1)

        $range = 'bytes {0}-{1}/{2}' -f $offset, $lastByte, $bytes.Length

        $contentHeaders = $baseHeaders.Clone()
        $contentHeaders['Content-Range'] = $range
        $contentHeaders['Content-Type'] = 'application/octet-stream'
        $contentHeaders['x-ms-file-name'] = $file.Name

        $UploadFileChunkRequest = @{
            Uri     = $locationUri
            Method  = 'Patch'
            Headers = $contentHeaders
            Body    = [byte[]]$bytes[$offSet..$lastByte]
        }

        Invoke-RestMethod @UploadFileChunkRequest | Out-Null

        Write-Host "Uploaded chunk $currentChunk/$totalChunks"
    }
}

function Get-FileColumnInChunks {
    param (
        [Parameter(Mandatory)]
        [string]
        $setName,

        [Parameter(Mandatory)]
        [System.Guid]
        $id,

        [Parameter(Mandatory)]
        [string]
        $columnName,

        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]
        $outputDirectory
    )

    $uri = '{0}{1}({2})/{3}/$value' -f $baseURI, $setName, $id, $columnName

    $chunkSize = 4 * 1024 * 1024  # 4 MB

    # Use minimal headers for file download (OData headers cause 400 on file endpoints)
    $downloadHeaders = @{
        'Authorization' = $baseHeaders['Authorization']
        'Range'         = 'bytes=0-{0}' -f ($chunkSize - 1)
    }

    $InitialDownloadRequest = @{
        Uri     = $uri
        Method  = 'Get'
        Headers = $downloadHeaders
    }

    $response = Invoke-WebRequest @InitialDownloadRequest

    $fileName = $response.Headers['x-ms-file-name'][0]
    $fileSize = [long]$response.Headers['x-ms-file-size'][0]

    Write-Host "Downloading file: $fileName ($([Math]::Round($fileSize / 1MB, 2)) MB)"
    Write-Host "Chunk size: $([Math]::Round($chunkSize / 1MB, 2)) MB"

    $totalChunks = [Math]::Ceiling($fileSize / $chunkSize)
    $currentChunk = 1

    $fileBytes = [System.Collections.Generic.List[byte]]::new([int]$fileSize)
    $fileBytes.AddRange([byte[]]$response.Content)

    Write-Host "Downloaded chunk $currentChunk/$totalChunks"

    $offset = $response.Content.Length

    while ($offset -lt $fileSize) {

        $currentChunk++

        $lastByte = [Math]::Min($offset + $chunkSize - 1, $fileSize - 1)

        $chunkHeaders = @{
            'Authorization' = $baseHeaders['Authorization']
            'Range'         = 'bytes={0}-{1}' -f $offset, $lastByte
        }

        $DownloadChunkRequest = @{
            Uri     = $uri
            Method  = 'Get'
            Headers = $chunkHeaders
        }

        $response = Invoke-WebRequest @DownloadChunkRequest

        $fileBytes.AddRange([byte[]]$response.Content)
        $offset += $response.Content.Length

        Write-Host "Downloaded chunk $currentChunk/$totalChunks"
    }

    $outputFilePath = Join-Path $outputDirectory $fileName
    [System.IO.File]::WriteAllBytes($outputFilePath, $fileBytes.ToArray())

    Write-Host "File saved to: $outputFilePath"

    return Get-Item $outputFilePath
}
