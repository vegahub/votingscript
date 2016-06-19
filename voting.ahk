;### some initialisation ###

/*
Changelog
v0.2.7
	- bugfixes
	
v0.2.6
    - wait for new block before sending second voting transaction
v0.2.5 
	- Changed input fields behavior to improve reliability
	- To prevent accidental selections, row checkbox selection now works with right click instead of left click
	- copy selected rows from delegate list with CTRL+C (rank,username,address) 
	- Button to get my recommended delegate list
	- some small improvements
*/

#SingleInstance force
#Persistent
#NoEnv
SetBatchLines -1
SetTitleMatchMode 2
#InstallKeybdHook
ComObjError(false)
FileEncoding UTF-8
Menu, tray, icon, shell32.dll, 145
GroupAdd justthiswin, %A_ScriptName% - Notepad	; for editing purposes

WinHttpReq:=ComObjCreate("WinHttp.WinHttpRequest.5.1")	
oHTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
;############# default settings ###########
node := "https://login.lisk.io"
ini := SubStr(A_ScriptName, 1,-4) ".ini"

;############### read ini file ###############
nodecount := 0
loop, read, %ini%
	{
	RegExMatch(a_loopreadline,"^(.*?)=(.*?)$",d)
	if !d
		continue
	%d1% := d2
	}

; create GUI
Gui, Color, 74828F,1B1926

gui, font,s10 cwhite bold, Verdana
Gui, Add, GroupBox, x+1 y+1 w560 h200 0x300 0x8000 cDC8G86, Lisk Accounts Passphrases
gui, font,s8 normal
Gui, Add, Edit,xs+10 ys+25 w140 hWndhWndpass1 r1 vpass1 Password* gAccountinfo,%pass1%
Gui, Add, Edit,w140 hWndhWndpass2 r1 vpass2 Password* gAccountinfo,%pass2%
Gui, Add, Edit,w140 hWndhWndpass3 r1 vpass3 Password* gAccountinfo,%pass3%
Gui, Add, Edit,w140 hWndhWndpass4 r1 vpass4 Password* gAccountinfo,%pass4%
Gui, Add, Edit,w140 hWndhWndpass5 r1 vpass5 Password* gAccountinfo,%pass5%

Gui, Add, Edit,xs+150 ys+25 w140 hWndhWndpass1_2 r1 vpass1_2 Password* ,%pass1_2%
Gui, Add, Edit,w140 hWndhWndpass2_2 r1 vpass2_2 Password* ,%pass2_2%
Gui, Add, Edit,w140 hWndhWndpass3_2 r1 vpass3_2 Password* ,%pass3_2%
Gui, Add, Edit,w140 hWndhWndpass4_2 r1 vpass4_2 Password* ,%pass4_2%
Gui, Add, Edit,w140 hWndhWndpass5_2 r1 vpass5_2 Password* ,%pass5_2%

SetEditPlaceholder(hWndpass1, "Account passphrase",1)
SetEditPlaceholder(hWndpass2, "Account 2 passphrase",1)
SetEditPlaceholder(hWndpass3, "Account 3 passphrase",1)
SetEditPlaceholder(hWndpass4, "Account 4 passphrase",1)
SetEditPlaceholder(hWndpass5, "Account 5 passphrase",1)

SetEditPlaceholder(hWndpass1_2, "Second passphrase",1)
SetEditPlaceholder(hWndpass2_2, "Second passphrase",1)
SetEditPlaceholder(hWndpass3_2, "Second passphrase",1)
SetEditPlaceholder(hWndpass4_2, "Second passphrase",1)
SetEditPlaceholder(hWndpass5_2, "Second passphrase",1)
gui, font,s8 bold
Gui, Add, Text,xs+300 ys+20 r2 w240 HWNDaccount1
Gui, Add, Text,y+4 w240 r2 HWNDaccount2
Gui, Add, Text,y+4 w240 r2 HWNDaccount3
Gui, Add, Text,y+3 w240 r2 HWNDaccount4
Gui, Add, Text,y+3 w240 r2 HWNDaccount5

Gui, Add, Button,section -Theme gshowhide  x25 y+10 h15, Show passphrases
Gui, Add, Button,ys -Theme gsavepass h15, Save passphrases
Gui, Add, Button,ys -Theme gdeletepass h15, Delete saved passphrases

gui, font,s10, 
Gui, Add, GroupBox, section x837 y1 w450 h200 0x300 0x8000 cDC8G86, Status Log
gui, font,s8, 
Gui, Add, Edit,xs+5 ys+20 w440 r12 -E0x200 ReadOnly HWNDstatuslog

gui, font,s10, 
Gui,Add, GroupBox, section x580 y155 w250 0x300 0x8000 cDC8G86 h50,Node (URL with https and port)
gui, font,s8, 
Gui,Add, Edit, xs+10 ys+20 -E0x200 w230 vnode gnodecheck, %node%

Gui,Add,Edit,w195 x15 y280 h600 -E0x200 section hwndhwndVotinglist vVotinglist  gTransferlist,%votinglist%

Gui Add, ListView, xp+197 y280 w1050 h600 -E0x200 -LV0x10 Checked AltSubmit glistview, Votefor|#|Rank|Username|Lisk Address|Voted|Voted2|Voted3|Voted4|Voted5|Voted you|Approval|Blocks|Missed Blocks|Productivity|pubkey

LV_ModifyCol(1, "Right"), LV_ModifyCol(2, "Integer"), LV_ModifyCol(3,  "Integer"), LV_ModifyCol(12, "Integer"), LV_ModifyCol(13, "Integer"),LV_ModifyCol(14, "Integer"),LV_ModifyCol(15, "Integer 90"), LV_ModifyCol(16, 0),LV_ModifyCol(7, 0),LV_ModifyCol(8, 0),LV_ModifyCol(9, 0),LV_ModifyCol(10, 0),LV_ModifyCol(11, 0)

gui, font,s10, 
Gui, Add, GroupBox, x15 y210 w195 h670 0x300 0x8000 cDC8G86, Delegate Filter
Gui, Add, GroupBox, x210 y210 w1052 h670 0x300 0x8000 cDC8G86, Delegate List
gui, font,s8, 
Gui, Add, Button, x20 y228 -Theme ggetlist h15, Recommended Delegates
Gui, Add, Button, x40 y245 -Theme gloadlist h15, &Load list
Gui, Add, Button, x+5 yp -Theme gSavelist h15, &Save list
Gui, Add, Button, x65 yp+18 -Theme gClearlist h15, &Clear filter

Gui, Add, Button, x220 y232 -Theme h15 gselectall, Select All
Gui, Add, Button, xp yp+23 -Theme h15 gunselectall, Unselect All

Gui, Add, Button, x+10 y233 -Theme h15 gtransferlist, Display all delegates
Gui, Add, Button, xp yp+22 -Theme h15 gupdateinfo, Update Table
Gui, Add, Button, x+100 y240 -Theme gvote_unvote, Vote Selected
Gui, Add, Button, x+25 yp -Theme gvote_unvote, Unvote Selected
Gui, Add, Button,  x+25 yp -Theme gstartcheck, Update All Data


gui, font,s10, 
Gui, Add, GroupBox, section x580 y1 w250 h150 0x300 0x8000 cDC8G86, Info
gui, font,s8, 
Gui, Add, Text,ys+18 xs+5 w240 r1 HWNDinfo1,
Gui, Add, Text,yp+13 w240 r1 HWNDinfo2,
Gui, Add, Text,yp+13 w240 r1 HWNDinfo3,
Gui, Add, Text,yp+25 w240 r1 HWNDinfo4,
Gui, Add, Text,yp+13 w240 r1 HWNDinfo5,
Gui, Add, Text,yp+13 w240 r1 HWNDinfo6,
Gui, Add, Text,yp+13 w240 r1 HWNDinfo7,
Gui, Add, Text,yp+13 w240 r1 HWNDinfo8,
Gui, Add, Text,yp+13 w240 r1 HWNDinfo9,


Gui Show, w1300 h900 Center,Lisk Delegate Voting
;Gui Show, w1300 h900 x650,Lisk Delegate Voting
ControlFocus , , Lisk Delegate Voting

OnMessage(0x200, "WM_MOUSEMOVE")

GroupAdd Self, % "ahk_pid " DllCall("GetCurrentProcessId") ; Create an ahk_group "Self" and make all the current process's windows get into that group.

startcheck:
If node
	gosub nodecheck_enter
	
If pass1
	gosub Accountinfo_enter

updateinfo:
if statuscheck = true
	gosub getdelegatelist	

gosub getvotedlist
	
gosub transferlist_enter
	
	return

;############ tooltip helper #######


WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
	if A_GuiControl not in Recommended Delegates,votinglist
		{
		Tooltip
		return
		}
		
	
	if A_GuiControl = Recommended Delegates
		Tooltip Delegates I (Vega) personally recommend you give your vote for.`nThe list is up to date`, downloaded from GitHub
	if A_GuiControl = votinglist
		Tooltip Type (or paste a list of) delegate names`, or `naddresses here to filter the full delegate list
		
	return	
}

	
;######## BUTTON actions #########	
getlist:
url := "https://raw.githubusercontent.com/vegahub/votingscript/master/recommend.txt"
newline := "Getting a fresh list of recommended delegates from GitHub"
gosub updatestatus
UrlDownloadToFile, %URL%, recommend_list.txt

recommend_list:=""
loop, read, recommend_list.txt
	{
	Ifinstring a_loopreadline, //
		continue
	if !a_loopreadline
		continue
	recommend_list .= a_loopreadline "`n"	
	}

if !recommend_list
	return
GuiControl,, edit13, %recommend_list%
sleep 20
gosub transferlist_enter
return

loadlist:
Ifexist votinglist.txt
	FileRead votinglist, votinglist.txt
if !votinglist	
	return
GuiControl,, edit13, %votinglist%
gosub transferlist_enter
return

Clearlist:
gui submit,NoHide
GuiControl,, edit13,
If !votinglist
	return
gosub transferlist_enter
return

Savelist:
FileDelete votinglist.txt
FileAppend %votinglist%, votinglist.txt
newline := "Voting list was saved to votinglist.txt"
gosub updatestatus
Return

selectall:
loop % LV_GetCount()	
{
SendMessage, 4140, a_index - 1, 0xF000, SysListView321  ; 4140 is LVM_GETITEMSTATE.  0xF000 is LVIS_STATEIMAGEMASK.
IsChecked := (ErrorLevel >> 12) - 1  ; This sets IsChecked to true if RowNumber is checked or false otherwise.
If IsChecked = 0
	LV_Modify(a_index, "+Check")
if a_index = 101		; don't select more than max vote number
		break
}
checkedrow := LV_GetCount()
GuiControl,, % info3 ,% "Delegates Selected: " checkedrow
return

unselectall:
loop % LV_GetCount()	
{
SendMessage, 4140, a_index - 1, 0xF000, SysListView321  ; 4140 is LVM_GETITEMSTATE.  0xF000 is LVIS_STATEIMAGEMASK.
IsChecked := (ErrorLevel >> 12) - 1  ; This sets IsChecked to true if RowNumber is checked or false otherwise.
If IsChecked = 1
	LV_Modify(a_index, "-Check")
}
checkedrow := "0"
GuiControl,, % info3 ,% "Delegates Selected: " checkedrow
Return 

listview:	; check/uncheck rows checkbox on click
;msgbox % A_GuiControl "`n" A_GuiEvent
;https://autohotkey.com/docs/commands/ListView.htm#G-Label_Notifications_Secondary
rownum := A_EventInfo
;if !InStr(ErrorLevel, "S", true)	; row selected
;	Return
SendMessage, 4140, rownum - 1, 0xF000, SysListView321  ; 4140 is LVM_GETITEMSTATE.  0xF000 is LVIS_STATEIMAGEMASK.
IsChecked := (ErrorLevel >> 12) - 1  ; This sets IsChecked to true if RowNumber is checked or false otherwise.	

if (IsChecked = "1" AND A_GuiEvent = "Rightclick")
	{
	LV_Modify(rownum, "-Check")
	checkedrow--
	}
if (IsChecked != "1" AND A_GuiEvent = "Rightclick")
	{
	LV_Modify(rownum, "+Check")
	checkedrow++
	}
GuiControl,, % info3 ,% "Delegates Selected: " checkedrow
return

showhide:
gui submit,nohide

if A_GuiControl = Show passphrases
	{
	GuiControl,, %A_GuiControl%,Hide passphrases
	loop 5 {
		GuiControl, -Password +redraw, % hWndpass%a_index%
		GuiControl, -Password +redraw, % hWndpass%a_index%_2
		}
	
	}
else
	{
	GuiControl,, %A_GuiControl%,Show passphrases
	loop 5 {
		GuiControl, +Password +redraw, % hWndpass%a_index%
		GuiControl, +Password +redraw, % hWndpass%a_index%_2
		}
}		
return

savepass:
passvar := ""
loop 5 {
	passprim := pass%a_index%, passsec := pass%a_index%_2
	if passprim
		IniWrite, %passprim%, %ini%, Passphrases,pass%a_index%
	if passsec	
		IniWrite, %passsec%, %ini%, Passphrases,pass%a_index%_2
}
newline := "Passphrased are saved to settings"
gosub updatestatus
return

deletepass:
IniDelete, %ini%, Passphrases
newline := "Passphrased are deleted from settings"
gosub updatestatus
return

updatestatus:
FormatTime, nowtime,,HH:mm:ss - 
guicontrolget, statlog,, % statuslog
GuiControl,, %statuslog%,%nowtime% %newline%`n%statlog%
Return

;###########################
GuiClose:
ExitApp



;######## get account info based on passphrase ##########
Accountinfo:
GuiControlGet, controlcalled, FocusV
GuiControlGet, controlcalled2, FocusV
while (controlcalled = controlcalled2)
	{
	sleep 50
	GuiControlGet, controlcalled2, FocusV
	if a_index = 3000	; so it wont hung
		break
	}

Accountinfo_enter:
accountcount:=0
Gui, submit,nohide	

if !notsecureok
	ifinstring node, http:// 
	MsgBox , 260, Unencrypted connection to Node, The Node URL you provided has no "https" in it.`nThe tool needs to send your passphrase(s) to your node as POST data.`nSending you passphrase(s) through an unencrypted connection is a security risk.`n`nDo you want to continue anyway?
	IfMsgBox No
		{
		newline := "Please provide a secure Node URL"
		gosub updatestatus
		notsecureok := 1
		return
		}

	notsecureok := 1


loop 5 {
	if (A_GuiControl AND if !InStr(A_GuiControl, " "))			; called by a specific field being edited
		passphrase := %A_GuiControl%, c := SubStr(A_GuiControl, 0), controlname := account%c% 
	else
		c := a_index, passphrase := pass%a_index%, controlname := account%c%

	if !passphrase 
		{
		GuiControl,,%controlname%
		continue
		}
		
accountcount++	

	newline := "Getting Account info for passphrase " c
	gosub updatestatus
	oHTTP.Open("POST", node "/api/accounts/open" , False)	;Post request
	oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded") 
	oHTTP.Send("secret=" passphrase)	;Send POST request
	voterinfo := oHTTP.ResponseText

	regexmatch(voterinfo,"i){""success"":true,""account"":{""address"":""(.*?)"",""unconfirmedBalance"":""(.*?)"",""balance"":""(.*?)"",""publicKey"":""(.*?)"",""unconfirmedSignature"":.,""secondSignature"":(.*?),""secondPublicKey"":(.*?),""multisignatures"":(.*?),""u_multisignatures"":(.*?)}}",d)	

	if d
		{
		voteraddress_%c% := d1, unconfirmedbalance_%c% := d2 / 100000000, balance_%c% := round(d3 / 100000000,2),voterpubkey_%c% := d4,secondsig_%c% := d5,secondpubkey_%c% := d6
		if secondsig_%c% != 0
			SetEditPlaceholder(hWndpass%c%_2, "Needs second pass!",1)
		Else
			SetEditPlaceholder(hWndpass%c%_2, "No second pass needed",1)

		GuiControl,,%controlname%,% "Address: " voteraddress_%c% "`nBalance: " balance_%c% " Lisk"
		}
	
	if !d
		{
		GuiControl,,%controlname%
		newline := "Couldn't get account info from """ node """"
		gosub updatestatus
		return
		}

		
	;if A_GuiControl			; if specific field called it, break the loop
	;	break

}
if A_GuiEvent = Normal
	gosub getvotedlist
return



#IfWinActive ahk_group Self
~enter::			; so enter saves changes in input fields
~NumpadEnter::
~Tab::
GuiControlGet, controlcalled, FocusV

if controlcalled not in node,pass1,pass2,pass3,pass4,pass5,pass1_2,pass2_2,pass3_2,pass4_2,pass5_2,votinglist
	return

If (controlcalled = "votinglist")	
	goto transferlist_enter
	
ControlFocus ,,

If (controlcalled = "node")
	goto nodecheck_enter

If controlcalled in pass1,pass2,pass3,pass4,pass5,pass1_2,pass2_2,pass3_2,pass4_2,pass5_2
	goto Accountinfo_enter
return

; copy selected rows to clipboard
~^c::
GuiControlGet, controlcalled, Focus
If controlcalled != sysListView321
	return

sellist:="",rowNumber := 0,rowcount:=0
Loop
{
    RowNumber := LV_GetNext(RowNumber)  ; Resume the search at the row after that found by the previous iteration.
    if not RowNumber  ; The above returned zero, so there are no more selected rows.
        break
		
	row:=""
	loop % LV_GetCount("Column") 
		{
		if a_index in 3,4,5
			{
			LV_GetText(x, RowNumber,a_index)
			If x
				row .= x a_tab
			}	
		}
		
	sellist .= row "`n"	
	rowcount++
}

newline := rowcount " delegates info was copied to the clipboard"
gosub updatestatus
return


;#### check if provided node url is working (send sync api call)
nodecheck:
GuiControlGet, controlcalled, FocusV


while (controlcalled = "node")
	{
	sleep 50
	GuiControlGet, controlcalled, FocusV
	if a_index = 3000	; so it wont hung
		break
	}

nodecheck_enter:
Gui, submit,nohide	
	
if SubStr(node, 0) = "/"
	node := SubStr(node, 1,-1)

newline := "Checking """ node """"
gosub updatestatus

url := node "/api/loader/status/sync"
statuscheck := RegExReplace(WinHttpReq.ResponseText(WinHttpReq.Send(WinHttpReq.Open("GET",url))),"{""success"":(.*?),""syncing"":(.*?),""blocks"":(.*?),""height"":(.*?)}","$1")

; TODO - if syncing, then .....
If statuscheck = true
	newline := "Node is ready to go"
else 
	newline := "No response from Node!"

if (node_old AND node != node_old)
	{
	IniWrite, %node%, %ini%, General,Node
	node_old := node
	gosub startcheck
	}
node_old := node
gosub updatestatus
return


;##### parse delegate list (or filtered list) and display in table. check for votes) ##
transferlist:

GuiControlGet, controlcalled, FocusV

while (controlcalled = "votinglist")
	{
	sleep 50
	GuiControlGet, controlcalled, FocusV
	if a_index = 3000	; so it wont hung
		break
	}

transferlist_enter:
Gui, submit,nohide

rowcount:="0"	
LV_Delete()

LV_ModifyCol(16, 0),LV_ModifyCol(7, 0),LV_ModifyCol(8, 0),LV_ModifyCol(9, 0),LV_ModifyCol(10, 0),LV_ModifyCol(11, 0)

If A_GuiControl = Display All Delegates
	{
	GuiControl, , %A_GuiControl%,Display Filtered List
	votinglist := ""
	}
else
If A_GuiControl = Display Filtered List
	{
	GuiControl, , %A_GuiControl%,Display All Delegates
	Gui, submit,nohide
	}
If !votinglist
	{
	newline := "Displaying complete delegate list"

	gosub updatestatus
	
	loop, parse, delegate_list, {
		{
		regexmatch(a_loopfield,"""username"":""(?<username>.*?)"",""address"":""(?<address>.*?)"",""publicKey"":""(?<publickey>.*?)"",""vote"":""(?<vote>.*?)"",""producedblocks"":""?(?<producedblocks>.*?)""?,""missedblocks"":""?(?<missedblocks>.*?)""?,""rate"":(?<rate>.*?),""approval"":""?(?<approval>.*?)""?,""productivity"":""?(?<productivity>.*?)""?}",delegate_)

		if !delegate_
			continue
		
		loop 5 {
		if !voteraddress_%a_index%
			continue
		votedfor%a_index% := "NO"
		ifinstring voted_%a_index%, %delegate_address%	; ignore account you already voted for
			votedfor%a_index% := "YES"
			
		}	
	
		rowcount++		
		;  get who voted for this delegate
		if rowcount = 1		; get list only once
			votes := WinHttpReq.ResponseText(WinHttpReq.Send(WinHttpReq.Open("GET",node "/api/delegates/voters?publicKey=" voterpubkey_1)))

	
		votedback := "NO"		
		Ifinstring votes, %delegate_address%
			votedback := "YES"
		
		if !isdelegate_1		; voter is not delegate, don't display voteback
			votedback := ""		
		Else	
			{
			votedback := "NO"		
			Ifinstring votes, %delegate_address%
				votedback := "YES"
			}
		LV_Insert(rowcount,"","",rowcount,delegate_rate,delegate_username,delegate_address,votedfor1,votedfor2,votedfor3,votedfor4,votedfor5,votedback,delegate_approval,delegate_producedblocks,delegate_missedblocks,delegate_productivity,delegate_publickey)

		
	;	if ((votedfor1 = "NO" OR votedfor2 = "NO" OR votedfor3 = "NO" OR votedfor4 = "NO" OR votedfor5 = "NO") AND delegate_rate)
		;if delegate_username = Vega				; little bit of self interest
		;	LV_Modify(rowcount, "+Check")			; never hurt anyone
		
		}
		

	}

checkedrow:="0"
newline := "Displaying filtered delegate list"
loop, parse, votinglist, `n,`r
	{
	if (a_index = "1" and A_GuiControl != "votinglist")		; just some typing
		gosub updatestatus
	if !a_loopfield
		continue
	; determine if username,address,pubkey
	line := a_loopfield	
	delegate_username := "", delegate_address := "", delegate_publickey :=  "",delegate_vote := "",	delegate_producedblocks := "", delegate_missedblocks := "", delegate_rate := "", delegate_approval := "", delegate_productivity := ""
	loop, parse, delegate_list, {
		{
		
		Ifnotinstring a_loopfield, "%line%"
			continue

		regexmatch(a_loopfield,"""username"":""(?<username>.*?)"",""address"":""(?<address>.*?)"",""publicKey"":""(?<publickey>.*?)"",""vote"":""(?<vote>.*?)"",""producedblocks"":""?(?<producedblocks>.*?)""?,""missedblocks"":""?(?<missedblocks>.*?)""?,""rate"":(?<rate>.*?),""approval"":""?(?<approval>.*?)""?,""productivity"":""?(?<productivity>.*?)""?}",delegate_)
		break
		}

	If !delegate_username 	
		delegate_username := line, delegate_address := "NOT FOUND IN DELEGATE LIST"
		
		loop 5 {
		if !voteraddress_%a_index%
			continue		
		votedfor%a_index% := "NO"
		ifinstring voted_%a_index%, %delegate_address%	; ignore account you already voted for
			votedfor%a_index% := "YES"
		}	

				
		rowcount++	
		
		;  get who voted for this delegate
		if rowcount = 1		; get list only once
			votes := WinHttpReq.ResponseText(WinHttpReq.Send(WinHttpReq.Open("GET",node "/api/delegates/voters?publicKey=" voterpubkey_1)))

		if !isdelegate_1		; voter is not delegate, don't display voteback
			votedback := ""		
		Else	
			{
			votedback := "NO"		
			Ifinstring votes, %delegate_address%
				votedback := "YES"
			}
		LV_Insert(rowcount,"","",rowcount,delegate_rate,delegate_username,delegate_address,votedfor1,votedfor2,votedfor3,votedfor4,votedfor5,votedback,delegate_approval,delegate_producedblocks,delegate_missedblocks,delegate_productivity,delegate_publickey)

	if ((votedfor1 = "NO" OR votedfor2 = "NO" OR votedfor3 = "NO" OR votedfor4 = "NO" OR votedfor5 = "NO") AND delegate_rate)
		{
		LV_Modify(rowcount, "+Check")
		checkedrow++
		}
	;if delegate_username = Vega				; little bit of self interest
		;LV_Modify(rowcount, "+Check")			; never hurt anyone
	
	}
		
loop % LV_GetCount("Col")	
	if a_index not in 7,8,9,10,15,16
		LV_ModifyCol(a_index,"AutoHdr")

loop % LV_GetCount()	
	{
	LV_GetText(vf, a_index, 7)
	if vf
		LV_ModifyCol(7, 60)
	LV_GetText(vf, a_index, 8)
	if vf
		LV_ModifyCol(8, 60)
	LV_GetText(vf, a_index, 9)
	if vf
		LV_ModifyCol(9, 60)
	LV_GetText(vf, a_index, 10)
	if vf
		LV_ModifyCol(10, 60)
	}

if isdelegate_1
	LV_ModifyCol(11, 80)	; show voted you column

	if !isdelegate_1
	LV_ModifyCol(11, 0)	; show voted you column
LV_ModifyCol(1,"25")
delegatelistcount := LV_GetCount()
GuiControl,,%info2%,Delegates displayed: %delegatelistcount%
GuiControl,, % info3 ,% "Delegates Selected: " checkedrow
GuiControl,,delegatelisted,Delegates listed: %delegatelistcount%
GuiControl,,delegatecount,Total Delegates: %TotalDelegateCount%

return

;##### get full delegate list from node #####
getdelegatelist:
newline := "Getting full delegate list"
gosub updatestatus

limit := "100", offset := "0",delegate_list :="",countlist:=""
loop 20 {
url := node "/api/delegates?limit=100&offset=" offset "&orderBy=rate"
delegate_list .= WinHttpReq.ResponseText(WinHttpReq.Send(WinHttpReq.Open("GET",url)))
offset += limit
if a_index = 1	; get total delegate count
	TotalDelegateCount := regexreplace(delegate_list,".*""totalCount"":(.*?)}","$1"), TotalCount := ceil(regexreplace(delegate_list,".*""totalCount"":(.*?)}","$1") / limit)		; determine how many api calls needed to get all delegates info

if a_index = %TotalCount%
	break
}
isdelegate_1 := ""
IfInString delegate_list, %voteraddress_1%
	isdelegate_1 := "YES"

newline := "Got full delegate list (" TotalDelegateCount " Delegates)"
gosub updatestatus

GuiControl,, %info1%,% "Delegates total: " TotalDelegateCount 

return


; get the list of accounts voted for your delegate
getvotedlist:
newline := "Getting list of accounts you voted for"
	gosub updatestatus
loop 5 {
if !voteraddress_%a_index%
	continue
voted_%a_index% := WinHttpReq.ResponseText(WinHttpReq.Send(WinHttpReq.Open("GET",node "/api/accounts/delegates/?address=" voteraddress_%a_index%)))

StringReplace, voted_%a_index%, voted_%a_index%, username, username, UseErrorLevel
votedcount_%a_index% := ErrorLevel
infoline := info (a_index + 3)

GuiControl,, % info%infoline% ,% "Account " a_index ": votes cast " votedcount_%a_index% " (of 101)"

;newline := "Already voted for " votedcount_%a_index% " delegates with account " a_index
;gosub updatestatus
}
return


;########## Vote/unvote selected delegates ##############
VOTE_UNVOTE:

ifinstring node, http://
	MsgBox , 260, Unencrypted connection to Node, To vote`, the script needs to send your passphrase(s) to your node as POST data.`nSending you passphrase(s) through an unencrypted connection is a security risk.`n`nDo you want to continue anyway?
	IfMsgBox No
		{
		newline := "Voting was interrupted (No https connection)"
		gosub updatestatus
		return
		}

voteprefix := "+"	
If A_GuiControl = Unvote Selected
	voteprefix := "-"


Gui +OwnDialogs
loop % accountcount 
	{
	tovotelist%a_index% := "", tovotecount%a_index%:="0", novotecount%a_index%:="0",countselected:="",votemaxed_%a_index%:=""
	
	if (voteprefix = "+" AND votedcount_%a_index% = "101")	; no more voting spots for account	
		{
		newline := "Account " a_index " has already voted for 101 delegates"
		gosub updatestatus
		votemaxed_%a_index% := 1
		}
	}
	
Gui, submit,nohide	
RowNumber:=0
	
loop 5 
	{
	voted_%a_index% := WinHttpReq.ResponseText(WinHttpReq.Send(WinHttpReq.Open("GET",node "/api/accounts/delegates/?address=" voteraddress_%a_index%)))
	tovotelist%a_index% :="", novotecount%a_index%:="",tovotecount%a_index%:=0
	}
	
Loop		; get selected rows from lisview 
{
	RowNumber := LV_GetNext(RowNumber,"checked")
	if not RowNumber 
		break
	countselected := a_index	
	LV_GetText(publickey, RowNumber,"16")	; get public key			
	LV_GetText(un, RowNumber,"4")
	
	
	loop 5 {
	
	if !voted_%a_index%
		continue
		
	if ((voteprefix = "+" AND !InStr(voted_%a_index%, publickey)) OR (voteprefix = "-" AND InStr(voted_%a_index%, publickey))) 
		{	
		if ((voteprefix = "+") AND (tovotecount%a_index% > (101 - votedcount_%a_index%) - 1))	; no more voting spots for account
			continue

		tovote = "%voteprefix%%publickey%"
		tovotecount%a_index%++
		}
	else
		novotecount%a_index%++
		
	if !tovote
		continue
	
	if (voteprefix = "+" AND InStr(voted_%a_index%, publickey)) 
		continue

	if (voteprefix = "-" AND !InStr(voted_%a_index%, publickey)) 
		continue

	ifinstring tovotelist%a_index%, %tovote%
		continue
	
	if tovotelist%a_index%
		if tovotecount%a_index% >= 33		; bulk vote maximum allowed
			tovotelist%a_index% .= "|", tovotecount%a_index% := 0
	else	
		tovotelist%a_index% .= ","
	
	tovotelist%a_index% .= tovote
	tovotelist%a_index%_names .= un "`n"

	}	

}

if !countselected	; no delegate selected
	Return

; display some voting data in status log
newline := delegatelistcount " Delegate names displayed - " countselected " selected"
gosub updatestatus

;###### now, do the actual voting ######
loop % accountcount {			; vote from every account
count := a_index
if votemaxed_%a_index% = 1	
	continue
votingfor_count := countselected - novotecount%count%

newline := "Account " count " already voted for " novotecount%count% " voting for: " votingfor_count
if voteprefix = -
	newline := "Account " count " unvoting " votingfor_count
gosub updatestatus	

if votingfor_count = 0
	continue

secdata:=""
	passphrase := pass%count%, voterpubkey := voterpubkey_%count%, secondpassphrase := pass_%count%_2
	
	stringsplit tovotelistpart,tovotelist%count%,|	
	
	
	if (secondsig_%count% > 0 AND tovotelistpart0 > 0)	; there is a second passphrase for this account
		{
		Prompt := "Your account " voteraddress_%count% " has a second passphrase`n`nPlease enter it here" 
		if !secondpassphrase
		InputBox, secondpassphrase , Second Passphrase Required, %Prompt%, HIDE, 410, 160, , , , , 
		if secondpassphrase
			secdata = "secondSecret":"%secondpassphrase%",
		If ErrorLevel
			{
			newline := "Account " count " didn't (un)vote, no second passphrase provided"
			gosub updatestatus
			break
			}
		}

	loop % tovotelistpart0 ; send the vote api calls
	{
	delegates := tovotelistpart%a_index%
	data = {"secret":"%passphrase%", %secdata% "publicKey":"%voterpubkey%", "delegates":[%delegates%]}
	
	
;clipboard :=  tovotelist0 "`n" tovotelist%a_index%_names "`n`n" data
;msgbox % clipboard
	
	oHTTP.Open("PUT", node "/api/accounts/delegates", false)
	oHTTP.setRequestHeader("Content-Type", "application/json")
	oHTTP.Send(data)
	responsetext := oHTTP.ResponseText
	
	newline := "Server response: " responsetext
	stringreplace nopassdata, data, %passphrase%,secretpassphrase
	stringreplace nopassdata, nopassdata, %secondpassphrase%,secretpassphrase2
	FileAppend voterequest: %nopassdata%`n%newline%`n,voteresponse.log	
	
	Ifinstring responsetext, "success":true
		{
		newline := "Account " count " successfully voted for: " tovotecount%count% " delegate(s)"
		if voteprefix = -
			newline := "Account " count " successfully unvoted " tovotecount%count% " delegate(s)"
		}

	Ifinstring responsetext, "error"
		newline := "Account " count " Error: " RegExReplace(responsetext,".*error"":""(.*?)"".*","$1")
		
	gosub updatestatus	
	newline := "Waiting 15 secs for Lisk to process new votes"
	gosub updatestatus			
	sleep 15000

	}
	
}

gosub startcheck			; update delegate info
return


;# just stuff to make editing the script easier for me
#IfWinActive ahk_group justthiswin
~^s::
Sleep 500
reload
return
#IfWinActive


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

SetEditPlaceholder(control, string, showalways = 0){
	if control is not number
		GuiControlGet, control, HWND, %control%
	if(!A_IsUnicode){
		VarSetCapacity(wstring, (StrLen(wstring) * 2) + 1)
		DllCall("MultiByteToWideChar", UInt, 0, UInt, 0, UInt, &string, Int, -1, UInt, &wstring, Int, StrLen(string) + 1)
	}
	else
		wstring := string
	DllCall("SendMessageW", "UInt", control, "UInt", 0x1501, "UInt", showalways, "UInt", &wstring)
	return
}