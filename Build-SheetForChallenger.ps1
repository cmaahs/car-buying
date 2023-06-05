Write-Verbose "Gathering Options" -Verbose
function RemoveChars
{
 param ( $in )
 $out = ((($in.Replace(" ", "")).Replace("'","")).Replace("®","")).Replace("™","")
 Write-Output $out
}

$buildOptionsTime = Measure-Command {
$xmlFiles = Get-ChildItem -Filter *.xml

$uniqueOptionCodes = @()

foreach ( $file in $xmlFiles )
{
	[xml]$xmlData = Get-Content $file
	if ( $xmlData.MONRONEY.VINYEAR -eq "17" )
	{
		foreach ( $option in $xmlData.MONRONEY.OPTIONALEQUIPMENT.OPTION )
		{
			$item = "" | Select-Object BulletCode,OptionCode,Price,Description
			$item.BulletCode = $option.BULLETINCODE
			$item.OptionCode = $option.OPTIONCODE
			$item.Price = $option.PRICE
			$item.Description = $option.DESCRIPTION
			$uniqueOptionCodes += $item
		}
	}
}

$OptionCodeListD = $uniqueOptionCodes | Where-Object { $_.BulletCode -eq "D" } | Sort-Object -Property BulletCode,OptionCode,Price,Description -Unique
$OptionCodeListB = $uniqueOptionCodes | Where-Object { $_.BulletCode -eq "B" } | Sort-Object -Property BulletCode,OptionCode,Price,Description -Unique

$GroupOfCodeListD = $OptionCodeListD | Group-Object -Property BulletCode,OptionCode,Description

$propInfo = @{}
$propNames = @()
$a = ""
$b = ""
$c = ""
$d = ""
foreach ( $optionItem in $GroupOfCodeListD )
{ 
	$subItems = $OptionCodeListB | Where-Object { $_.OptionCode -eq $optionItem.Group[0].OptionCode }
	$a += "$($optionItem.Group[0].Description),"
	$b += "$($optionItem.Group[0].OptionCode),"
	$priceText = ""
	foreach ( $groupItem in $optionItem.Group )
	{
		$priceText += "$($groupItem.Price)~"
	}
	$c += "$($priceText),"
	if ( $subItems )
	{
		$propLast = "Group"
		$d += "Group Option,"
	} else {
		$propLast = "Individual"
		$d += "Individual Option,"
	}
	$propName = "$(RemoveChars $optionItem.Group[0].Description)_$(RemoveChars $optionItem.Group[0].OptionCode)_$(RemoveChars $priceText)_$($propLast)"
	$propNames += $propName
	if ( -not ( $propInfo.ContainsKey($propName) ) )  
	{
		$propItem = "" | Select-Object Description,OptionCode,Price,GroupType,PropertyName,PrimarySortKey,SecondarySortKey
		$propItem.Description = $optionItem.Group[0].Description
		$propItem.OptionCode = $optionItem.Group[0].OptionCode
		$propItem.Price = $priceText
		if ( $propLast -eq "Group" ) 
		{
			$propItem.GroupType = "Group Option"
			$propItem.PrimarySortKey = 0
			$propItem.SecondarySortKey = 0
		}
		if ( $propLast -eq "Individual") 
		{
			$propItem.GroupType = "Individual Option"
			$propItem.PrimarySortKey = 1
			$propItem.SecondarySortKey = 2
		}
		$propItem.PropertyName = $propName
		$propInfo.Add($propName, $propItem)
	}
	
	foreach ( $subItem in $subItems )
	{
		$a += "$($subItem.Description),"
		$b += "$($subItem.OptionCode),"
		$c += "$($subItem.Price),"
		$d += "Group Member,"
		$propName = "$(RemoveChars $subItem.Description)_$(RemoveChars $subItem.OptionCode)_$(RemoveChars $subItem.Price)_GroupMember"
		$propNames += $propName
		if (-not ( $propInfo.ContainsKey($propName) ) )  
		{
			$propItem = "" | Select-Object Description,OptionCode,Price,GroupType,PropertyName,PrimarySortKey,SecondarySortKey
			$propItem.Description = $subItem.Description
			$propItem.OptionCode = $subItem.OptionCode
			$propItem.Price = $subItem.Price
			$propItem.GroupType = "Group Member"
			$propItem.PrimarySortKey = 0
			$propItem.SecondarySortKey = 1
			$propItem.PropertyName = $propName
			$propInfo.Add($propName, $propItem)
		}
	}
}
}
$propNames = $propNames | Sort-Object -Unique

$propCollection = @()
foreach ( $key in $propInfo.Keys )
{
	$propCollection += $propInfo[$key]
}
$sortedPropCollection = $propCollection | Sort-Object -Property PrimarySortKey,OptionCode,SecondarySortKey
Write-Verbose "Options took: $($buildOptionsTime)" -Verbose

Write-Verbose "Gathering Vehicle and Dealer Data" -Verbose
$buildVehicleDealerDataTime = Measure-Command {
$allVehicleData = @()
$allVehicleDataByVIN = @{}

$vehicleFiles = Get-ChildItem -Filter Inventory*.clixml

foreach ( $vehicle in $vehicleFiles )
{
	$vTemp = Import-Clixml $vehicle
	$allVehicleData += $vTemp.result.data.vehicles	
}
foreach ( $vehicle in $allVehicleData )
{
	if ( -not ($allVehicleDataByVIN.ContainsKey($vehicle.vin)) )
	{
		$allVehicleDataByVIN.Add($vehicle.vin, $vehicle)
	}
}



$allVehicleData | Export-Clixml "C:\Temp\Challenger\AllVehicleData.clixml"

$allDealerData = Import-Clixml "C:\Temp\Challenger\AllDealerList.clixml"

$a = ""
$b = ""
$c = ""
$d = ""
foreach ( $propItem in $sortedPropCollection )
{
	$a += "$($propItem.Description),"
	$b += "$($propItem.OptionCode),"
	$c += "$($propItem.Price),"
	$d += "$($propItem.GroupType),"
}
$a += "VIN,PaintPrimary,PaintSecondary,InteriorColor,TripDescription,DealerURL,DealerLowPrice,DealerState,"

Write-Output $a | Out-File -FilePath "C:\Temp\Challenger\SheetHeaders.csv" -Encoding ascii
Write-Output $b | Out-File -FilePath "C:\Temp\Challenger\SheetHeaders.csv" -Encoding ascii -Append
Write-Output $c | Out-File -FilePath "C:\Temp\Challenger\SheetHeaders.csv" -Encoding ascii -Append
Write-Output $d | Out-File -FilePath "C:\Temp\Challenger\SheetHeaders.csv" -Encoding ascii -Append
}

Write-Verbose "Vehicle and Dealer Data Took $($buildVehicleDealerDataTime)" -Verbose

Write-Verbose "Gathering Rows" -Verbose
$buildVehicleRowsTime = Measure-Command {
$vehicleData = @()
foreach ( $file in $xmlFiles )
{
	$uniqueOptionCodes = @()
	[xml]$xmlData = Get-Content $file
	if ( $xmlData.MONRONEY.VINYEAR -eq "17" )
	{
		
		$item = "" | Select-Object $propNames
		Add-Member -InputObject $item -NotePropertyName VIN -NotePropertyValue ""
		Add-Member -InputObject $item -NotePropertyName PaintPrimary -NotePropertyValue ""
		Add-Member -InputObject $item -NotePropertyName PaintSecondary -NotePropertyValue ""
		Add-Member -InputObject $item -NotePropertyName InteriorColor -NotePropertyValue ""
		Add-Member -InputObject $item -NotePropertyName TrimDescription -NotePropertyValue ""
		Add-Member -InputObject $item -NotePropertyName DealerURL -NotePropertyValue ""
		Add-Member -InputObject $item -NotePropertyName DealerLowPrice -NotePropertyValue ""
		Add-Member -InputObject $item -NotePropertyName DealerState -NotePropertyValue ""
		$item.VIN = $xmlData.MONRONEY.VIN
		$item.PaintPrimary = $xmlData.MONRONEY.PAINTDESCPRIM
		$item.PaintSecondary = $xmlData.MONRONEY.PAINTDESCSECD
		$item.InteriorColor = $xmlData.MONRONEY.INTCOLORDESC
		$item.TrimDescription = $xmlData.MONRONEY.TRIMDESC1	
		
		#$dealerCode = ($allVehicleData | Where-Object { $_.vin -eq $item.VIN })[0].DealerCode
		$dealerCode = $allVehicleDataByVIN[$item.VIN].dealerCode
		if ( -not ($dealerCode) ) 
		{
			$dealerCode = $xmlData.MONRONEY.DEALERS.DEALER1.NUMBER
		}
		#$dealerURL = ($allDealerData | Where-Object { $_.dealerCode -eq $dealerCode })[0].url
		if ( -not ( $allDealerData.ContainsKey($dealerCode) ) ) { Write-Verbose "Missing DealerCode for ZIP: $($xmlData.MONRONEY.DEALERS.DEALER1.ZIPCODE)" -Verbose }
		$dealerURL = $allDealerData[$dealerCode].url
		$dealerURI = "$($dealerURL)/catcher.esl?vin=$($item.VIN)"
		$item.DealerURL = $dealerURI
		$item.DealerState = $allDealerData[$dealerCode].State
		
		if ( Test-Path "$($item.VIN).txt" )
		{
			$lowPriceLine = Get-Content "$($item.VIN).txt"
			$item.DealerLowPrice = ($lowPriceLine.Substring($lowPriceLine.IndexOf("data-attribute-value=")+22)).Replace("`"","").Replace(">","")
		}

		foreach ( $optionItem in $xmlData.MONRONEY.OPTIONALEQUIPMENT.OPTION )
		{
			$priceValues = $OptionCodeListD | Where-Object { ($_.OptionCode -eq $optionItem.OptionCode) -and ($_.Description -eq $optionItem.Description) }
			
			$subItems = $OptionCodeListB | Where-Object { $_.OptionCode -eq $optionItem.OptionCode }
			$priceText = ""
			foreach ( $priceItem in $priceValues )
			{
				$priceText += "$($priceItem.Price)~"
			}
			if ( $subItems )
			{
				$propLast = "Group"
			} else {
				$propLast = "Individual"
			}
			if ( $optionItem.BULLETINCODE -eq "B" )
			{
				$propLast = "GroupMember"
				$priceText = "$($optionItem.Price)"
			}
			$propName = "$(RemoveChars $optionItem.Description)_$(RemoveChars $optionItem.OptionCode)_$(RemoveChars $priceText)_$($propLast)"
			$item.($propName) = "X"
			if ( $propLast -eq "GroupMember" )
			{
				#We want to mark LIKE Individual options with an X, so Trailer Brake Group, contains Trailer Brake as a GroupMember, we also want to X the Trailer  Brake Individual Item.
				$lookforDescription = RemoveChars $optionItem.Description
				$itemPropList = $item | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty" } | Select-Object -Property Name
				foreach ( $ipl in $itemPropList )
				{
					if ( $ipl.Name.Contains("_") ) 
					{
						$splitFields = $ipl.Name.Split("_")
						if (( $splitFields[3] -eq "Individual" ) -and ( $splitFields[0] -eq $lookforDescription ) )
						{
							$item.($ipl.Name) = "X"
							break
						}
					}
				}
			}

		}
		
		$vehicleData += $item
	}
}

$vehicleData | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath .\SheetHeaders.csv -Append -Encoding ascii
}
Write-Verbose "Row Data Took: $($buildVehicleRowsTime)" -Verbose



#$allDealerData = @()
#$allDealerDataByDealerCode = @{}

#$dealerFiles = Get-ChildItem -Filter Dealer*.clixml 
#foreach ( $dealer in $dealerFiles )
#{
#	$dTemp = Import-Clixml $dealer
#	$allDealerData += $dTemp.data.dealers
#}
#foreach ( $dealer in $allDealerData )
#{
#	if ( -not ($allDealerDataByDealerCode.ContainsKey($dealer.DealerCode)) )
#	{
#		$allDealerDataByDealerCode.Add($dealer.DealerCode, $dealer)
#	}
#}
#$allDealerData | Export-Clixml "C:\Temp\RAM\AllDealerData.clixml"