function Get-Records {
    param (
        [Parameter(Mandatory)]
        [String]
        $setName,

        [Parameter(Mandatory)]
        [String]
        $query
    )

    $uri = $baseURI + $setName + $query

    # Header for GET operations that have annotations
    $getHeaders = $baseHeaders.Clone()
    $getHeaders.Add('If-None-Match', $null)
    $getHeaders.Add('Prefer', 'odata.include-annotations="*"')

    $RetrieveMultipleRequest = @{
        Uri     = $uri
        Method  = 'Get'
        Headers = $getHeaders
    }

    Invoke-RestMethod @RetrieveMultipleRequest
}

function New-Record {
    param (
        [Parameter(Mandatory)]
        [String]
        $setName,

        [Parameter(Mandatory)]
        [hashtable]
        $body
    )

    $postHeaders = $baseHeaders.Clone()

    $CreateRequest = @{
        Uri     = $baseURI + $setName
        Method  = 'Post'
        Headers = $postHeaders
        Body    = ConvertTo-Json $body
    }

    Invoke-RestMethod @CreateRequest -ResponseHeadersVariable rh | Out-Null
    $url = $rh['OData-EntityId']
    $selectedString = Select-String -InputObject $url -Pattern '(?<=\().*?(?=\))'
    return [System.Guid]::New($selectedString.Matches.Value.ToString())
}

function Get-Record {
    param (
        [Parameter(Mandatory)]
        [String]
        $setName,

        [Parameter(Mandatory)]
        [Guid]
        $id,

        [String]
        $query
    )

    $uri = $baseURI + $setName
    $uri = $uri + '(' + $id.Guid + ')' + $query

    $getHeaders = $baseHeaders.Clone()
    $getHeaders.Add('If-None-Match', $null)
    $getHeaders.Add('Prefer', 'odata.include-annotations="*"')

    $RetrieveRequest = @{
        Uri     = $uri
        Method  = 'Get'
        Headers = $getHeaders
    }

    Invoke-RestMethod @RetrieveRequest
}

function Update-Record {
    param (
        [Parameter(Mandatory)]
        [String]
        $setName,

        [Parameter(Mandatory)]
        [Guid]
        $id,

        [Parameter(Mandatory)]
        [hashtable]
        $body
    )

    $uri = $baseURI + $setName
    $uri = $uri + '(' + $id.Guid + ')'

    # Header for Update operations
    $updateHeaders = $baseHeaders.Clone()
    $updateHeaders.Add('If-Match', '*') # Prevent Create

    $UpdateRequest = @{
        Uri     = $uri
        Method  = 'Patch'
        Headers = $updateHeaders
        Body    = ConvertTo-Json $body
    }

    Invoke-RestMethod @UpdateRequest
}

function Remove-Record {
    param (
        [Parameter(Mandatory)]
        [String]
        $setName,

        [Parameter(Mandatory)]
        [Guid]
        $id
    )

    $uri = $baseURI + $setName
    $uri = $uri + '(' + $id.Guid + ')'

    $DeleteRequest = @{
        Uri     = $uri
        Method  = 'Delete'
        Headers = $baseHeaders
    }

    Invoke-RestMethod @DeleteRequest
}
