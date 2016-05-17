class Bin
{
	ObjDefine := {}
	static sizeof := {Int64:8,Int:4,Short:2,Char:1,UInt:4,UShort:2,UChar:1,Double:8,Float:4,Ptr:A_PtrSize,UPtr:A_PtrSize}
	static Encodings := {"":1+A_IsUnicode,"Utf-8":1,"Utf-16":2,base:{__call:Bin.getCharacterSize}}
	class Region
	{
		__New(Offset=0,Size=0)
		{
			this.1 := Offset
			this.2 := Size
		}
		_Test(Region)
		{
			return ( -(Region.1<0) | ( (Region.1 + Region.2) > this.2) )
		}
	}
	class AccessFn
	{
		_GetIntend(Region="")
		{
			return Region?this.Region._Test(Region):0
		}
		_SetIntend(Region="")
		{
			if !IsObject(Region)
				return 0
			if (Region.2<0)
				return -2
			d := this.Region._Test(Region)
			if (d>0)
				return this._Resize(Region.1+Region.2)
			return d
		}
		_Resize(Size)
		{
			if (Size!=this.Region.2)
			{
				if !IsObject(this.AllocedRegion)
					this.AllocedRegion := this.Region
				if !(Size>this.AllocedRegion.2)
					this.Region.2 := Size
				else
					return !this.realloc(Size)
			}
			return 0
		}
	}
	class AllocFn
	{
		alloc(Size=0)
		{
			this.Data := ""
			this.SetCapacity("Data",Size)
			this.Region := {1:(Size>0)? this.GetAddress("Data") : 0 ,2:Size,base:Bin.Region}
		}
		realloc(Size=0)
		{
			this.SetCapacity("Data",Size)
			this.Region := {1:this.GetAddress("Data"),2:Size,base:Bin.Region}
			return 1
		}
		AllocedRegion[]
		{
			get{
				return {1:this.GetAddress("Data"),2:this.GetCapacity("Data"),base:Bin.Region}
			}
		}
	}
	class ObjHelper
	{
		Merge(Objects)
		{
			For Each,Obj in Objects
				For Key,Value in Obj
					This[Key] := Value
		}
	}
	class LinkerFn
	{
		class File
		{
			ToFile(FileName,Encoding="")
			{
				if this._GetIntend()
					return
				oFile := Encoding ? FileOpen( FileName, "w", Encoding ) : FileOpen( FileName, "w" )
				oFile.RawWrite( This.Region.1, This.Region.2 )
				oFile.Close()
				return this
			}
			FromFile(FileName,Encoding="")
			{
				oFile := Encoding ? FileOpen( FileName, "r", Encoding ) : FileOpen( FileName, "r" )
				if this._SetIntend([0,oFile.Length])
					return
				Size := oFile.RawRead( (this.region.1+0), oFile.Length )
				this._Resize( Size )
				return this
			}
		}
		class Str
		{
			StrGet(Encoding="")
			{
				if this._GetIntend()
					return
				max := floor(this.region.2/Bin.Encodings[ Encoding ])
				if Encoding
					ret := StrGet( (this.Region.1+0), max, Encoding)
				else
					ret := StrGet( (this.Region.1+0), max)
				return ret
			}
			StrPut(String,Encoding="")
			{
				Len := Encoding ? StrPut( String, Encoding ) : StrPut(String)
				if this._SetIntend( [ 0, Len * Bin.Encodings[ Encoding ] ] )
					return
				if (Encoding)
					StrPut(String,(this.Region.1+0),Encoding)
				else
					StrPut(String,(this.Region.1+0))
				return this
			}
			Str[]{
				get{
					return this.StrGet()
				}
				set{
					return this.StrPut(value)
				}
			}
		}
		class Crypt
		{
			CryptTo(Flags)
			{
				if this._GetIntend()
					return
				DllCall("crypt32\CryptBinaryToString", "ptr", this.Region.1, "uint", this.Region.2, "uint", Flags, "ptr", 0, "uint*", Size)
				oBuf := Bin.alloc(Size*(A_IsUnicode+1))
				if oBuf._SetIntend([0,Size*(A_IsUnicode+1)])
					return
				DllCall("crypt32\CryptBinaryToString", "ptr", this.Region.1, "uint", this.Region.2, "uint", Flags, "ptr", oBuf.Region.1, "uint*", Size)
				return oBuf
			}
			CryptFrom(oBuf,Flags)
			{
				if oBuf._GetIntend()
					return
				DllCall("crypt32\CryptStringToBinary", "ptr", oBuf.Region.1, "uint", 0, "uint", Flags, "ptr", 0, "uint*", Size, "ptr", 0, "ptr", 0)
				if this._SetIntend([0,Size])
					return
				DllCall("crypt32\CryptStringToBinary", "ptr", oBuf.Region.1, "uint", 0, "uint", Flags, "ptr", this.Region.1, "uint*", Size, "ptr", 0, "ptr", 0)
				return this
			}
			Hex[]{
				set{
					return This.CryptFrom(value,4)
				}
				get{
					return This.CryptTo(4)
				}
			}
			base64[]{
				set{
					return This.CryptFrom(value,1)
				}
				get{
					return This.CryptTo(1)
				}
			}
		}
		class Num
		{
			NumGet(OffSet=0,Type="UPtr")
			{
				if this._GetIntend([OffSet,Bin.sizeof[Type]])
					return
				return NumGet((this.Region.1+0),OffSet,Type)
			}
			NumPut(Num,Offset=0,Type="UPtr")
			{
				if this._SetIntend([Offset,Bin.sizeof[type]])
					return
				NumPut(Num,(this.Region.1+0),OffSet,Type)
				return this
			}
		}
		class Rtl
		{
			MoveTo(Target)
			{
				if this._GetIntend()
					return
				if IsObject(Target)
				{
					if Target._SetIntend([0,this.Region.2])
						return
					DllCall("RtlMoveMemory", "ptr", Target.Region.1,"ptr", this.Region.1, "ptr", this.Region.2,"Cdecl")
				}
				else
					DllCall("RtlMoveMemory", "ptr", Target,"ptr", this.Region.1, "ptr", this.Region.2,"Cdecl")
			}
			MoveFrom(Source,Size="")
			{
				if IsObject(Source)
				{
					if Source._GetIntend()
						return
					if This._SetIntend([0,Source.Region.2])
						return
					DllCall("RtlMoveMemory", "ptr", this.Region.1,"ptr", Source.Region.1, "ptr", Source.Region.2,"Cdecl")
				}
				else
				{
					if This._SetIntend([0,Size])
						return
					DllCall("RtlMoveMemory", "ptr", this.Region.1,"ptr", Source, "ptr", Size,"Cdecl")
				}
			}
			Zero(Size="")
			{
				Size := Size ? Size : this.Region.2
				if This._SetIntend([0,Size])
					return
				DllCall("RtlZeroMemory","ptr",this.region.1,"ptr",Size,"Cdecl")
			}
			Copy()
			{
				return Bin.MoveFrom(This)
			}
		}
		class Struct
		{
			Offset(Offset,Size="")
			{
				Size:=(Size ? Size : this.Region.2-Offset)
				if this._SetIntend([Offset,Size])
					return
				oBuf := Bin.Build("wrapper")
				oBuf.Region   := {1:this.Region.1 + Offset,2: Size ,base:bin.Region}
				return oBuf
			}
		}
	}
	getCharacterSize(Encoding="")
	{
		static Test,Init := VarSetCapacity(Test,4*3,0)
		StrPut("  ",&Test,3,Encoding)
		For Each,CharType in {1:"UChar",2:"UShort",4:"UInt"}
			if (NumGet(Test,0,CharType)=NumGet(Test,Each,CharType))
				return this[Encoding] := Each
		return this[Encoding] := ""
	}
	Define(Key,Obj)
	{
		if (Key == "default")
		{
			this.Actions := new this.ObjHelper()
			this.Actions.Merge(Obj)
		}
		This.ObjDefine[Key] := Obj
	}
	Build(Key="default")
	{
		This.ObjHelper.Merge.Call( oBinBase := {}, This.ObjDefine[Key] )
		oBin := {base:oBinBase}
		return oBin
	}
	Call(Id,p*)
	{
		if (!ObjHasKey(This,Id)&&this.Actions.HasKey(Id))
		{
			oBin := this.Build()
			oBin.Alloc()
			(oBin[Id]).Call(oBin,p*)
			return oBin
		}
	}
	Set(Id,value)
	{
		if (!ObjHasKey(This,Id)&&this.Actions.HasKey(Id))
		{
			oBin := this.Build()
			oBin.Alloc()
			oBin[Id] := value
			return oBin
		}
	}
	Init()
	{
		Static a:= Bin.Init()
		LinkerFn := {}
		For each,Format in this.LinkerFn
		{
			If IsObject(Format)
				This.ObjHelper.Merge.Call(LinkerFn,[Format])
		}
		This.Define("default",[This.AccessFn,This.AllocFn,LinkerFn])
		THis.Define("wrapper",[This.AccessFn,LinkerFn])
		This.base := {__Call:this.Call,__Set:this.Set}
	}
}
