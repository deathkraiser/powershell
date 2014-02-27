# will need AD
import-module activedirectory

# set folder locations to variable, for easy changing later
$newfolder = "ENTER YOUR FOLDER FOR THE PHOTOS TO BE UPLOADED"
$oldfolder = "ENTER FOLDER FOR UPLOADED PHOTOS TO BE MOVED TO"
$logfiles = "ENTER FOLDER TO STORE LOG FILES"

#get all files in the folder and exclude subfolders
$filelist = get-childitem $newfolder | Where-Object {$_ -isnot [IO.DirectoryInfo]}

#create arrays for completed log and failed log
$completed = @()
$failed = @()
$didcomplete = $false
$didfail = $false

#set the current date
$currentdate = (get-date -uFormat "%d%m%Y")


foreach ($file in $filelist){

	#set user to blank
	$user = ""
	
	#set username to filename
	$username = $file.name
	
	#set filepath filepath
	$filepath = ($newfolder + $username)
	
	#set username to username without the jpg
	$username = $username -replace ".jpg"
	
	#set user to getaduser username
	$user = get-aduser -filter {samaccountname -eq $username} -properties thumbnailphoto
	
	# if the username exists in AD, add the photo
	if (get-aduser -filter {samaccountname -eq $username}) {
		if ($user.thumbnailphoto -ne "") {
			#convert photo to bytes and store in variable
			$adphoto = [byte[]](get-content $filepath -encoding byte)
			
			#set the thumbnailphoto property in AD user account to adphoto
			set-aduser $username -replace @{thumbnailphoto=$adphoto}
			
			$user = get-aduser -filter {samaccountname -eq $username} -properties thumbnailphoto
			
			#if user now has thumbnail
			if ($user.thumbnailphoto -ne ""){
				#add username to completed log file
				$didcomplete = $true
				$completed += $username
				
				#move the current file into the Old Photos folder
				move-item $filepath $oldfolder
			}
			else{
				#add username to failed log file
				$didfail = $true
				$failed += $username
			}
		}
	}
	else{
		#add username to failed log file
		$didfail = $true
		$failed += $username
		
	}

	
}

if ($didcomplete -eq $true){
#create file name with completed and todays date
$compfile = ($logfiles + "completed " + $currentdate + ".txt")
#create text file for completion
$completed | out-file $compfile
}

if ($didfail -eq $true) {
#create file name with failed and todays date
$failfile = ($logfiles + "failed " + $currentdate + ".txt")
#create text file for failed
$failed | out-file $failfile

}