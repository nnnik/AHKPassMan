#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Persistent
SetBatchLines,-1
#Include Encrypt.ahk


if FileExist("EncData.dat")
{
	EncDat := Bin.FromFile("EncData.dat")
	Loop
	{
		InputBox,PassStr,Password,% ["Please insert your Master password","Please insert your correct Master password"][(A_Index>1)+1]
		if !passstr
			break
		PassDat := Bin.StrPut(PassStr,"Utf-8")
		PassStr := ""
		Data := Enc.Decrypt(EncDat,PassDat)
		EncDat := ""
		If IsObject(Data)
		{
			If IsObject(d := OpenData(Data))
			{
				Data := ""
				break
			}
		}
	}
}
Gui,Add,ActiveX,vWb x0 y0 h400 w600,Shell.Explorer
Wb.Navigate("about:blank")
HTML = 
(
<!DOCTYPE HTML>
<html>
	<head>
		<style>
			td, th,table {
				border:0px;
			}
			th, td {
				padding: 1`%;
				text-align: left;
			}
			body {
				background-color: #F5F5FF;
			}
		</style>
	</head>
	<body>
		<table id="list" style="width:100`%">
			<tr style="background-color:#efdfdf;">
				<th style="width:50`%">Name</th>
				<th>Password</th>
			</tr>
		</table>
		<button id="add" style="width:100`%">Add New</button>
	</body>
</html>
)
while wb.ReadyState != 4
	Sleep 10
wb.Document.open()
wb.Document.write(html)
wb.Document.close()
btnadd := wb.Document.getElementById("add")
btnadd.onclick := func("addnew")
l := new List(wb,"list")
For each,row in d
	l.Push(row*)
d := ""
Gui,Show,h400 w600,Password Manager
return
GuiClose:
Out := []
For each,row in l.Table
{
	Out2 := []
	Out.Push(Out2)
	For each, td in row
		Out2.Push(td.innerHTML)
}
while !PassDat.Region.2
{
	InputBox,PassStr,Password,Please insert your new Master password
	PassDat:= Bin.StrPut(PassStr,"Utf-8")
	PassStr := ""
}
Enc.Encrypt(savedata(Out),PassDat).toFile("EncData.dat")
ExitApp



class List
{
	__new(wb,id)
	{
		this.document := wb.Document
		this.tbody := wb.Document.getElementById(id).getElementsByTagName("tbody")[0]
		this.Table:=[]
		this.Rows:=[]
		this.colors := [0xcfcfff,0xffcfcf]
		this.hovercolor := 0xcfffcf
	}
	Push(p*)
	{
		tr  := this.Document.createElement("tr")
		tr.style.backgroundColor := this.colors[mod(this.Table.Length(),2)+1]
		tds := []
		for each,Text in p
		{
			tds.Push(td := this.Document.createElement("td"))
			td.appendChild( this.Document.createTextNode( Text ) )
			tr.appendChild(td)
			td.onclick := this.onclick.bind(this,this.Table.Length()+1,Each)
			td.onmouseenter := this.onmouseenter.bind(this,this.Table.Length()+1,Each)
		} 
		this.tbody.appendChild(tr)
		this.Rows.Push(tr)
		this.Table.Push(tds)
	}
	onclick(x,y)
	{
		InputBox,newval,Please Select,% ["Please select a name for the password","Please select a password"][y]
		if !newval
			return
		td := this.Table[x,y]
		td.innerHTML := ""
		td.appendChild(this.Document.createTextNode( newval ))
		
	}
	onmouseenter(x,y)
	{
		static LastMouseEnter
		this.Rows[LastMouseEnter].style.backgroundColor := this.colors[mod(LastMouseEnter+1,2)+1]
		LastMouseEnter := x
		this.Rows[LastMouseEnter].style.backgroundColor := this.hovercolor
	}
}
addnew()
{
	global l
	Loop 2
	{
		InputBox,newval%A_Index%,Please Select,% ["Please select a name for the password","Please select a password"][A_Index]
		if !newval%A_Index%
			return
	}
	l.Push(newval1,newval2)
}
OpenData(Data)
{
	ret := []
	Sub := Data.Copy()
	loop 
	{
		oo := []
		Loop,2
		{
			oo.Push(s:=Sub.StrGet("Utf-16"))
			if !mod(A_Index,2)
				ret.Push(oo)
			if (!s)
				return mod(A_Index,2)?ret:""
			Sub := Sub.Offset(StrPut(s,"Utf-16")*2)
		}
	}
}
SaveData(passarray)
{
	oBin := Bin.Alloc()
	For each,KeyVal in passarray
		For each,str in KeyVal
			oBin.Offset( oBin.Region.2, StrPut( str, "Utf-16" ) * 2 ).StrPut( str, "Utf-16" )
	oBin.NumPut(0,oBin.Region.2,"UShort")
	return oBin
}
