function Get-RadiansFromDegrees
{
    param 
    (
        [double]$degrees
    )

    [double]$degToRadFactor = [Math]::PI / 180

    Write-Output ($degrees * $degToRadFactor)
}

function Get-DegreesFromRadians
{
param 
    (
        [double]$radians
    )

    [double]$radToDegFactor = 180 / [Math]::PI

    Write-Output ($radians * $radToDegFactor)
}

function Get-KilometersFromMiles
{
    #1 km: 0.62137119 mi
    #1 mile: 1.609344 km

    param 
    (
        [double]$miles
    )

    [double]$kilometers = $miles * 1.609344

    Write-Output $kilometers
}


function Get-GeoLocationFromStartUsingBearingAndDistance
{
    param (
        [double]$startLatitude
        ,
        [double]$startLongitude
        ,
        [double]$bearingInRadians
        ,
        [double]$distanceInMiles
    )


    $distanceInKilometers = Get-KilometersFromMiles $distanceInMiles
    [double] $radiusEarthKilometres = 6371.01
    $distRatio = $distanceInKilometers / $radiusEarthKilometres
    $distRatioSine = [Math]::Sin($distRatio)
    $distRatioCosine = [Math]::Cos($distRatio)

    $startLatRad = Get-RadiansFromDegrees $startLatitude
    $startLonRad = Get-RadiansFromDegrees $startLongitude

    $startLatCos = [Math]::Cos($startLatRad)
    $startLatSin = [Math]::Sin($startLatRad)

    $endLatRads = [Math]::Asin(($startLatSin * $distRatioCosine) + ($startLatCos * $distRatioSine * [Math]::Cos($bearingInRadians)))

    $endLonRads = $startLonRad + [Math]::Atan2([Math]::Sin($bearingInRadians) * $distRatioSine * $startLatCos, $distRatioCosine - $startLatSin * [Math]::Sin($endLatRads))

    $newGeoLocation = "" | Select-Object Latitude,Longitude
    $newGeoLocation.Latitude = Get-DegreesFromRadians $endLatRads
    $newGeoLocation.Longitude = Get-DegreesFromRadians $endLonRads

    Write-Output $newGeoLocation

}

