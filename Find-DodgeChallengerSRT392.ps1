#$uri = "http://www.ramtrucks.com/inventory/?modelYearCode=IUT201713&radius=200&ref=details"
#http://www.ramtrucks.com/inventory/?modelYearCode=IUT201713&radius=200&ref=details
#http://www.ramtrucks.com/monroney/MonroneyXMLServlet?Vin=1C6RR7YT7HS517517


#DEALER URL for Challenger
#http://www.dodge.com/hostd/getlocatedealers.json?zipCode=55374&zipDistance=25&isDodge=Y&modelYearCode=IUD201703
#2017 INVENTORY CALL FOR ALL DEALERS
#http://www.dodge.com/hostd/inventory/getinventoryresults.json?attributes=drive:RWD&includeIncentives=N&matchType=X&modelYearCode=IUD201703&pageNumber=1&pageSize=10&radius=25&sortBy=0&variation=SRT%AE%20392,SRT%AE%20HELLCAT,392%20HEMI%20SCAT%20PACK%20SHAKER&zip=55374
#2016 INVENTORY CALL FOR ALL DEALERS
#http://www.dodge.com/hostd/inventory/getinventoryresults.json?includeIncentives=N&matchType=P&modelYearCode=IUD201603&pageNumber=1&pageSize=10&radius=25&sortBy=0&variation=SRT%AE%20392&zip=55374
#INVENTORY CALL FOR SPECIFIC DEALER
#http://www.dodge.com/hostd/inventory/getinventoryresults.json?attributes=drive:RWD&dealerCodes=68978&includeIncentives=N&matchType=X&modelYearCode=IUD201703&pageNumber=1&pageSize=10&radius=25&sortBy=0&variation=SRT%AE%20392,SRT%AE%20HELLCAT,392%20HEMI%20SCAT%20PACK%20SHAKER&zip=55374
#BUILD SPEC CALL FOR VIN
#http://www.dodge.com/monroney/MonroneyXMLServlet?Vin=2C3CDZFJXHH501771
#WINDOW STICKER GENERATOR FOR VIN
#http://www.dodge.com/hostd/windowsticker/getWindowStickerPdf.do?vin=2C3CDZFJXHH501771

#$zipCode = "55374"
#$zipCode = "66160"
#$zipCode = "37222"
#$zipCode = "72901"

#$uri = "https://maps.googleapis.com/maps/api/geocode/json?latlng=45.7818981,-108.6337238,12&key=AIzaSyDerL9gcldy1lQnapAy2MWZo7rcK4Ndxlo"
#$uri = "https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&key=AIzaSyDerL9gcldy1lQnapAy2MWZo7rcK4Ndxlo"
#$uri = "https://maps.googleapis.com/maps/api/geocode/json?latlng=45.211481,-93.586483&key=AIzaSyDerL9gcldy1lQnapAy2MWZo7rcK4Ndxlo"

#Far West/North Coordinate
#$uri = "https://maps.googleapis.com/maps/api/geocode/json?latlng=47.9096693,-124.6408848&key=AIzaSyDerL9gcldy1lQnapAy2MWZo7rcK4Ndxlo"
#Far East/North Coordinate: 46.7978251772444,-69.0693246703974
#Eastern Boundary 44.829664 (Latitude)
#Southern Boundary -81.8584042 (Longitude)

#2016
#$modelYearCode = "IUD201603"
#2017
$modelYearCode = "IUD201703"

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

function Get-ZipCodeFromCoord
{
    param ( $coordItem )
    $uri = "https://maps.googleapis.com/maps/api/geocode/json?latlng=$($coordItem.Latitude),$($coordItem.Longitude)&key=AIzaSyDerL9gcldy1lQnapAy2MWZo7rcK4Ndxlo"
    $result = Invoke-WebRequest -Uri $uri
    $geoData = $result.Content | ConvertFrom-Json
    Write-Output ($geoData.results[0].address_components | Where-Object { $_.types -eq "postal_code" }).short_name
}

$coordList = @()

$startLat = 47.9096693
$startLon = -124.640884

$westLat = 47.9096693
$westLon = -124.640884

#$startLat = 45.0150381823373
#$startLon = -124.640884

$boundriesHit = $false
$heightCount = 0
$loopCount = 0
do 
{
    
    #if ( $startLat -lt 44.829644 ) 
    if ( $loopCount -eq 30 )
    {
        $loopCount = 0
        Write-Verbose "Hit East Boundary: $($startLat),$($startLon)" -Verbose
        $return = Get-GeoLocationFromStartUsingBearingAndDistance $westLat $westLon (Get-RadiansFromDegrees 180) 100
    #    Write-Verbose "Out East Boundary: $($return.Latitude),$($return.Longitude)" -Verbose
        Write-Output "$($return.Latitude),$($return.Longitude)"
        $coordList += $return
        $startLat = $return.Latitude
        $startLon = $return.Longitude
        $westLat = $return.Latitude
        $westLon = $return.Longitude

        $heightCount++
    }

    if ( $heightCount -lt 14 ) 
    {
        #Write-Verbose "In: $($startLat),$($startLon)" -Verbose
        $return = Get-GeoLocationFromStartUsingBearingAndDistance $startLat $startLon (Get-RadiansFromDegrees 90) 100
        #Write-Verbose "Out: $($return.Latitude),$($return.Longitude)" -Verbose
        Write-Output "$($return.Latitude),$($startLon)"
        $coordList += $return
        $startLat = $return.Latitude
        $startLon = $return.Longitude

        #if ( ( $startLat -lt 44.829644 ) -and ( $startLon -gt -81.8584042 ) ) { $boundriesHit = $true }
    }
    $loopCount++
}
while ( $heightCount -le 14 ) 

$zipCodeList = @()
foreach ( $coordItem in $coordList ) 
{
    $zipCode = Get-ZipCodeFromCoord $coordItem
    if ( $zipCode ) 
    {
        $item = "" | Select-Object ZipCode,Latitude,Longitude
        $item.ZipCode = $zipCode
        $item.Latitude = $coordItem.Latitude
        $item.Longitude = $coordItem.Longitude
        $zipCodeList += $item
    }
    
}

if ( Test-Path Variable:ZipCodeList )
{
	$zipCodeList | Export-Clixml "C:\Temp\Challenger\zipCodeList.clixml"
} else {
	$zipCodeList = Import-Clixml "C:\Temp\Challenger\zipCodeList.clixml"
}

$allDealerList = @{}
#Dealer Gathering
foreach ( $zipCode in $zipCodeList ) 
{
    if ( $zipCode.ZipCode.Length -eq 5 ) 
    {
        $dealersDownloaded = 0
        $skippedDealers = 0
        Write-Verbose "Getting Dealer Data for $($zipCode.ZipCode)" -Verbose
        $uri = "http://www.dodge.com/hostd/getlocatedealers.json?zipCode=$($zipCode.ZipCode)&zipDistance=200&isDodge=Y&modelYearCode=$($modelYearCode)"
        $result = Invoke-WebRequest -Uri $uri
        $dealerData = $result.Content | ConvertFrom-Json
        foreach ( $dealer in $dealerData.data.dealers )
        {
            if ( -not ( $allDealerList.ContainsKey($dealer.DealerCode) ) )
            {
                $allDealerList.Add($dealer.DealerCode, $dealer)
                $dealersDownloaded++
            } else {
                $skippedDealers++
            }
        }
    }
    Write-Verbose "Downloaded $($dealersDownloaded) and skipped $($skippedDealers)" -Verbose
}

if ( Test-Path Variable:allDealerList )
{
	$allDealerList | Export-Clixml "C:\Temp\Challenger\allDealerList.clixml"
} else {
	$allDealerList = Import-Clixml "C:\Temp\Challenger\allDealerList.clixml"
}

foreach ( $dealerKey in $allDealerList.Keys ) 
{

    $carsDownloaded = 0
    Write-Verbose "Getting Data for $($allDealerList[$dealerKey].name)" -Verbose

    $uri = "http://www.dodge.com/hostd/inventory/getinventoryresults.json?attributes=drive:RWD&dealerCodes=$($dealerKey)&includeIncentives=N&matchType=X&modelYearCode=$($modelYearCode)&pageNumber=1&pageSize=10&radius=50&sortBy=0&variation=SRT%AE%20392,SRT%AE%20HELLCAT,392%20HEMI%20SCAT%20PACK%20SHAKER&zip=$($allDealerList[$dealerKey].Zip.Substring(0,5))"
    
    $result = Invoke-WebRequest -Uri $uri

    $inventoryData = $result.Content | ConvertFrom-Json

    $numMatches = $inventoryData.result.data.metadata.exactMatchCount

    $totalPage = [Math]::Ceiling($numMatches / 10)
	if ( -not ( Test-Path "C:\Temp\RAM\Inventory_$($dealerKey)_Page$($totalPage).clixml" ) )
	{
    $inventoryData | Export-Clixml -Path "C:\Temp\Challenger\Inventory_$($dealerKey)_Page1.clixml"

    foreach ( $vehicle in $inventoryData.result.data.vehicles )
    {
            
        if ( -Not ( Test-Path -Path "C:\Temp\Challenger\$($vehicle.vin).pdf" ) ) 
        {
            $carsDownloaded++
            $windowStickerURI = "http://www.dodge.com/hostd/windowsticker/getWindowStickerPdf.do?vin=$($vehicle.vin)"
            $stickerName = "C:\Temp\Challenger\$($vehicle.vin).pdf"
            Invoke-WebRequest -Uri $windowStickerURI -OutFile $stickerName
        
            $OptionsXmlUri = "http://www.dodge.com/monroney/MonroneyXMLServlet?Vin=$($vehicle.vin)"
            $optionsName = "C:\Temp\Challenger\$($vehicle.vin)_Options.xml"
            Invoke-WebRequest -Uri $OptionsXmlUri -OutFile $optionsName

            $dealerURL = $allDealerList[$dealerKey].url #($dealerData.data.dealers | Where-Object { $_.dealerCode -eq $vehicle.dealerCode }).url
            $dealerURI = "$($dealerURL)/catcher.esl?vin=$($vehicle.vin)"
            $dealerName = "C:\Temp\Challenger\$($vehicle.vin).htm"
            Invoke-WebRequest -Uri $dealerURI -OutFile $dealerName
            $dealerContent = Get-Content $dealerName
            $lowPrice = "0"
            foreach ( $line in $dealerContent ) 
            {
                #Write-Verbose "Processing: $($line)" -Verbose
                if ( $line.Contains("<span class=`"internetPrice") )
                {
                    $lowPrice = $line
                }
                if ( $line.Contains("<span class=`"askingPrice") ) 
                {
                    $lowPrice = $line            
                }
                if ( $line.Contains("<span class=`"stackedConditionalFinal") ) 
                {
                    $lowPrice = $line            
                }
        
            }
            if ( $lowPrice -ne "0" ) 
            {
                Write-Output $lowPrice | Out-File -FilePath "C:\Temp\Challenger\$($vehicle.vin).txt" -Force -Encoding ascii
            }
        }
    }

    for ( $pageNum = 2; $pageNum -le $totalPage; $pageNum++ ) 
    {
        $uri = "http://www.dodge.com/hostd/inventory/getinventoryresults.json?attributes=drive:RWD&dealerCodes=$($dealerKey)&includeIncentives=N&matchType=X&modelYearCode=$($modelYearCode)&pageNumber=$($pageNum)&pageSize=10&radius=50&sortBy=0&variation=SRT%AE%20392,SRT%AE%20HELLCAT,392%20HEMI%20SCAT%20PACK%20SHAKER&zip=$($allDealerList[$dealerKey].Zip.Substring(0,5))"

        $result = Invoke-WebRequest -Uri $uri

        $inventoryData = $result.Content | ConvertFrom-Json
        $inventoryData | Export-Clixml -Path "C:\Temp\Challenger\Inventory_$($dealerKey)_Page$($pageNum).clixml"

        foreach ( $vehicle in $inventoryData.result.data.vehicles )
        {
            if ( -Not ( Test-Path -Path "C:\Temp\Challenger\$($vehicle.vin).pdf" ) ) 
            {
                $carsDownloaded++
                $windowStickerURI = "http://www.dodge.com/hostd/windowsticker/getWindowStickerPdf.do?vin=$($vehicle.vin)"
                $stickerName = "C:\Temp\Challenger\$($vehicle.vin).pdf"
                Invoke-WebRequest -Uri $windowStickerURI -OutFile $stickerName
    
                $OptionsXmlUri = "http://www.dodge.com/monroney/MonroneyXMLServlet?Vin=$($vehicle.vin)"
                $optionsName = "C:\Temp\Challenger\$($vehicle.vin)_Options.xml"
                Invoke-WebRequest -Uri $OptionsXmlUri -OutFile $optionsName
    
                $dealerURL = $allDealerList[$dealerKey].url #($dealerData.data.dealers | Where-Object { $_.dealerCode -eq $vehicle.dealerCode }).url
                $dealerURI = "$($dealerURL)/catcher.esl?vin=$($vehicle.vin)"
                $dealerName = "C:\Temp\Challenger\$($vehicle.vin).htm"
                Invoke-WebRequest -Uri $dealerURI -OutFile $dealerName
                $dealerContent = Get-Content $dealerName
                $lowPrice = "0"
                foreach ( $line in $dealerContent ) 
                {
                    #Write-Verbose "Processing: $($line)" -Verbose
                    if ( $line.Contains("<span class=`"internetPrice") )
                    {
                        $lowPrice = $line
                    }
                    if ( $line.Contains("<span class=`"askingPrice") ) 
                    {
                        $lowPrice = $line            
                    }
                    if ( $line.Contains("<span class=`"stackedConditionalFinal") ) 
                    {
                        $lowPrice = $line            
                    }
        
                }
                if ( $lowPrice -ne "0" ) 
                {
                    Write-Output $lowPrice | Out-File -FilePath "C:\Temp\Challenger\$($vehicle.vin).txt" -Force -Encoding ascii
                }
            }
        }
    }
	}
    Write-Verbose "Cars downloaded for $($allDealerList[$dealerKey].name) in $($allDealerList[$dealerKey].state) = $($carsDownloaded)" -Verbose
}

#USE to FETCH Window Sticker PDF
#http://www.ramtrucks.com/hostd/windowsticker/getWindowStickerPdf.do?vin=$($jsonData.result.data.vehicles[0].vin)

#USE to fetch STOCK image.
#http://www.ramtrucks.com/mediaserver/iris?$($jsonData.result.data.vehicles[0].extImage)

#USE to go to Dealer Site
#$($dealerData.data.dealers[0].url)/catcher.esl?vin=$($jsonData.result.data.vehicles[0].vin)

#http://www.cornerstonechrysler.com/apis/mycars/v1/profiles/589a1a45e4b04445e6114f6f/vehicles?statusType=RECENTLY_VIEWED&pageSize=20&referrer=%2Fnew%2FRam%2F2017-Ram-1500-Elk%2BRiver%2BMN%2B-93f0af7f0a0e0ae8595b246cd8bcdee6.htm&_=1486660266532


#$uri = "http://www.cornerstonechrysler.com/catcher.esl?vin=1C6RR7YT7HS517517"
#$result = Invoke-WebRequest -Uri $uri -SessionVariable mySession

#This NO WORKY
#$uri = "http://www.rosevillechryslerjeepdodge.net/apis/mycars/v1/profiles"
#$result = Invoke-WebRequest -Uri $uri -SessionVariable newVar -Method Post -Headers @{"MyCarsAction"="create"}

#AHH, this looks good!!!!
#$OptionsXmlUri = "http://www.ramtrucks.com/monroney/MonroneyXMLServlet?Vin=1C6RR7YT7HS517517"
#$optionsName = "C:\Temp\RAM\1C6RR7YT7HS517517_Options.xml"
#Invoke-WebRequest -Uri $OptionsXmlUri -OutFile $optionsName




#Engine Codes
# "EZA" was the first 5.7L Hemi
# "EZB" was the first 5.7L Hemi with MDS
# "EZC" is the new 2nd gen 5.7L VVT without MDS
# "EZD" is the new 2nd gen 5.7L VVT with MDS 
# "EZE" is the HEV 5.7 that was in the Durango/Aspen
# "EZH" is a revised version of the 5.7L VVT MDS that replaced "EZD" fall of 2008 