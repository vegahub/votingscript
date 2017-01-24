/*
Lisk Voting Tool for Windows by Vega
Written in Autohotkey

v1.0

Previous versions can be found here: https://github.com/vegahub/votingtool

This script uses jQuery and Tablesorter (https://mottie.github.io/tablesorter/)

todo:
- allow saving setting without saving passhprases
- allow saving only the first passhprase and asking for the second one when voting
- vote for all displayed (filtered) delegates
- design improvements
- make nicer tooltips
- add some tooltips with help info
*/


;### some initialisation ###

#SingleInstance force
#Persistent
#NoEnv
SetBatchLines -1
SetTitleMatchMode 2
ComObjError(false)
FileEncoding UTF-8
Menu, tray, icon, shell32.dll, 145
GroupAdd justthiswin, %A_ScriptName% - Notepad	; for editing purposes

oHTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
;############# default settings ###########


;############### read ini file ###############
ini := SubStr(A_ScriptName, 1,-4) ".ini"	
ScriptName := SubStr(A_ScriptName, 1,-4)

Fileread settings_file,%ini%
loop, parse, settings_file, `n,`r
{
	regex = "(.*?)"="(.*)"
	regexmatch(a_loopfield,regex,d)
	if (!d or !d2)
		continue
	%d1% := Trim(d2)
	
	ifinstring d1, passp1
		count_accounts++
}

if !nodeurl	; if custom url not set up
	nodeurl := "https://login.lisk.io"	; use official node
nodeurl := RegExReplace(nodeurl,"(.*)\/$","$1")		; remove / if present at the end of url

gui, add, ActiveX, vui x0 w1400 h1000, Shell.Explorer	; create gui control
ui.Navigate(a_scriptdir "/votingUI.html") 	; load html from file
While ui.readyState != 4 || ui.busy ; wait for the page to load
Sleep, 10

;// necessary to accept enter and accelorator keys
;http://msdn.microsoft.com/en-us/library/microsoft.visualstudio.ole.interop.ioleinplaceactiveobject(VS.80).aspx
IOleInPlaceActiveObject_Interface:="{00000117-0000-0000-C000-000000000046}"
pipa :=	ComObjQuery(ui, IOleInPlaceActiveObject_Interface)
OnMessage(WM_KEYDOWN:=0x0100, "WM_KEYDOWN")
OnMessage(WM_KEYUP:=0x0101, "WM_KEYDOWN")
;##############

; create a html table based on how many accounts the user have
generatetable:
account_cols:="",account_cols2 := ""
loop % count_accounts {
;account_cols .= "<th class='acc filter-parsed filter-select'>A" a_index "</th>`n"
account_cols .= "<th class='acc filter-select'>A" a_index "</th>`n"
account_cols2 .= "<td class='acc'></td>"
}

delegate_table = 
(
<thead>
<tr class='header'>
	<th class='rank'>Rank</th>
	<th data-placeholder="Search Delegates" class='Delegate'>Delegate</th>
	<th class="filter-select voted" data-placeholder="All" >Voters</th>
	%account_cols%
	<th class='approval'>Approval</th>	
	<th class='productivity'>Prod</th>
	<th class='forged'>Forged</th>
	<th class='missed'>Missed</th>
</tr>
</thead>
)

Gui Margin , 10, 0		

st:
gui show,Autosize, Lisk Voting	; display GUI
gosub accountinfo	; get account(s) info based on passhprases provided

gosub getdelegatelist	; get list of delegates to be dispalyed

loop % count_accounts		
	{
	accc := a_index
	gosub getvotedlist		; check what delegate your account have voted for
	}

; update tablesorter cache
js = $("#delegates").trigger("updateAll");
ui.document.parentwindow.execScript(js)

gosub countstuff	; get stats to display
gosub Getvoterslist	; check who voted for your delegate

settimer delegates_displayed, 500	; continously check filter changes

doc := ui.document
ComObjConnect(doc, "Doc_")	; watch for click on GUI

return

return

;#####################################################
; trigger so ctrl+v would format a delegate list before pasting it in the search field
#IfWinActive  Lisk Voting ahk_class AutoHotkeyGUI
^v::
Stringreplace list,clipboard,`r`n,`n,all
Stringreplace list,list,`n,|,all
js = $.tablesorter.setFilters( $('#delegates'), [ '', '%list%'] );
if (ui.document.activeElement.id = "search")
	ui.document.parentwindow.execScript(js)
else 
	sendinput %clipboard%
return

;#####################################################
; check who voted for your delegate
Getvoterslist:
if !delegatename
	return
; API call
delegate_publickey := regexreplace(oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET", nodeurl "/api/delegates/get?username=" delegatename))),".*publicKey"":""(.*?)"",.*","$1")

Ifinstring delegate_publickey, Account not found
	return
	
response := oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET", nodeurl "/api/delegates/voters?publicKey=" delegate_publickey)))

;process and display list
loop % ui.document.getElementById("delegates").rows.length	
	{
	del_add := ui.document.getElementById("delegates").rows[a_index].getAttribute("address")
	if !del_add 
		continue
		
			
			
	IfinString response, %del_add%
		ui.document.getElementById("delegates").rows[a_index].cells[2].innerhtml := "✔", ui.document.getElementById("delegates").rows[a_index].cells[2].style.color := "green", ui.document.getElementById("delegates").rows[a_index].cells[2].title := "Voted"
		
	else
		ui.document.getElementById("delegates").rows[a_index].cells[2].innerhtml := "✘", ui.document.getElementById("delegates").rows[a_index].cells[2].style.color := "red", ui.document.getElementById("delegates").rows[a_index].cells[2].title := "Not voted"
	}

return


settingshtml:
;fill the fields for the html if there is already settings saved
; deobfuscate passphrases before displaying
ui.document.getElementById("settings_nodeurl").value := nodeurl
ui.document.getElementById("settings_delegatename").value := delegatename
if (savetofilestatus = "-1")
	ui.document.getElementById("savepass").checked := true

loop 8 {

	ui.document.getElementsByClassName("settings_firstpass")[a_index - 1].value := CodeG(passp1_%a_index%,-1,"whatever")
	ui.document.getElementsByClassName("settings_secondpass")[a_index - 1].value := CodeG(passp2_%a_index%,-1,"whatever")
}

ui.document.getElementById("editpass").style.display := "block"	
return

settingsclose:
count_accounts:=""
ui.document.getElementById("editpass").style.display := "none"
nodeurl := ui.document.getElementById("settings_nodeurl").value
delegatename := ui.document.getElementById("settings_delegatename").value
savetofilestatus := ui.document.getElementById("savepass").checked

settingstosave := ""

settingstosave .= """nodeurl""=""" ui.document.getElementById("settings_nodeurl").value """`n"
settingstosave .= """delegatename""=""" ui.document.getElementById("settings_delegatename").value """`n"
settingstosave .= """savetofilestatus""=""" ui.document.getElementById("savepass").checked """`n"

	loop 8
		{
	passp1_%a_index% := CodeG(ui.document.getElementsByClassName("settings_firstpass")[a_index - 1].value,1,"whatever"), passp2_%a_index% := CodeG(ui.document.getElementsByClassName("settings_secondpass")[a_index - 1].value,1,"whatever")		
	
	settingstosave .= """passp1_" a_index """=""" CodeG(ui.document.getElementsByClassName("settings_firstpass")[a_index - 1].value,1,"whatever") """`n""passp2_" a_index """=""" CodeG(ui.document.getElementsByClassName("settings_secondpass")[a_index - 1].value,1,"whatever") """`n", ui.document.getElementsByClassName("settings_firstpass")[a_index - 1].value, ui.document.getElementsByClassName("settings_secondpass")[a_index - 1].value := ""
	
	if passp1_%a_index%
	count_accounts++
	}

if !settingstosave
	return

	
If (settings_file = settingstosave)
	return

	; get save passwords status and
if (ui.document.getElementById("savepass").checked = "-1")
	{
	FileDelete %ini%
	FileAppend %settingstosave%,%ini%		
	}


gosub generatetable
;reload
return


;######## get account informations based on passhprases provided ####
accountinfo:
info_html := ""

select := "<select id='affected_accounts' name='affected_accounts'><option value='All'>Mark all accounts</option>"
loop % count_accounts 
		select .= "<option value='" a_index "'>Mark account " a_index "</option>`n"
select .= "</select>"
  
filters_div = 
(
<input type=text class="search selectable" placeholder="Search" data-column="1" id="search">
<select id='selectfilter' class="change-input">
  <option value="1">Delegate name</option>
  <option value="0">Rank</option>
  <option value="all">Everything</option> 
  <option value="5">Approval</option>
  <option value="6">Productivity</option>
</select>
<div class='dropdown'> <button class='dropbtn'>Show Only</button>  <div class='dropdown-content'>    <a href='#'>Load list 1</a>    <a href='#'>Load list 2</a>  <a href='#'>Recommended list</a></div></div>
<div class='dropdown'> <button class='dropbtn'>Save Current List</button>  <div class='dropdown-content'>    <a href='#'>Save as list 1</a>    <a href='#'>Save as list 2</a></div></div>
<button type="button" class="dropbtn">Reset Filter</button>
<br><hr>
)

buttons =
(
<div class='dropdown'> <button class='dropbtn'>Clone A1 marks to all accounts</button>  <div class='dropdown-content'>  </div></div>  
<div class='dropdown'> <button class='dropbtn' title='Reload all data. Recheck accounts and vote statuses again.'>Reload All Data</button>  <div class='dropdown-content'>  </div></div>  
)
	 
ui.document.getElementById("filters").innerhtml  := "<legend>Filter and Action Buttons</legend>" filters_div buttons


js = $.tablesorter.filter.bindSearch( $('#delegates'), $('.search') );
ui.document.parentwindow.execScript(js)
js = $('select').change(function(){ $('.selectable').attr( 'data-column', $(this).val()  );     $.tablesorter.filter.bindSearch( $('#delegates'), $('.search'), false );  $('#delegates').trigger('filterReset'); }); 
ui.document.parentwindow.execScript(js)

; create html table to display data
ui.document.getElementById("basicinfo").innerhtml := "<button class='dropbtn' type='button' id='Settings_button'>Settings</button><div class='rTableRow'>		<div class='rTableHead' style='width:125px;' >Delegates displayed</div><div class='rTableCell' id='info_visible'></div></div><div class='rTableRow'>		<div class='rTableHead' style='width:125px;'>Your delegate name</div><div class='rTableCell' id='delname'>" delegatename "</div></div><div class='rTableRow' >		<div class='rTableHead' style='width:125px;' id='nodeurl'>Node URL</div><div class='rTableCell'>" nodeurl "</div> 	</div><div class='rTableRow'>&nbsp;</div>"

ui.document.getElementById("info_rTbody").innerhtml  := ""
loop % count_accounts {

	if !passp1_%a_index% 
		continue

	oHTTP.Open("POST", nodeurl "/api/accounts/open" , False)	;Post request
	oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded") 
	oHTTP.Send("secret=" CodeG(passp1_%a_index%,-1,"whatever"))	;Send POST request
	voterinfo := oHTTP.ResponseText

	regexmatch(voterinfo,"i){""success"":true,""account"":{""address"":""(.*?)"",""unconfirmedBalance"":""(.*?)"",""balance"":""(.*?)"",""publicKey"":""(.*?)"",""unconfirmedSignature"":.,""secondSignature"":(.*?),""secondPublicKey"":(.*?),""multisignatures"":(.*?),""u_multisignatures"":(.*?)}}",d)	
	if !d
		continue
	
	voteraddress_%a_index% := d1, unconfirmedbalance_%a_index% := d2 / 100000000, balance_%a_index% := round(d3 / 100000000,2),voterpubkey_%a_index% := d4,secondsig_%a_index% := d5,secondpubkey_%a_index% := d6

infobox := "<div class='rTableRow'><div class='rTableCell info_address' id='info_address" a_index "'>" voteraddress_%a_index% "</div>	<div class='rTableCell info_balance' id='info_balance" a_index "'>" balance_%a_index% " Lisk</div>		<div class='rTableCell info_votes' id='info_votes" a_index "'> ? </div> <div class='rTableCell info_tovotes' id='info_tovotes" a_index "'> ? </div>	<div class='rTableCell info_tounvotes' id='info_tounvotes" a_index "'> ? </div>	<div class='rTableCell info_totalvotes' id='info_totalvotes" a_index "'> ? </div></div>"


ui.document.getElementById("info_rTbody").innerhtml .= infobox
}


return
		

;#################################
;######## BUTTON actions #########	
;#################################

; this gets called whenever a user click on the GUI
Doc_OnClick(doc) {
global ui, nodeurl, count_accounts
If (doc.parentWindow.event.srcElement.id = "Settings_button")
	gosub settingshtml
	
if (doc.parentWindow.event.srcElement.innerhtml = "Vote/Unvote!")
	gosub vote_unvote
	
;msgbox % doc.parentWindow.event.srcElement.outerhtml	
If (doc.parentWindow.event.srcElement.id = "Done_button")
	gosub settingsclose
address := doc.parentWindow.event.srcElement.getAttribute("address")
If 	address
	ifinstring nodeurl,testnet
		run https://testnet-explorer.lisk.io/address/%address%
	else
		run https://explorer.lisk.io/address/%address%

;############	filter buttons #############
if (doc.parentWindow.event.srcElement.innerhtml = "Reload All Data")
	gosub st

if (doc.parentWindow.event.srcElement.innerhtml = "Load list 1")
	{
	FileRead list, list1.txt
	Stringreplace list,list,`r`n,`n,all
	Stringreplace list,list,`n,|,all
	if !list
		return
	js = $.tablesorter.setFilters( $('#delegates'), [ '', '%list%'] );
	ui.document.parentwindow.execScript(js)
	doc.parentWindow.event.srcElement.innerhtml .= " - Loaded"
	sleep 1000
	doc.parentWindow.event.srcElement.innerhtml := "Load list 1"
	return
	}
	
if (doc.parentWindow.event.srcElement.innerhtml = "Load list 2")
	{
	FileRead list, list2.txt
	Stringreplace list,list,`r`n,`n,all
	Stringreplace list,list,`n,|,all
	if !list
		return
	js = $.tablesorter.setFilters( $('#delegates'), [ '', '%list%'] );
	ui.document.parentwindow.execScript(js)
	doc.parentWindow.event.srcElement.innerhtml .= " - Loaded"
	sleep 1000
	doc.parentWindow.event.srcElement.innerhtml := "Load list 2"
	return
	}
	
if (doc.parentWindow.event.srcElement.innerhtml = "Recommended list")
	{
	url := "https://raw.githubusercontent.com/vegahub/votingscript/master/recommend.txt"
	UrlDownloadToFile, %URL%, recommend_list.txt

	list:=""
	loop, read, recommend_list.txt
		{
		Ifinstring a_loopreadline, //
			continue
		if !a_loopreadline
			continue
		if list
			list .= "|"
		list .= a_loopreadline
		}

	if !list
		return
		
	js = $.tablesorter.setFilters( $('#delegates'), [ '', '%list%'] );
	ui.document.parentwindow.execScript(js)
	doc.parentWindow.event.srcElement.innerhtml .= " - Loaded"
	sleep 1000
	doc.parentWindow.event.srcElement.innerhtml := "Recommended List"
	return
	}

if (doc.parentWindow.event.srcElement.innerhtml = "Save as list 1")
	{
	current_delegate_list :=""
	loop % ui.document.getElementById("delegates").rows.length		
		{
		rowclass := ui.document.getElementById("delegates").rows[a_index].classname
		Ifnotinstring rowclass, filtered	; visible row	
			if rowclass
				current_delegate_list .= ui.document.getElementById("delegates").rows[a_index].cells[1].innertext "`n"
		}		
		FileDelete list1.txt
		Fileappend %current_delegate_list%, list1.txt	
		doc.parentWindow.event.srcElement.innerhtml .= " - Saved"
		sleep 1000
		doc.parentWindow.event.srcElement.innerhtml := "Save as list 1"
	}
	
if (doc.parentWindow.event.srcElement.innerhtml = "Save as list 2")
	{
	current_delegate_list :=""
	loop % ui.document.getElementById("delegates").rows.length		
		{
		rowclass := ui.document.getElementById("delegates").rows[a_index].classname
		Ifnotinstring rowclass, filtered	; visible row	
			if rowclass
				current_delegate_list .= ui.document.getElementById("delegates").rows[a_index].cells[1].innertext "`n"
		}		
		FileDelete list1.txt
		Fileappend %current_delegate_list%, list2.txt	
		doc.parentWindow.event.srcElement.innerhtml .= " - Saved"
		sleep 1000
		doc.parentWindow.event.srcElement.innerhtml := "Save as list 2"
	}

	
if (doc.parentWindow.event.srcElement.innerhtml = "Voted Delegates")
	{
	ui.document.getElementById("selectfilter").value := "all"
	ui.document.getElementById("search").value := "✔"

	;js = $("#delegates").trigger("update");
;	ui.document.parentwindow.execScript(js)	
    
	}
	
;############	quick action buttons #############
	
if (doc.parentWindow.event.srcElement.innerhtml = "Reset Filter")
	{
	js = $('#delegates').trigger('filterReset');
	ui.document.parentwindow.execScript(js)
	gosub countstuff
	return
	}

	
if (doc.parentWindow.event.srcElement.innerhtml = "Clone A1 marks to all accounts")
	{
	loop % ui.document.getElementById("delegates").rows.length		
		{
		accc3 := a_index
		rowclass := ui.document.getElementById("delegates").rows[a_index].classname
		Ifinstring rowclass, filtered	; not visible row	
			continue
		if !rowclass
			continue
		A1 := ui.document.getElementById("delegates").rows[a_index].cells[3].innertext 	
		

		loop % count_accounts	
			{
			AC := ui.document.getElementById("delegates").rows[accc3].cells[3 + a_index].innertext 	
			if (A1 = "⇈" AND AC = "✘")
				ui.document.getElementById("delegates").rows[accc3].cells[3 + a_index].innertext := "⇈", ui.document.getElementById("delegates").rows[accc3].cells[3 + a_index].style.color := "blue"
			if (A1 = "⇊" AND AC = "✔")
				ui.document.getElementById("delegates").rows[accc3].cells[3 + a_index].innertext := "⇊", ui.document.getElementById("delegates").rows[accc3].cells[3 + a_index].style.color := "blue"
			}
		
		
		}		
		
	}

	
;##################################################
If (doc.parentWindow.event.srcElement.id = "cancel_button")
	ui.document.getElementById("editpass").style.display := "none"
	
column := doc.parentWindow.event.srcElement.classname


if (column = "tablesorter-filter")
	{
	;todo supress or delay click action until update happened
	js = $("#delegates").trigger("update");
	;ui.document.parentwindow.execScript(js)	
	return
	}

if column = acc
	{

	;cellstyle := doc.parentWindow.event.srcElement.style.color
	celltext := doc.parentWindow.event.srcElement.innerhtml

	if (celltext = "✔")
		doc.parentWindow.event.srcElement.innerhtml := "⇊", doc.parentWindow.event.srcElement.style.color := "blue", doc.parentWindow.event.srcElement.title := "Unvote!"
	else if (celltext = "✘")
		doc.parentWindow.event.srcElement.innerhtml := "⇈", doc.parentWindow.event.srcElement.style.color := "blue", doc.parentWindow.event.srcElement.title := "Vote!"
		
	
	else if (celltext = "⇊")
		doc.parentWindow.event.srcElement.innerhtml := "✔", doc.parentWindow.event.srcElement.style.color := "green", doc.parentWindow.event.srcElement.title := "Voted"
		
	else if (celltext = "⇈")
		doc.parentWindow.event.srcElement.innerhtml := "✘", doc.parentWindow.event.srcElement.style.color := "red", doc.parentWindow.event.srcElement.title := "Not voted"

	gosub countstuff	
		
		
	js = $("#delegates").trigger("update");
	;ui.document.parentwindow.execScript(js)
	}


;doc.parentWindow.event.srcElement.style.background := "purple"
;msgbox % ui.document.getElementById("delegates").rows[doc.parentWindow.event.srcElement.parentElement.id].cells[5].outerhtml
;    MsgBox, % doc.parentWindow.event.srcElement.innerhtml "`n" doc.parentWindow.event.srcElement.OuterHtml "`n" doc.parentWindow.event.srcElement.parentElement.id "`n" doc.parentWindow.event.srcElement.classname
}
return

; get stats based on what accounts got marked for vote/unvote
countstuff:
loop % count_accounts {
accc2 := a_index
votedcount_%accc2% := 0, count_visible := 0
if !voteraddress_%a_index%
	continue

count_voted := "0"	, count_notvoted := "0", count_vote := "0", count_unvote := "0", votinglist%accc2% := ""
loop % ui.document.getElementById("delegates").rows.length	
	{
	rowclass := ui.document.getElementById("delegates").rows[a_index].classname

	celltext := ui.document.getElementById("delegates").rows[a_index].cells[2 + accc2].innerHTML

		
	if (celltext = "✔")
		count_voted ++
	else if (celltext = "✘")
		count_notvoted ++
	else if (celltext = "⇊")
		{
		count_unvote ++
		if votinglist%accc2%
			votinglist%accc2% .= ","
		votinglist%accc2% .= "-" ui.document.getElementById("delegates").rows[a_index].getAttribute("pubkey")
		}
	else if (celltext = "⇈")
		{
		count_vote ++
		if votinglist%accc2%
			votinglist%accc2% .= ","
		votinglist%accc2% .= "+" ui.document.getElementById("delegates").rows[a_index].getAttribute("pubkey")
		
		}
	
	}

count_voted += count_unvote
ui.document.getElementById("info_tovotes" accc2).innerhtml := count_vote
ui.document.getElementById("info_tounvotes" accc2).innerhtml := count_unvote
ui.document.getElementById("info_totalvotes" accc2).innerhtml := count_voted + count_vote - count_unvote
ui.document.getElementById("info_votes" a_index).innerhtml := count_voted
;ui.document.getElementById("info_visible").innerhtml := "Delegates displayed: " count_visible

if ui.document.getElementById("info_totalvotes" accc2).innerhtml > 101
	ui.document.getElementById("info_totalvotes" accc2).style.color := "red"
else
	ui.document.getElementById("info_totalvotes" accc2).style.color := "black"
}
return

;########### get how many delegates are showing ############
; needed when list is filtered
delegates_displayed:
IfWinNotActive ahk_class AutoHotkeyGUI
	return
Thread, NoTimers	


displayed_rows := ui.document.getElementById("delegates").rows.length - ui.document.getElementsByClassName("filtered").length - 1

ui.document.getElementById("info_visible").innerhtml := displayed_rows
return
	
;########## Vote/unvote selected delegates ##############
; this part does the actual voting based on marks
VOTE_UNVOTE:

if (InStr(node, "http://") AND !InStr(node, "localhost"))
	{
	ui.document.getElementById("info").innerhtml .= "<div id='info_warning'>The Node URL you provided doesn't have an SSL certificate. Please select use another node for security reasons.</div>"
	return
	}

loop % count_accounts
	{
	count := 0, pubkeylist := "", accc := a_index
	loop, parse, votinglist%a_index%, `,
		{
		if pubkeylist
			pubkeylist .= ","
		pubkeylist .= """" a_loopfield """"
		count++
		if count = 33
			{
			gosub sendtransaction
			count := 0, pubkeylist := ""
			}
		}
	if pubkeylist
		gosub sendtransaction
	}
gosub countstuff
return	

sendtransaction:
passphrase := CodeG(passp1_%accc%,-1,"whatever")

secdata := CodeG(passp2_%accc%,-1,"whatever")
if secdata
	secdata = "secondSecret":"%secdata%",
	
voterpubkey :=	voterpubkey_%accc%
data = {"secret":"%passphrase%", %secdata% "publicKey":"%voterpubkey%", "delegates":[%pubkeylist%]}

oHTTP.Open("PUT", nodeurl "/api/accounts/delegates", false)
oHTTP.setRequestHeader("Content-Type", "application/json")
oHTTP.Send(data)
responsetext := oHTTP.ResponseText

Ifinstring responsetext, {"success":true
	loop % ui.document.getElementById("delegates").rows.length
		{
		pubkey := ui.document.getElementById("delegates").rows[a_index].getAttribute("pubkey")
		if !pubkey
			continue
		ifinstring responsetext,+%pubkey%
			ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].innerHTML := "✔", ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].style.color := "green", ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].title := "Successfully Voted!", ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].style.backgroundColor := "#00FF00"
		ifinstring responsetext,-%pubkey%
			ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].innerHTML := "✘", ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].style.color := "red", ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].title := "Successfully Unvoted!", ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].style.backgroundColor := "#00FF00"
		}
	
shortresponse := Regexreplace(responsetext,"{("".*?"":true),.*","$1")
FormatTime time,%a_now%,HH:mm:ss			
ui.document.getElementById("logentries").innerhtml := time a_tab "Account " accc " - " shortresponse "<br>" ui.document.getElementById("logentries").innerhtml

FileAppend %a_now%%a_tab%account%accc%%a_tab%%responsetext%`n,%ScriptName%.log
passphrase := "", secdata := "", data := ""
gosub countstuff
return
	
	
; Getting list of accounts you voted for
getvotedlist:
if ui.document.getElementById("delegates").rows.length = 0
	return
	
if !accc
	accc = 1
	
votedcount_%accc% := 0

if !voteraddress_%accc%
	return

voted_%accc% := oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET",nodeurl "/api/accounts/delegates/?address=" voteraddress_%accc%)))

	loop % ui.document.getElementById("delegates").rows.length
		ifinstring voted_%accc%, % ui.document.getElementById("delegates").rows[a_index].getAttribute("address")
			{
			ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].innerHTML := "✔", ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].style.color := "green", ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].title := "Voted"
			votedcount_%accc%++
			}
			
		else	
			ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].innerHTML := "✘", ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].style.color := "red", ui.document.getElementById("delegates").rows[a_index].cells[2 + accc].title := "Not Voted"


votedcount_%accc%--			
ui.document.getElementById("info_votes" a_index).innerhtml := votedcount_%accc%

return

;##### get full delegate list from node #####
getdelegatelist:

limit := "100", offset := "0",countlist:=""
tablehtml := delegate_table
response := oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET",nodeurl "/api/delegates?limit=100&offset=" offset "&orderBy=rate:asc")))
totalcount := regexreplace(response,".*,""totalCount"":(.*?)}.*","$1"), req_loop := ceil((totalcount / 100)) - 1

loop % req_loop {
	offset += 100
	response .= oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET",nodeurl "/api/delegates?limit=100&offset=" offset "&orderBy=rate:asc")))
		}
	
; get data from response and put it into html		
tablehtml .= "<tbody>"

Pos := 1
regex = "username":"(.*?)","address":"(.*?)","publicKey":"(.*?)","vote":"(.*?)","producedblocks":(.*?),"missedblocks":(.*?),"rate":(.*?),"approval":(.*?),"productivity":(.*?)}
While Pos {
	Pos:=RegExMatch(response,regex, d, Pos+StrLen(d1) )
	if !d
		Break

 row = <tr id='%a_index%' address='%d2%' pubkey='%d3%'><td class='rank'>%d7%</td><td class='username' Title='Address: %d2%'><a address='%d2%' href='#'>%d1%</a></td></td><td class='voted'></td>%account_cols2%<td class='approval'>%d8% `%</td><td class='productivity'>%d9% `%</td><td class=forged''>%d5%</td><td class='missed'>%d6%</td></tr>`n
tablehtml .= row "`n"  

loop % count_accounts		; replace address with name in account info if match found
	{
	aaa := ui.document.getElementById("info_address" a_index).innerhtml
	if aaa contains %d2%
		ui.document.getElementById("info_address" a_index).innerhtml := d1
	}

}
tablehtml .= "</tbody>"
ui.document.getElementById("delegates").innerhtml := tablehtml
return
	

	
	
;# just stuff to make editing the script easier for me
#IfWinActive ahk_group justthiswin
~^s::
Sleep 500
reload
return
#IfWinActive


GuiClose:
ExitApp


;############### FUNCTIONS ##############

APIPOST(URL,PostData) {		; function to POST API CALL
oHTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
oHTTP.Open("POST", URL , False)	;Post request
oHTTP.SetRequestHeader("User-Agent", "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)")	;Add User-Agent header
oHTTP.SetRequestHeader("Referer", URL)	;Add Referer header
oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded") ;Add Content-Type
oHTTP.Send(PostData)	;Send POST request
response := oHTTP.ResponseText
return response
}

; needed to sense trying in html input box fields
WM_KEYDOWN(wParam, lParam, nMsg, hWnd)  ;// modeled after code written by lexikos
{
	global	ui, pipa
	static	fields :=	"hWnd,nMsg,wParam,lParam,A_EventInfo,A_GuiX,A_GuiY"
	WinGetClass, ClassName, ahk_id %hWnd%
	if	(ClassName = "Internet Explorer_Server")
	{
		;// Build MSG Structure
		VarSetCapacity(Msg, 48)
		Loop Parse, fields, `,
			NumPut(%A_LoopField%, Msg, (A_Index-1)*A_PtrSize)
		;// Call Translate Accelerator Method
		TranslateAccelerator :=	NumGet(NumGet(1*pipa)+5*A_PtrSize)
		Loop 2 ;// only necessary for Shell.Explorer Object
			r :=	DllCall(TranslateAccelerator, "Ptr",pipa, "Ptr",&Msg)
		until	wParam != 9 || ui.document.activeElement != ""
	
		if	r = 0 ;// S_OK: the message was translated to an accelerator.
			return	0
	}
}
return

;https://autohotkey.com/board/topic/54882-random-encryption/	
CodeG(x,E,K1=0,K2=1,K3=2,K4=3) { ; x: data string, E=1|-1: encode|decode, K1..4: 32 bit unsigned keys
   If (C1!=K1 || C2!=K2 || C3!=K3 || C4!=K4) {
      L := 224, C1 := K1 , C2 := K2 , C3 := K3 , C4 := K4
      Loop %L%
         D%A_Index% := 0, S .= Chr(A_Index+31)
      Loop 4 {
         Random,,K%A_Index%
         Loop %L% {
            Random D, 0, L-1
            D%A_Index% := mod(D+D%A_Index%,L)
         }
      }
   }
   C =
   Loop Parse, x
      C .= " "<=(A:=A_LoopField) ? SubStr(S,mod(InStr(S,A,1)+L-1+E*D%A_Index%,L)+1,1) : A
   Return C
}

