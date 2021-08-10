
#################################################################################################################
# PBI_Exporter.ps1   												                                            #
#                                                                                                               #
# This script exports selected data tables from Power BI and generates csv files that can be reimported in      #
# Power BI in order to generate historic daily and monthly data. The script also generates a log file of all    #
# exports and notifies execution status via email.                                                              #
#       													                                                    #
# Authors:     Jorge Díaz                                                                                       #
#              Salvador Gomez    Salva.gm@outlook.es                                                            #
#                                                                                                               #
# Credits:                                                                                                      #
# Based on https://github.com/djouallah/PowerBI_Desktop_ETL by Mimoune Djouallah https://datamonkeysite.com/    #
#                                                                                                               #
# Notes:                                                                                                        #    
# 1.Edit custom variables to adapt the script to your context                                                   #
# 2.Avoid using paths and PBI table names with spaces since this will cause errors in the script                #
#                                                                                                               #
#                                                                                                               #
#################################################################################################################


################## CUSTOM VARIABLES ##################

# Array of PBI tables you want to export
$TABLES = "IntegrationRuntimesPROD"
# the Path your pbix file 
$template = "C:\Users\mumramacra\Downloads\5m-Sales-Records\test.pbix"  
# The root path where subdirectories will be created for CSV files to export
$path = "C:\Users\mumramacra\Downloads\5m-Sales-Records\"
# The Path to PowerBI Desktop executable
$PBIDesktop = "C:\Program Files\WindowsApps\Microsoft.MicrosoftPowerBIDesktop_2.95.983.0_x64__8wekyb3d8bbwe\bin\PBIDesktop.exe"    
# The time Needed in Seconds for PowerBI Desktop to launch and open the pbix file, 60 seconds by default, you may increase it for really big files
$waitoPBD  = 60   


# Orignal Line
# $TABLES = "IntegrationRuntimesPROD"
# the Path your pbix file 
# $template = "E:\Autorun\Files\IntegrationRuntimePROD.pbix"  
# The root path where subdirectories will be created for CSV files to export
# $path = "C:\Users\_tomhei\Outotec Oyj\Service Operational Development - 13. Historical\"
# The Path to PowerBI Desktop executable
# $PBIDesktop = "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe"    
# The time Needed in Seconds for PowerBI Desktop to launch and open the pbix file, 60 seconds by default, you may increase it for really big files
# $waitoPBD  = 60 


################## HELPER FUNCTIONS ##################

#Log function 
Function log_message ($log_message)
{
    $log = "$($path)\PBI_Exporter_log.txt"
    Write-Host $log_message
    Add-Content $log $log_message
}

#Calculate script duration
#Thanks to Russ Gillespie https://community.spiceworks.com/topic/436406-time-difference-in-powershell
Function calculate_duration ($date_1, $date_2)
{
    $TimeDiff = New-TimeSpan $date_1 $date_2
    if ($TimeDiff.Seconds -lt 0) {
	    $Hrs = ($TimeDiff.Hours) + 23
	    $Mins = ($TimeDiff.Minutes) + 59
	    $Secs = ($TimeDiff.Seconds) + 59 
    }
    else {
	    $Hrs = $TimeDiff.Hours
	    $Mins = $TimeDiff.Minutes
	    $Secs = $TimeDiff.Seconds 
    }
    $difference = '{0:00} hours {1:00} minutes and {2:00} seconds' -f $Hrs,$Mins,$Secs
    return $difference

}

#This function is used to remove from the exported CSV files extra lines and double quotes inside Power BI text fields which may cause problems when later reimporting the CSV file into Power BI
Function Remove_unwantedChars ($csv_file)
{
    $csv_input = [System.IO.File]::ReadAllText($csv_file) 
        
    # Replace all double quotes
    $csv_output = $csv_input -replace "`"","~DOUBLE~QUOTE~"
    # Restore double quotes only for csv separators (",") 
    $csv_output = $csv_output -replace "~DOUBLE~QUOTE~,~DOUBLE~QUOTE~","`",`""
    # Replace all double double quotes with single quote
    # Note: export_csv escapes a " with ""
    $csv_output = $csv_output -replace "~DOUBLE~QUOTE~~DOUBLE~QUOTE~","`'"
    # Restore double quotes at end of line (both "rn and "r and "n) 
    $csv_output = $csv_output -replace "~DOUBLE~QUOTE~`r`n","`"`r`n"    
    $csv_output = $csv_output -replace "~DOUBLE~QUOTE~`r","`"`r"    
    $csv_output = $csv_output -replace "~DOUBLE~QUOTE~`n","`"`n"
    # Restore at the start of new line (both rn" and r" and n")
    $csv_output = $csv_output -replace "`r`n~DOUBLE~QUOTE~","`r`n`""
    $csv_output = $csv_output -replace "`r~DOUBLE~QUOTE~","`r`""
    $csv_output = $csv_output -replace "`n~DOUBLE~QUOTE~","`n`""
    # Restore the first double quote in the file (the very first character)
    $csv_output = $csv_output -replace "^~DOUBLE~QUOTE~", "`""
    
    # Replace any other double quotes by single quotes (this are line double quotes originally inside Power BI text fields)
    #$csv_output = $csv_output -replace "~DOUBLE~QUOTE~","`'"
    #The above is commented because actually if there is any other double quote it should be an error because export_csv escapes " with "" (Check for this situation and raise an exception if needed)
    if ($csv_output -like '*~DOUBLE~QUOTE~*') { 
        throw "Unexpected double quotes found in file $($csv_file), original file is saved unmodified."
    }


    # Replace all line ends (both for rn and r and n)
    $csv_output = $csv_output -replace "`r`n","~LINE~END~"
    $csv_output = $csv_output -replace "`r","~LINE~END~"
    $csv_output = $csv_output -replace "`n","~LINE~END~"
    # Replace line ends finishing with "," with bars (this are extra lines originally inside Power BI text fields)
    $csv_output = $csv_output -replace "`",`"~LINE~END~","`",`"  |  "
    # Restore other line ends associated to a double quote separator (this are the real csv line ends)
    $csv_output = $csv_output -replace "`"~LINE~END~","`"`r`n"
    # Replace all other line ends with bars (this are extra lines originally inside Power BI text fields)
    $csv_output = $csv_output -replace "~LINE~END~","  |  "

    #Overwrite the modifications onto the original file
    Write-Output $csv_output > $csv_file
}


################## MAIN SCRIPT ##################

Try{
    $status ="with undetermined status"
    $executionDate = get-date -f yyyy-MM-dd_HH_mm_ss
    $executionDate_raw = get-date

    $isFirstDayOfMonth = (get-date -f dd) -eq "01"
    $isLastDayOfMonth =  ((get-date).AddDays(1)).Month -ne (get-date).Month

    #Make directory if needed
    md -Force $($path) | Out-Null

    log_message "***********************************************"
    log_message "Executing PBI_Exporter.ps1 at $($executionDate)"
    log_message "Launching Power BI"

    $app = START-PROCESS $PBIDesktop $template -PassThru
    log_message "Waiting $($waitoPBD) seconds for PBI to launch"
    Start-Sleep -s $waitoPBD

    log_message "Assuming PBI is launched and ready now"


    # get the server name and the port name of PowerBI desktop SSAS , thanks for Imke http://www.thebiccountant.com/2016/04/09/hackpowerbi/#more-1147

    $pathtofile = (Get-ChildItem -Path c:\users -Filter msmdsrv.port.txt -Recurse -ErrorAction SilentlyContinue -Force | sort LastWriteTime | select -last 1).FullName
    $port = gc $pathtofile
    $port = $port -replace '\D',''
    $dataSource = "localhost:$port"
    $pathtoDataBase_Name = $pathtofile -replace 'msmdsrv.port.txt',''
    $Database_Name = Get-ChildItem -Path $pathtoDataBase_Name -Filter *.db.xml -Recurse -ErrorAction SilentlyContinue -Force
    $Database_Name = $Database_Name.ToString().Split(".") | select -First 1


    #  Connect using AMO thanks for stackexchange :)

    log_message "Connecting to PBI using AMO"
    [System.Reflection.Assembly]::LoadFile("C:\Program Files (x86)\Microsoft SQL Server\130\SDK\Assemblies\Microsoft.AnalysisServices.tabular.DLL")
     ("Microsoft.AnalysisServices") >$NULL
    $server = New-Object Microsoft.AnalysisServices.tabular.Server

    $server.connect($dataSource)
    $database = $server.Databases.Item($Database_Name)


    #Refreshing Bower BI (thanks to Marco russo http://www.sqlbi.com/articles/using-process-add-in-tabular-models/)
    log_message "Trying to refresh Power BI now"
    $model = $database.Model
    $model.RequestRefresh("Full")
    $model.SaveChanges()


    $server.disconnect($dataSource)


    # Connect using ADOMD.NET
    log_message "Connecting to PBI using ADOMD.NET"
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.AdomdClient")   
 
    # Create the first connection object  
    log_message "Quering datasource $($dataSource) for database $($Database_Name)"
    $con = new-object Microsoft.AnalysisServices.AdomdClient.AdomdConnection 
    $con.ConnectionString = "Datasource=$dataSource; Initial Catalog=$Database_Name;timeout=0; connect timeout =0" 
    $con.Open() 


    foreach ($element in $TABLES) {
    
        # Create a command and send a query to get the data, the dax/mdx query is defined at the top  
        $command = $con.CreateCommand()
        $command.CommandText = "evaluate $($element)"
        #$Reader = $Comand.ExecutedataReader()
 
        $adapter = New-Object -TypeName Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter $command
        $dataset = New-Object -TypeName System.Data.DataSet

        $adapter.Fill($dataset)

        ######## Daily export ########

        #make sure the directory exists (with -Force it won't complain if it already exists)
        md -Force "$($path)Daily\$($element)\" | Out-Null

        $filename = "$($path)Daily\$($element)\$($element)_$($executionDate).csv"

        log_message "Exporting to file $($filename)"

        $dataset.Tables[0] | export-csv "$($filename)" -notypeinformation -Encoding UTF8

        log_message "Removing unwanted chars from $($filename)"

        Remove_unwantedChars $filename

        ######## Beginning of month export ########
        If ($isFirstDayOfMonth) {
            md -Force "$($path)MonthStart\$($element)\" | Out-Null

            $filename = "$($path)MonthStart\$($element)\$($element)_$($executionDate).csv"

            log_message "Exporting to file $($filename)"

            $dataset.Tables[0] | export-csv "$($filename)" -notypeinformation -Encoding UTF8

            log_message "Removing unwanted chars from ($filename)"

            Remove_unwantedChars $filename
        }

        ######## End of month export ########
        If ($isLastDayOfMonth) {
            md -Force "$($path)MonthEnd\$($element)\" | Out-Null

            $filename = "$($path)MonthEnd\$($element)\$($element)_$($executionDate).csv"

            log_message "Exporting to file $($filename)"

            $dataset.Tables[0] | export-csv "$($filename)" -notypeinformation -Encoding UTF8

            log_message "Removing unwanted chars from $($filename)"

            Remove_unwantedChars $filename
        }
   
    }

    $status ="successfuly"  
}
Catch
{

    $status ="with errors"

    #Error 
    $e = $_.Exception
    $ErrorMessage = $e.Message
    while ($e.InnerException) {
        $e = $e.InnerException
        $ErrorMessage += "`n" + $e.Message
    }

    log_message ($ErrorMessage)    
}
Finally 
{
    try
    {
        $finishDate = get-date -f MM-dd-yyyy_HH_mm_ss
        $finishDate_raw = get-date

        $elapsed_time = calculate_duration $executionDate_raw $finishDate_raw

        log_message "Script finished $($status) at $($finishDate)"

        #We don't know where the error happened so just in case we try to clean-up the connection and process in a Finally section
        log_message "Closing the connection"
        $con.Close() 
        log_message "Stopping Power BI"
        Stop-Process $app.Id

        #Now report back the error through email
#        switch ($status) 
#        { 
#            "successfuly" {
#                send_email "Successful PBI_Exporter execution" @"
#<p><span style="color:green;"><strong>Successful</strong></span> execution of PBI_Exporter.ps1 at <strong>$($executionDate)</strong> finished after a total elapsed time of $($elapsed_time)</p>
#"@
#            } 
#            "with errors" {
#                send_email "Error in PBI_Exporter execution" @"
#<p><span style="color:red;"><strong>An error </strong></span>occurred when executing PBI_Exporter.ps1 at <strong>$($executionDate)</strong>:</p>
#<p style="color:red;">$($ErrorMessage)</p>
#"@
#            } 
#            default {
#               send_email "Undetermined PBI_Exporter execution" @"
#<p><span style="color:red;"><strong>Undertermined</strong></span> execution status of PBI_Exporter.ps1 at <strong>$($executionDate)</strong></p>
#"@
#            }
#        }
    }
    catch
    {
        #Error 
        $e = $_.Exception
        $ErrorMessage = $e.Message
        while ($e.InnerException) {
            $e = $e.InnerException
            $ErrorMessage += "`n" + $e.Message
        }

        log_message ($ErrorMessage)
        }

} 