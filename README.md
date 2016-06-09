
# Windows Voting Tool
Vote for a list of Lisk Delegates (https://lisk.io)

This is an Autohotkey script for voting Lisk Delegates.
You can find Autohotkey here: https://autohotkey.com/

Changelog
v0.2.6
    - wait for new block before sending second voting transaction
v0.2.5 
	- Changed input fields behavior to improve reliability
	- To prevent accidental selections, row checkbox selection now works with right click instead of left click
	- copy selected rows from delegate list with CTRL+C (rank,username,address) 
	- Button to get my recommended delegate list
	- some small improvements
	
Current features:

- You only need to provide your passphrase and it works
- You can vote/unvote with up to 5 accounts simultaneously (the first should always be your delegate account)
- Displays some basic account information
- Displays full registered delegate list
- Filter list by providing a list of delegate names, addresses or public keys, or any mix of them
- Shows what delegate you already voted for, who voted you back
- Can vote, unvote with up to 5 accounts  at once

Few nodes and warnings:
- This script written in AHK, windows only. Should work with any windows WinXP+
- You can save passphrases but it will be in plain text, please be carefull. For security reasons it won't save second passphrases, it will ask for it when needed (voting)
- If some information is not updating after voting, please wait a few and use "Update All Data" button. This is because sometimes the votes doesn't get included into the blockchain fast enough, I'll automate checking later
- if you vote for more than one delegate at the time, the vote will be bundled into one transaction. if you selected more than 33 delegates it will be split into as many transactions as necessary.
- if you selected more delegates than voting spots you have left, it will cast what it can, and ignore the additional votes (needs testing)
- if you already voted for 101 delegates, any additional votes will simple be ignored
- There may be some quirks in this version, and some bugs. Let me know if you find any.

Screenshot

![Alt text](http://i.imgur.com/X2AuHj4.png "Screenshot")
