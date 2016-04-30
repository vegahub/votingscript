;### some initialisation ###
#SingleInstance force
#Persistent
#NoEnv
SetBatchLines -1
SetTitleMatchMode 2
DetectHiddenWindows, On
ComObjError(false)
FileEncoding UTF-8
GroupAdd justthiswin, %A_ScriptName% - Notepad	; for editing purposes

WinHttpReq:=ComObjCreate("WinHttp.WinHttpRequest.5.1")	

;############# default settings ###########
 html_voters =
(
	<!DOCTYPE html>
	<html>
	<head>
	<body>
	<table style="width:100`%" border='1px'>
	<tr>
    <th>#</th><th>Delegate Name</th><th>Lisk Address</th><th>Status</th><th>
	</tr>
)

votinglist = Vega`n
Ifexist votinglist.txt
	FileRead votinglist, votinglist.txt

node := "https://login.lisk.io",html:=""
; if settings saved, read from file
IfExist settings.txt
	loop,read,settings.txt
		{
		if a_index = 1
			passphrase := a_loopreadline
		if a_index = 2	
			node := a_loopreadline
		}	

; create GUI
Gui, Add, Text, x17 y8 w220 h20, Passphrase of your voting account:
Gui, Add, Text, x17 y38 w220 h20, Node URL (USE HTTPS! add port if needed):
Gui, Add, Edit, x240 y8 w200 h20 vPassphrase,%passphrase%
Gui, Add, Edit, x240 y38 w200 h20 vnode, %node%

Gui, Add, Checkbox, x10 y+10 vSave, Save settings to file
Gui, Add, Checkbox, x10 y+10 Checked vSavelist, Save voting list to file
Gui,Add, text,x10 y+20, Your voting list. Can be username, lisk address or public key. One per line.

Gui,Add,Edit,r47 w420 vVotinglist,%votinglist%
Gui,Add,Button,Default xs+200 gOK,Vote!
Gui, Show, x279 y217 h800 w450 center
Return 

GuiClose:
ExitApp

OK:
Gui, submit
If !passphrase
	{
	Gui, Show, x279 y217 h800 w450 center
	msgbox The passphrase field can't be empty
	return
	}
If savelist = 1
	{
	FileDelete votinglist.txt
	FileAppend %votinglist%, votinglist.txt
	}
If save = 1
	{
	FileDelete settings.txt
	FileAppend %Passphrase%`n%node%, settings.txt
	}
gui Destroy
resultlist=

voterinfo := APIPOST(node "/api/accounts/open")		; get account info based on passphrase
if !voterinfo
	{
	msgbox No response from the node.`n`nPlease check your nodes URL you provided.`n`nPress OK to try again.
	reload
	}
regexmatch(voterinfo,"i)address"":""(.*?)"".*?publicKey"":""(.*?)""",d)
voteraddress := d1, voterpubkey := d2 ; put info into var

; now get a list of the accounts you already voted for
voted := WinHttpReq.ResponseText(WinHttpReq.Send(WinHttpReq.Open("GET",node "/api/accounts/delegates/?address=" voteraddress)))
;Filedelete voted.txt
;FileAppend %voted%,voted.txt

; get full delegate list
limit := "100", offset := "0",delegate_list :="",countlist:=""
loop 20 {
url := node "/api/delegates?limit=100&offset=" offset "&orderBy=rate"
delegate_list .= WinHttpReq.ResponseText(WinHttpReq.Send(WinHttpReq.Open("GET",url)))
offset += limit
if a_index = 1	; get total delegate count
	TotalCount := ceil(regexreplace(delegate_list,".*""totalCount"":(.*?)}","$1") / limit)		; determine how many api calls needed to get all delegates info

if a_index = %TotalCount%
	break
}
;FileAppend %delegate_list%,delegates.txt
;Fileread, delegate_list,delegates.txt

loop, parse, votinglist, `n,`r
{
line := a_loopfield, username :="", address := "", publickey := ""
if !line
	Continue
countlist++
StringCaseSense On
	loop, parse, delegate_list, {
		{
		
		Ifnotinstring a_loopfield, "%line%"
			continue
		regex = "username":"(.*?)","address":"(.*?)","publicKey":"(.*?)",.*	
		regexmatch(a_loopfield,regex,d)
		username := d1, address := d2, publickey := d3
		}
StringCaseSense off
if (!address OR !username OR !publickey)
	{
	html .= "<tr><td>" countlist "</td><td>" line "</td><td></td><td>Not found on delegate list</td><td></tr>`n"
	resultlist .= line a_tab "was not found in delegate list`n"
	continue
	}
;msgbox % line "`n" username "`n" address "`n" publickey			
if address
	ifinstring voted, %address%	; ignore account you already voted for
		{
		html .= "<tr><td>" countlist "</td><td>" username "</td><td>" address "</td><td>Previously voted</td><td></td></tr>`n"
		resultlist .= username a_tab address a_tab "Voted Already`n"
		continue
		}
; needs to batch votes, max 33

html .= "<tr><td>" countlist "</td><td>" username "</td><td>" address "</td><td>voting now</td><td></td></td></tr>`n"

delegate = "+%publickey%"
If delegates
	delegates .= ","
delegates .= delegate
count++
if count = 33
	gosub sendvotes

}	; end of votinglist loop

if count > 0		; vote for any remaining delegates from the list
	gosub sendvotes

html_voters .= html	 "</table></body></html>"
now := a_now
FileAppend %html_voters%,voterslist_%now%.html
run voterslist_%now%.html
exitapp

; send PUT request with votes
SENDVOTES:
;data = {"secret":"%Passphrase%", "publicKey":"%voterpubkey%", "delegates":["+%publickey%"]}

data = {"secret":"%Passphrase%", "publicKey":"%voterpubkey%", "delegates":[%delegates%]}

WebRequest2 := ComObjCreate("WinHttp.WinHttpRequest.5.1")
WebRequest2.Open("PUT", node "/api/accounts/delegates", false)
WebRequest2.setRequestHeader("Content-Type", "application/json")
WebRequest2.Send(data)
responsetext := WebRequest2.ResponseText
ifinstring responsetext, error":"Account has no LISK
	{
	msgbox API Response:`n%responsetext%`n`nProbably a passphrase error.`n`nPress OK to try again.
	reload
	sleep 100
	}

Ifinstring responsetext, account has already voted
	stringreplace html,html,<td>voting now</td><td></td></td>,<td>Already Voted</td><td></td></td>,all
Ifinstring responsetext, success":true,"
	stringreplace html,html,<td>voting now</td><td></td></td>,<td bgcolor="#00FF00">Voted!</td><td></td></td>,all
resultlist .= username a_tab "Response: " responsetext "`n" 
count=0
return

;# just stuff to make editing the script easier for me
#IfWinActive ahk_group justthiswin
~^s::
Sleep 500
reload
return
#IfWinActive


;############### FUNCTIONS ##############

APIPOST(URL) {		; function to POST API CALL
global passphrase
PostData := "secret=" passphrase
oHTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
oHTTP.Open("POST", URL , False)	;Post request
oHTTP.SetRequestHeader("User-Agent", "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)")	;Add User-Agent header
oHTTP.SetRequestHeader("Referer", URL)	;Add Referer header
oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded") ;Add Content-Type
oHTTP.Send(PostData)	;Send POST request
response := oHTTP.ResponseText
return response
}
