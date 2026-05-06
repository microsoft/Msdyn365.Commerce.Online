function Get-WhoAmI {
    $WhoAmIRequest = @{
        Uri     = $baseURI + 'WhoAmI'
        Method  = 'Get'
        Headers = $baseHeaders
    }

    Invoke-RestMethod @WhoAmIRequest
}
