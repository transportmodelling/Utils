unit RNG;

////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Type
  TRandomNumberGenerator = Class
  public
    Constructor Create;
    Procedure Init; virtual; abstract;
    // Uniform random number in [0,1)
    Function Next: Float64; virtual; abstract;
  end;

  TWeightedDraw = Class
  // Draws an option with a probability proportional to its weight.
  // Weights need not sum to 1, zero weight options are never drawn.
  // The generator is not owned, so it can be shared by multiple weighted draws.
  private
    FGenerator: TRandomNumberGenerator;
    FWeightCount: Integer;
    FWeights: TArray<Float64>;
    Cumulative: TArray<Float64>;
    UpdateCumulative: Boolean;
    LastPositive: Integer;
    Procedure SetWeightCount(Count: Integer);
    Function GetWeight(Option: Integer): Float64;
    Procedure SetWeight(Option: Integer; Weight: Float64);
    Procedure Accumulate;
  public
    Constructor Create(const Generator: TRandomNumberGenerator);
    Procedure SetWeights(const Weights: array of Float64);
    // Returns -1 if no option has a positive weight
    Function Draw: Integer;
  public
    Property Generator: TRandomNumberGenerator read FGenerator;
    // Setting the weight count resets all weights to zero
    Property WeightCount: Integer read FWeightCount write SetWeightCount;
    Property Weights[Option: Integer]: Float64 read GetWeight write SetWeight;
  end;

  TMersenneTwister = Class(TRandomNumberGenerator)
  // 32-bit Mersenne Twister (MT19937)
  // Based on: http://www.math.sci.hiroshima-u.ac.jp/m-mat/MT/MT2002/emt19937ar.html
  private
    Const
      N = 624;
      M = 397;
      MatrixA = $9908B0DF;
      UpperMask = $80000000;
      LowerMask = $7FFFFFFF;
      DefaultSeed = 5489;
      Scale32 = 1/4294967296; // 2^-32
    Var
      FSeed: UInt32;
      Index: Integer;
      State: array[0..N-1] of UInt32;
    Procedure Twist;
  public
    Constructor Create; overload;
    Constructor Create(const Seed: UInt32); overload;
    Procedure Init; override;
    Function Next: Float64; override;
    Function NextUInt32: UInt32;
  public
    Property Seed: UInt32 read FSeed;
  end;

  TSplitMix64 = record
  // SplitMix64, used to expand a 64-bit seed into the state of other generators
  // Based on: https://prng.di.unimi.it/splitmix64.c
  private
    State: UInt64;
  public
    Constructor Create(const Seed: UInt64);
    Function Next: UInt64;
  end;

  TXoshiro256 = Class(TRandomNumberGenerator)
  // xoshiro256** (Blackman & Vigna), seeded through SplitMix64
  // Based on: https://prng.di.unimi.it/xoshiro256starstar.c
  strict private
    Class Function RotL(const x: UInt64; const k: Integer): UInt64; static; inline;
  private
    Const
      DefaultSeed = 0;
      Scale53 = 1/9007199254740992; // 2^-53
    Var
      FSeed: UInt64;
      State: array[0..3] of UInt64;
  public
    Constructor Create; overload;
    Constructor Create(const Seed: UInt64); overload;
    Procedure Init; override;
    Function Next: Float64; override;
    Function NextUInt64: UInt64;
  public
    Property Seed: UInt64 read FSeed;
  end;

  TPCG64 = Class(TRandomNumberGenerator)
  // PCG XSL RR 128/64 (O'Neill), the generator NumPy's PCG64 is based on
  // Different streams yield independent sequences for the same seed
  // Based on: https://www.pcg-random.org
  strict private
    Class Function RotR(const x: UInt64; const k: Integer): UInt64; static; inline;
    Class Procedure Multiply(const a,b: UInt64; out Hi,Lo: UInt64); static; inline;
  private
    Const
      DefaultSeed = 0;
      Scale53 = 1/9007199254740992; // 2^-53
      MultiplierHi = UInt64($2360ED051FC65DA4);
      MultiplierLo = UInt64($4385DF649FCCF645);
      DefaultIncrementHi = UInt64($5851F42D4C957F2D);
      DefaultIncrementLo = UInt64($14057B7EF767814F);
    Var
      FSeed: UInt64;
      StateHi,StateLo: UInt64;
      IncrementHi,IncrementLo: UInt64;
    Procedure Step;
  public
    Constructor Create; overload;
    Constructor Create(const Seed: UInt64); overload;
    Constructor Create(const Seed,Stream: UInt64); overload;
    Procedure Init; override;
    Function Next: Float64; override;
    Function NextUInt64: UInt64;
  public
    Property Seed: UInt64 read FSeed;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils;

// The 64-bit generators rely on wrap-around integer arithmetic
{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

Constructor TRandomNumberGenerator.Create;
begin
  inherited Create;
  Init;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TWeightedDraw.Create(const Generator: TRandomNumberGenerator);
begin
  inherited Create;
  if Generator <> nil then
  begin 
    FGenerator := Generator;
    UpdateCumulative := true;
  end else
    raise Exception.Create('Generator not assigned');
end;

Procedure TWeightedDraw.SetWeightCount(Count: Integer);
begin
  if Count >= 0 then 
  begin
    // Capacity is retained for reuse
    if Length(FWeights) < Count then SetLength(FWeights,Count);
    for var Option := 0 to Count-1 do FWeights[Option] := 0.0;
    FWeightCount := Count;
    UpdateCumulative := true;
  end else
    raise Exception.Create('Invalid weight count');
end;

Function TWeightedDraw.GetWeight(Option: Integer): Float64;
begin
  if (Option >= 0) and (Option < FWeightCount) then 
    Result := FWeights[Option]
  else
    raise Exception.Create('Invalid option');
end;

Procedure TWeightedDraw.SetWeight(Option: Integer; Weight: Float64);
begin
  if (Option >= 0) and (Option < FWeightCount) then 
    if Weight >= 0.0 then 
    begin
      FWeights[Option] := Weight;
      UpdateCumulative := true;
    end else
      raise Exception.Create('Invalid weight')
  else
    raise Exception.Create('Invalid option');
end;

Procedure TWeightedDraw.SetWeights(const Weights: array of Float64);
begin
  // Reset first, so that no options remain when an invalid weight is rejected
  FWeightCount := 0;
  UpdateCumulative := true;
  if Length(FWeights) < Length(Weights) then SetLength(FWeights,Length(Weights));
  for var Option := 0 to High(Weights) do
  if Weights[Option] >= 0.0 then
    FWeights[Option] := Weights[Option]
  else
    raise Exception.Create('Invalid weight');
  FWeightCount := Length(Weights);
end;

Procedure TWeightedDraw.Accumulate;
begin
  var Total := 0.0;
  if Length(Cumulative) < FWeightCount then SetLength(Cumulative,Length(FWeights));
  LastPositive := -1;
  for var Option := 0 to FWeightCount-1 do
  begin
    Total := Total + FWeights[Option];
    Cumulative[Option] := Total;
    if FWeights[Option] > 0.0 then LastPositive := Option;
  end;
  UpdateCumulative := false;
end;

Function TWeightedDraw.Draw: Integer;
begin
  if UpdateCumulative then Accumulate;
  // No option available
  if LastPositive < 0 then Exit(-1);
  var Value := FGenerator.Next*Cumulative[LastPositive];
  // Binary search for the first option with Value < Cumulative weight.
  // Zero weight options can not be found this way, and if rounding yields Value = Total,
  // the search ends at the last option with a positive weight.
  Result := 0;
  var Upper := LastPositive;
  while Result < Upper do
  begin
    var Mid := (Result+Upper) shr 1;
    if Value < Cumulative[Mid] then Upper := Mid else Result := Mid+1;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TMersenneTwister.Create;
begin
  Create(DefaultSeed);
end;

Constructor TMersenneTwister.Create(const Seed: UInt32);
begin
  FSeed := Seed;
  inherited Create;
end;

Procedure TMersenneTwister.Init;
begin
  State[0] := FSeed;
  for var i := 1 to N-1 do
    State[i] := (UInt64(1812433253)*(State[i-1] xor (State[i-1] shr 30)) + UInt64(i)) and $FFFFFFFF;
  Index := N;
end;

Procedure TMersenneTwister.Twist;
begin
  for var i := 0 to N-1 do
  begin
    var y: UInt32 := (State[i] and UpperMask) or (State[(i+1) mod N] and LowerMask);
    State[i] := State[(i+M) mod N] xor (y shr 1);
    if Odd(y) then State[i] := State[i] xor MatrixA;
  end;
  Index := 0;
end;

Function TMersenneTwister.Next: Float64;
begin
  Result := NextUInt32*Scale32;
end;

Function TMersenneTwister.NextUInt32: UInt32;
begin
  if Index >= N then Twist;
  var y := State[Index];
  Inc(Index);
  // Tempering
  y := y xor (y shr 11);
  y := y xor ((y shl 7) and $9D2C5680);
  y := y xor ((y shl 15) and $EFC60000);
  y := y xor (y shr 18);
  Result := y;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TSplitMix64.Create(const Seed: UInt64);
begin
  State := Seed;
end;

Function TSplitMix64.Next: UInt64;
begin
  State := State + UInt64($9E3779B97F4A7C15);
  Result := State;
  Result := (Result xor (Result shr 30)) * UInt64($BF58476D1CE4E5B9);
  Result := (Result xor (Result shr 27)) * UInt64($94D049BB133111EB);
  Result := Result xor (Result shr 31);
end;

////////////////////////////////////////////////////////////////////////////////

Class Function TXoshiro256.RotL(const x: UInt64; const k: Integer): UInt64;
begin
  Result := (x shl k) or (x shr ((-k) and 63));
end;

Constructor TXoshiro256.Create;
begin
  Create(DefaultSeed);
end;

Constructor TXoshiro256.Create(const Seed: UInt64);
begin
  FSeed := Seed;
  inherited Create;
end;

Procedure TXoshiro256.Init;
begin
  var SplitMix := TSplitMix64.Create(FSeed);
  for var i := 0 to 3 do State[i] := SplitMix.Next;
end;

Function TXoshiro256.NextUInt64: UInt64;
begin
  Result := RotL(State[1]*5,7)*9;
  var t := State[1] shl 17;
  State[2] := State[2] xor State[0];
  State[3] := State[3] xor State[1];
  State[1] := State[1] xor State[2];
  State[0] := State[0] xor State[3];
  State[2] := State[2] xor t;
  State[3] := RotL(State[3],45);
end;

Function TXoshiro256.Next: Float64;
begin
  // Upper 53 bits, the precision of a Float64
  Result := Int64(NextUInt64 shr 11)*Scale53;
end;

////////////////////////////////////////////////////////////////////////////////

Class Function TPCG64.RotR(const x: UInt64; const k: Integer): UInt64;
begin
  Result := (x shr k) or (x shl ((-k) and 63));
end;

Class Procedure TPCG64.Multiply(const a,b: UInt64; out Hi,Lo: UInt64);
// Full 128-bit product of two 64-bit values
begin
  var aLo := a and $FFFFFFFF;
  var aHi := a shr 32;
  var bLo := b and $FFFFFFFF;
  var bHi := b shr 32;
  var p0 := aLo*bLo;
  var p1 := aLo*bHi;
  var p2 := aHi*bLo;
  var Mid := (p0 shr 32) + (p1 and $FFFFFFFF) + (p2 and $FFFFFFFF);
  Hi := aHi*bHi + (p1 shr 32) + (p2 shr 32) + (Mid shr 32);
  Lo := (Mid shl 32) or (p0 and $FFFFFFFF);
end;

Constructor TPCG64.Create;
begin
  Create(DefaultSeed);
end;

Constructor TPCG64.Create(const Seed: UInt64);
begin
  FSeed := Seed;
  IncrementHi := DefaultIncrementHi;
  IncrementLo := DefaultIncrementLo;
  inherited Create;
end;

Constructor TPCG64.Create(const Seed,Stream: UInt64);
begin
  FSeed := Seed;
  // Increment must be odd
  IncrementHi := Stream shr 63;
  IncrementLo := (Stream shl 1) or 1;
  inherited Create;
end;

Procedure TPCG64.Step;
// State := State*Multiplier + Increment (mod 2^128)
var
  Hi,Lo: UInt64;
begin
  Multiply(StateLo,MultiplierLo,Hi,Lo);
  Hi := Hi + StateHi*MultiplierLo + StateLo*MultiplierHi;
  StateLo := Lo + IncrementLo;
  if StateLo < Lo then Inc(Hi);
  StateHi := Hi + IncrementHi;
end;

Procedure TPCG64.Init;
begin
  StateHi := 0;
  StateLo := 0;
  Step;
  // Add seed
  var Lo := StateLo;
  StateLo := StateLo + FSeed;
  if StateLo < Lo then Inc(StateHi);
  Step;
end;

Function TPCG64.NextUInt64: UInt64;
begin
  Step;
  Result := RotR(StateHi xor StateLo,StateHi shr 58);
end;

Function TPCG64.Next: Float64;
begin
  // Upper 53 bits, the precision of a Float64
  Result := Int64(NextUInt64 shr 11)*Scale53;
end;

end.
