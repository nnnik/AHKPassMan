#Include Bin.ahk
Class Enc
{
	Calc2( A, B, C )
	{
		D := 0 
		Loop 8
		{
			bA := (A&0xFF), bB := (B&0xFF), bC := (C&0xFF)
			D := this.RotateRight( D ^ this.FPM( bA+333, this.prime[ bB ], this.prime[ 100 + bB + bC ] ) ,8)
			A := A>>8, B := B>>8, C := C>>8
		}
		return D
	}
	Calc1( p* )
	{
		ret := 0
		For each,val in p
			ret := ret ^ val
		return ret
	}
	Encrypt(oBinEnc,oBinPass)
	{
		oBinEnc := This.WrapData(oBinEnc)
		Loop % oBinPass.Region.2
		{
			Dir := !Dir
			PassVal := oBinPass.NumGet( A_Index-1, "UChar")
			Loop 3
				PassVal := PassVal | (PassVal<<(2**(A_Index+2)))
			Shuffler := 0
			Loop % oBinEnc.Region.2/8
			{
				Id := Dir ? (A_Index-1)*8 : oBinEnc.Region.2-(A_Index*8)
				ThisVal := oBinEnc.NumGet( Id,"Int64" )
				NewThisVal := this.Calc1( ThisVal, PassVal, Shuffler )
				oBinEnc.NumPut( NewThisVal, Id, "Int64" )
				Shuffler := this.Calc2( Shuffler, ThisVal , PassVal )
			}
		}
		return oBinEnc
	}
	Decrypt(oBinDec,oBinPass)
	{
		oBinDec := oBinDec.Clone()
		Dir := !Mod(oBinPass.Region.2,2)
		Loop % oBinPass.Region.2
		{
			Dir := !Dir
			PassVal := oBinPass.NumGet( oBinPass.Region.2-A_Index, "UChar")
			Loop 3
				PassVal := PassVal | (PassVal<<(2**(A_Index+2)))
			Shuffler := 0
			Loop % oBinDec.Region.2/8
			{
				Id := Dir ? (A_Index-1)*8 : oBinDec.Region.2-A_Index*8
				ThisVal := oBinDec.NumGet( Id,"Int64" )
				NewThisVal := this.Calc1( ThisVal, PassVal, Shuffler )
				oBinDec.NumPut( NewThisVal, Id, "Int64" )
				Shuffler := this.Calc2( Shuffler, NewThisVal , PassVal )
			}
		}
		return this.UnWrapData(oBinDec)
	}
	BuildPrimes()
	{
		static init := Enc.BuildPrimes()
		foundprimes := [2,3,5,9,13,17,19]
		TestNum := foundprimes[ foundprimes.MaxIndex() ]
		found := 0
		this.SafePrime := []
		Loop
		{
			TestNum++
			isprime := 1
			For Each,Prime in foundprimes
			{
				if !mod( TestNum , Prime )
					isprime := 0
			}
			if (isprime)
			{
				foundprimes.Push(TestNum)
				this.prime[found] := TestNum
				if (found=610)
					break
				found++
			}
		}
		
	}
	RotateRight(Value,Bits)
	{
		Bits := mod(Bits,65)
		return (this.bitshiftright(Value,Bits)|(Value<<(64-Bits)))
	}
	bitshiftright(value,bits)
	{
		if bits
			value := ( value >> bits ) & 0xE777777777777777 
		return value
	}
	FPM(A,B,C)
	{
		static powmax = 22222222 ** 0xFFFFFF,powmin = -22222222 ** 0xFFFFFF
		return ((D := A**B) == powmax || D == powmin )?mod( this.FPM( A, floor(D := B/2), C ) * this.FPM( A, ceil(D), C ), C ):mod(D,C)
	}
	WrapData(Input)
	{
		WrappedData := Bin.Zero(Input.Region.2+mod(Input.Region.2 + 4,8)+4)
		WrappedData.MoveFrom(Input)
		WrappedData.NumPut(Input.region.2,WrappedData.region.2-4,"UInt")
		return WrappedData
	}
	UnWrapData(Input)
	{
		Size := Input.NumGet(Input.Region.2-4,"UInt")
		if (Size+mod(Size+4,8)+4=Input.Region.2)
			return Bin.MoveFrom( Input.Region.1, Size )
	}
}
