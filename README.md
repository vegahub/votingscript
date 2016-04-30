# votingscript
Vote for a list of Lisk Delegates (https://lisk.io)

This is an Autohotkey script for voting Lisk Delegates.

Few nodes and warnings:
- This script written in AHK, windows only. Should work with any windows WinXP+
- Script not compiled, download and install Autohotkey and run you can run any .ahk file, or you can compile it with ahk2exe in the install dir.
- It can vote for delegate username, lisk account address or public key. You can mix them on the list.
- One name/address/key per line
- Didn't test it too much, let me know if there is any problems
- Doesn't work if second passphrase is set for voting account. will add for mainnnet
- Always be cautious with your passphrase! For this reason I'd prefer if someone would check my code, verifing that there is nothing hinky in it.
- The default node is login.lisk.io, but it's slow, provide your own node address if you can
- also recommend that you only use https address, as the script will need to send your passphrase to the node. 
