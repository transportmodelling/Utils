unit TestUtils.RNG;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils, Math, Rtti, DUnitX.TestFramework, RNG;

Type
  [TestFixture]
  TMersenneTwisterTests = class
  public
    [Test] Procedure NextUInt32_DefaultSeed_MatchesReference;
    [Test] Procedure NextUInt32_Seed1_MatchesReference;
    [Test] Procedure Init_RestartsSequence;
    [Test] Procedure Next_EqualsScaledNextUInt32;
    [Test] Procedure Next_InUnitInterval;
  end;

  [TestFixture]
  TSplitMix64Tests = class
  public
    [Test] Procedure Next_Seed1234567_MatchesReference;
  end;

  [TestFixture]
  TXoshiro256Tests = class
  public
    [Test] Procedure NextUInt64_ReferenceState_MatchesReference;
    [Test] Procedure Init_RestartsSequence;
    [Test] Procedure Next_EqualsScaledUpper53Bits;
    [Test] Procedure Next_InUnitInterval;
  end;

  [TestFixture]
  TPCG64Tests = class
  public
    [Test] Procedure NextUInt64_Seed42Stream54_MatchesReference;
    [Test] Procedure Init_RestartsSequence;
    [Test] Procedure Create_DifferentStreams_DifferentSequences;
    [Test] Procedure Next_EqualsScaledUpper53Bits;
    [Test] Procedure Next_InUnitInterval;
  end;

  [TestFixture]
  TPhilox4x32Tests = class
  private
    Function Key(const k0,k1: UInt32): TPhiloxKey;
    Function Counter(const c0,c1,c2,c3: UInt32): TPhiloxCounter;
  public
    [Test] Procedure Block_KnownAnswers_MatchReference;
    [Test] Procedure Uniform_EqualsScaledUpper53Bits;
    [Test] Procedure Uniform_Extremes_InUnitInterval;
    [Test] Procedure Create_Seed_SplitsIntoKey;
    [Test] Procedure Next_EqualsUniformsOfSuccessiveBlocks;
    [Test] Procedure Next_CounterCarriesIntoNextWord;
    [Test] Procedure Init_RestartsSequence;
    [Test] Procedure KeyAndStart_RestartWalk;
    [Test] Procedure Create_DifferentKeys_DifferentSequences;
    [Test] Procedure Next_InUnitInterval;
  end;

  [TestFixture]
  TWeightedDrawTests = class
  private
    FGenerator: TRandomNumberGenerator;
    FDraw: TWeightedDraw;
  public
    [Setup]
    Procedure Setup;
    [TearDown]
    Procedure TearDown;

    // Create
    [Test] Procedure Create_NilGenerator_RaisesException;
    [Test] Procedure Generator_ReturnsGenerator;

    // Weights
    [Test] Procedure SetWeights_SetsWeightsAndCount;
    [Test] Procedure WeightCount_Set_ResetsWeights;
    [Test] Procedure WeightCount_Grown_AllWeightsZero;
    [Test] Procedure WeightCount_Negative_RaisesException;
    [Test] Procedure Weights_OutOfRange_RaisesException;
    [Test] Procedure Weights_Invalid_RaisesException;
    [Test] Procedure SetWeights_EmptyArray_LeavesNoOptions;
    [Test] Procedure SetWeights_InvalidWeight_LeavesNoOptions;

    // Draw
    [Test] Procedure Draw_SetWeights_FrequenciesProportionalToWeights;
    [Test] Procedure Draw_WeightsSetOneByOne_FrequenciesProportionalToWeights;
    [Test] Procedure Draw_WeightChanged_TakesEffectOnNextDraw;
    [Test] Procedure Draw_SinglePositiveWeight_AlwaysDrawn;
    [Test] Procedure Draw_NoOptions_ReturnsMinusOne;
    [Test] Procedure Draw_AllWeightsZero_ReturnsMinusOne;
    [Test] Procedure Draw_Unavailable_ConsumesNoRandomNumber;
    [Test] Procedure Draw_AvailableAgain_DrawsNormally;
    [Test] Procedure Draw_SharedGenerator_SeparateWeightsOneStream;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure CheckUnitInterval(const Generator: TRandomNumberGenerator);
// Verifies the range, and both the mean (1/2) and the variance (1/12) of a uniform
// distribution. The mean and variance are updated on the fly using Welford's algorithm,
// so that these tests do not depend on another unit under test.
begin
  const Draws = 100000;
  var Count := 0;
  var Mean := 0.0;
  var SumSqrDev := 0.0; // Sum of squared deviations from the mean
  for var Draw := 1 to Draws do
  begin
    var x: Float64 := Generator.Next;
    Assert.IsTrue((x >= 0) and (x < 1), 'Value outside [0,1): ' + FloatToStr(x));
    Inc(Count);
    var Delta := x-Mean;
    Mean := Mean + Delta/Count;
    SumSqrDev := SumSqrDev + Delta*(x-Mean);
  end;
  // Tolerances are 5 standard deviations of the sample mean and the sample variance
  Assert.AreEqual(1/2,Mean,5*Sqrt(1/(12*Draws)));
  Assert.AreEqual(1/12,SumSqrDev/(Count-1),5*Sqrt(1/(180*Draws)));
end;

Procedure CheckFrequencies(const WeightedDraw: TWeightedDraw; const Expected: array of Float64);
// Compare observed shares with expected shares, allowing 5 standard errors.
// With a fixed seed the outcome is deterministic.
begin
  const Draws = 200000;
  var Counts: TArray<Integer>;
  SetLength(Counts,Length(Expected));
  for var Draw := 1 to Draws do Inc(Counts[WeightedDraw.Draw]);
  for var Option := 0 to High(Expected) do
  if Expected[Option] = 0 then
    Assert.AreEqual(0,Counts[Option],'Zero weight option drawn')
  else
    Assert.AreEqual(Expected[Option],Counts[Option]/Draws,
                    5*Sqrt(Expected[Option]*(1-Expected[Option])/Draws));
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TMersenneTwisterTests.NextUInt32_DefaultSeed_MatchesReference;
begin
  // Reference values, also required of C++ std::mt19937
  var MT := TMersenneTwister.Create;
  try
    Assert.AreEqual<UInt32>(3499211612,MT.NextUInt32);
    var Value: UInt32 := 0;
    for var Draw := 2 to 10000 do Value := MT.NextUInt32;
    Assert.AreEqual<UInt32>(4123659995,Value);
  finally
    MT.Free;
  end;
end;

Procedure TMersenneTwisterTests.NextUInt32_Seed1_MatchesReference;
begin
  var MT := TMersenneTwister.Create(1);
  try
    Assert.AreEqual<UInt32>(1791095845,MT.NextUInt32);
  finally
    MT.Free;
  end;
end;

Procedure TMersenneTwisterTests.Init_RestartsSequence;
begin
  var MT := TMersenneTwister.Create;
  try
    for var Draw := 1 to 1000 do MT.NextUInt32;
    MT.Init;
    Assert.AreEqual<UInt32>(3499211612,MT.NextUInt32);
  finally
    MT.Free;
  end;
end;

Procedure TMersenneTwisterTests.Next_EqualsScaledNextUInt32;
begin
  var MT := TMersenneTwister.Create;
  try
    Assert.AreEqual(3499211612/4294967296,MT.Next,0.0);
  finally
    MT.Free;
  end;
end;

Procedure TMersenneTwisterTests.Next_InUnitInterval;
begin
  var MT := TMersenneTwister.Create;
  try
    CheckUnitInterval(MT);
  finally
    MT.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TSplitMix64Tests.Next_Seed1234567_MatchesReference;
Const
  Expected: array[0..4] of UInt64 = (6457827717110365317, 3203168211198807973,
    9817491932198370423, 4593380528125082431, 16408922859458223821);
begin
  var SplitMix := TSplitMix64.Create(1234567);
  for var Value in Expected do Assert.AreEqual<UInt64>(Value,SplitMix.Next);
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TXoshiro256Tests.NextUInt64_ReferenceState_MatchesReference;
Const
  ReferenceState: array[0..3] of UInt64 = (1, 2, 3, 4);
  Expected: array[0..9] of UInt64 = (11520, 0, 1509978240, 1215971899390074240,
    1216172134540287360, 607988272756665600, 16172922978634559625, 8476171486693032832,
    10595114339597558777, 2904607092377533576);
begin
  var Xoshiro := TXoshiro256.Create;
  try
    // The published reference values start from state (1,2,3,4), which can not be reached
    // through seeding. The private state is therefore set through its RTTI field offset.
    var Context := TRttiContext.Create;
    var Offset := Context.GetType(TXoshiro256).GetField('State').Offset;
    Move(ReferenceState,(PByte(Xoshiro)+Offset)^,SizeOf(ReferenceState));
    for var Value in Expected do Assert.AreEqual<UInt64>(Value,Xoshiro.NextUInt64);
  finally
    Xoshiro.Free;
  end;
end;

Procedure TXoshiro256Tests.Init_RestartsSequence;
begin
  var Xoshiro := TXoshiro256.Create(99);
  try
    var First := Xoshiro.NextUInt64;
    for var Draw := 1 to 1000 do Xoshiro.NextUInt64;
    Xoshiro.Init;
    Assert.AreEqual<UInt64>(First,Xoshiro.NextUInt64);
  finally
    Xoshiro.Free;
  end;
end;

Procedure TXoshiro256Tests.Next_EqualsScaledUpper53Bits;
begin
  var Xoshiro := TXoshiro256.Create;
  try
    var First := Xoshiro.NextUInt64;
    Xoshiro.Init;
    Assert.AreEqual((First shr 11)/9007199254740992,Xoshiro.Next,0.0);
  finally
    Xoshiro.Free;
  end;
end;

Procedure TXoshiro256Tests.Next_InUnitInterval;
begin
  var Xoshiro := TXoshiro256.Create;
  try
    CheckUnitInterval(Xoshiro);
  finally
    Xoshiro.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TPCG64Tests.NextUInt64_Seed42Stream54_MatchesReference;
Const
  // Reference values from the pcg-cpp demo program for pcg64 rng(42,54)
  Expected: array[0..5] of UInt64 = ($86B1DA1D72062B68, $1304AA46C9853D39,
    $A3670E9E0DD50358, $F9090E529A7DAE00, $C85B9FD837996F2C, $606121F8E3919196);
begin
  var PCG := TPCG64.Create(42,54);
  try
    for var Value in Expected do Assert.AreEqual<UInt64>(Value,PCG.NextUInt64);
  finally
    PCG.Free;
  end;
end;

Procedure TPCG64Tests.Init_RestartsSequence;
begin
  var PCG := TPCG64.Create(42,54);
  try
    for var Draw := 1 to 1000 do PCG.NextUInt64;
    PCG.Init;
    Assert.AreEqual<UInt64>($86B1DA1D72062B68,PCG.NextUInt64);
  finally
    PCG.Free;
  end;
end;

Procedure TPCG64Tests.Create_DifferentStreams_DifferentSequences;
begin
  var Stream1 := TPCG64.Create(42,1);
  var Stream2 := TPCG64.Create(42,2);
  try
    var Equal := 0;
    for var Draw := 1 to 100 do
    if Stream1.NextUInt64 = Stream2.NextUInt64 then Inc(Equal);
    Assert.AreEqual(0,Equal);
  finally
    Stream1.Free;
    Stream2.Free;
  end;
end;

Procedure TPCG64Tests.Next_EqualsScaledUpper53Bits;
begin
  var PCG := TPCG64.Create(42,54);
  try
    Assert.AreEqual((UInt64($86B1DA1D72062B68) shr 11)/9007199254740992,PCG.Next,0.0);
  finally
    PCG.Free;
  end;
end;

Procedure TPCG64Tests.Next_InUnitInterval;
begin
  var PCG := TPCG64.Create;
  try
    CheckUnitInterval(PCG);
  finally
    PCG.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

Function TPhilox4x32Tests.Key(const k0,k1: UInt32): TPhiloxKey;
begin
  Result[0] := k0;
  Result[1] := k1;
end;

Function TPhilox4x32Tests.Counter(const c0,c1,c2,c3: UInt32): TPhiloxCounter;
begin
  Result[0] := c0;
  Result[1] := c1;
  Result[2] := c2;
  Result[3] := c3;
end;

Procedure TPhilox4x32Tests.Block_KnownAnswers_MatchReference;
// Reference values from the kat_vectors file of Random123 (philox4x32, 10 rounds)
Const
  Counters: array[0..2,0..3] of UInt32 = (($00000000,$00000000,$00000000,$00000000),
                                          ($FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF),
                                          ($243F6A88,$85A308D3,$13198A2E,$03707344));
  Keys: array[0..2,0..1] of UInt32 = (($00000000,$00000000),
                                      ($FFFFFFFF,$FFFFFFFF),
                                      ($A4093822,$299F31D0));
  Expected: array[0..2,0..3] of UInt32 = (($6627E8D5,$E169C58D,$BC57AC4C,$9B00DBD8),
                                          ($408F276D,$41C83B0E,$A20BC7C6,$6D5451FD),
                                          ($D16CFE09,$94FDCCEB,$5001E420,$24126EA1));
begin
  for var Vector := 0 to 2 do
  begin
    var Block := TPhilox4x32.Block(Key(Keys[Vector,0],Keys[Vector,1]),
                                   Counter(Counters[Vector,0],Counters[Vector,1],
                                           Counters[Vector,2],Counters[Vector,3]));
    for var Word := 0 to 3 do
    Assert.AreEqual<UInt32>(Expected[Vector,Word],Block[Word],
                            'Vector ' + Vector.ToString + ', word ' + Word.ToString);
  end;
end;

Procedure TPhilox4x32Tests.Uniform_EqualsScaledUpper53Bits;
begin
  Assert.AreEqual((UInt64($E169C58D6627E8D5) shr 11)/9007199254740992,
                  TPhilox4x32.Uniform($6627E8D5,$E169C58D),0.0);
end;

Procedure TPhilox4x32Tests.Uniform_Extremes_InUnitInterval;
begin
  Assert.AreEqual(0.0,TPhilox4x32.Uniform(0,0),0.0);
  Assert.AreEqual((9007199254740992-1)/9007199254740992,TPhilox4x32.Uniform($FFFFFFFF,$FFFFFFFF),0.0);
end;

Procedure TPhilox4x32Tests.Create_Seed_SplitsIntoKey;
begin
  var Philox := TPhilox4x32.Create($0123456789ABCDEF);
  try
    Assert.AreEqual<UInt32>($89ABCDEF,Philox.Key[0]);
    Assert.AreEqual<UInt32>($01234567,Philox.Key[1]);
    for var Word := 0 to 3 do Assert.AreEqual<UInt32>(0,Philox.Start[Word]);
  finally
    Philox.Free;
  end;
end;

Procedure TPhilox4x32Tests.Next_EqualsUniformsOfSuccessiveBlocks;
begin
  var Philox := TPhilox4x32.Create(Key(1,2),Counter(7,0,0,0));
  try
    var First := TPhilox4x32.Block(Key(1,2),Counter(7,0,0,0));
    var Second := TPhilox4x32.Block(Key(1,2),Counter(8,0,0,0));
    Assert.AreEqual(TPhilox4x32.Uniform(First[0],First[1]),Philox.Next,0.0);
    Assert.AreEqual(TPhilox4x32.Uniform(First[2],First[3]),Philox.Next,0.0);
    Assert.AreEqual(TPhilox4x32.Uniform(Second[0],Second[1]),Philox.Next,0.0);
  finally
    Philox.Free;
  end;
end;

Procedure TPhilox4x32Tests.Next_CounterCarriesIntoNextWord;
begin
  var Philox := TPhilox4x32.Create(Key(1,2),Counter($FFFFFFFF,$FFFFFFFF,5,0));
  try
    Philox.Next;
    Philox.Next;
    var Carried := TPhilox4x32.Block(Key(1,2),Counter(0,0,6,0));
    Assert.AreEqual(TPhilox4x32.Uniform(Carried[0],Carried[1]),Philox.Next,0.0);
  finally
    Philox.Free;
  end;
end;

Procedure TPhilox4x32Tests.Init_RestartsSequence;
begin
  var Philox := TPhilox4x32.Create(99);
  try
    var First := Philox.Next;
    for var Draw := 1 to 1000 do Philox.Next;
    Philox.Init;
    Assert.AreEqual(First,Philox.Next,0.0);
  finally
    Philox.Free;
  end;
end;

Procedure TPhilox4x32Tests.KeyAndStart_RestartWalk;
begin
  var Philox := TPhilox4x32.Create(99);
  try
    for var Draw := 1 to 5 do Philox.Next;
    Philox.Start := Counter(3,4,5,6);
    var Started := TPhilox4x32.Block(Key(99,0),Counter(3,4,5,6));
    Assert.AreEqual(TPhilox4x32.Uniform(Started[0],Started[1]),Philox.Next,0.0,'Start');
    Philox.Key := Key(9,9);
    var Keyed := TPhilox4x32.Block(Key(9,9),Counter(3,4,5,6));
    Assert.AreEqual(TPhilox4x32.Uniform(Keyed[0],Keyed[1]),Philox.Next,0.0,'Key');
  finally
    Philox.Free;
  end;
end;

Procedure TPhilox4x32Tests.Create_DifferentKeys_DifferentSequences;
begin
  var Key1 := TPhilox4x32.Create(Key(42,1),Counter(0,0,0,0));
  var Key2 := TPhilox4x32.Create(Key(42,2),Counter(0,0,0,0));
  try
    var Equal := 0;
    for var Draw := 1 to 100 do
    if Key1.Next = Key2.Next then Inc(Equal);
    Assert.AreEqual(0,Equal);
  finally
    Key1.Free;
    Key2.Free;
  end;
end;

Procedure TPhilox4x32Tests.Next_InUnitInterval;
begin
  var Philox := TPhilox4x32.Create;
  try
    CheckUnitInterval(Philox);
  finally
    Philox.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TWeightedDrawTests.Setup;
begin
  FGenerator := TXoshiro256.Create(1);
  FDraw := TWeightedDraw.Create(FGenerator);
end;

Procedure TWeightedDrawTests.TearDown;
begin
  FDraw.Free;
  FGenerator.Free;
end;

Procedure TWeightedDrawTests.Create_NilGenerator_RaisesException;
begin
  Assert.WillRaiseAny(Procedure begin TWeightedDraw.Create(nil).Free end);
end;

Procedure TWeightedDrawTests.Generator_ReturnsGenerator;
begin
  Assert.AreSame(FGenerator,FDraw.Generator);
end;

Procedure TWeightedDrawTests.SetWeights_SetsWeightsAndCount;
begin
  FDraw.SetWeights([1, 0, 3]);
  Assert.AreEqual(3,FDraw.WeightCount);
  Assert.AreEqual(1.0,FDraw.Weights[0],0.0);
  Assert.AreEqual(0.0,FDraw.Weights[1],0.0);
  Assert.AreEqual(3.0,FDraw.Weights[2],0.0);
end;

Procedure TWeightedDrawTests.WeightCount_Set_ResetsWeights;
begin
  FDraw.SetWeights([1, 2, 3]);
  FDraw.WeightCount := 3;
  for var Option := 0 to 2 do Assert.AreEqual(0.0,FDraw.Weights[Option],0.0);
end;

Procedure TWeightedDrawTests.WeightCount_Grown_AllWeightsZero;
begin
  FDraw.SetWeights([1, 2]);
  FDraw.WeightCount := 5;
  Assert.AreEqual(5,FDraw.WeightCount);
  for var Option := 0 to 4 do Assert.AreEqual(0.0,FDraw.Weights[Option],0.0);
end;

Procedure TWeightedDrawTests.WeightCount_Negative_RaisesException;
begin
  Assert.WillRaiseAny(Procedure begin FDraw.WeightCount := -1 end);
end;

Procedure TWeightedDrawTests.Weights_OutOfRange_RaisesException;
begin
  FDraw.WeightCount := 2;
  Assert.WillRaiseAny(Procedure begin FDraw.Weights[2] := 1 end);
  Assert.WillRaiseAny(Procedure begin FDraw.Weights[-1] := 1 end);
  Assert.WillRaiseAny(Procedure begin if FDraw.Weights[2] = 0 then end);
end;

Procedure TWeightedDrawTests.Weights_Invalid_RaisesException;
begin
  FDraw.WeightCount := 2;
  Assert.WillRaiseAny(Procedure begin FDraw.Weights[0] := -1 end);
  Assert.WillRaiseAny(Procedure begin FDraw.Weights[0] := NaN end);
  Assert.WillRaiseAny(Procedure begin FDraw.SetWeights([1, -1]) end);
  Assert.WillRaiseAny(Procedure begin FDraw.SetWeights([1, NaN]) end);
end;

Procedure TWeightedDrawTests.SetWeights_EmptyArray_LeavesNoOptions;
begin
  FDraw.SetWeights([1, 1, 1, 1]);
  FDraw.Draw;
  FDraw.SetWeights([]);
  Assert.AreEqual(0,FDraw.WeightCount);
  Assert.AreEqual(-1,FDraw.Draw);
end;

Procedure TWeightedDrawTests.SetWeights_InvalidWeight_LeavesNoOptions;
begin
  FDraw.SetWeights([1, 1]);
  FDraw.Draw;
  Assert.WillRaiseAny(Procedure begin FDraw.SetWeights([1, -1]) end);
  Assert.AreEqual(0,FDraw.WeightCount);
  Assert.AreEqual(-1,FDraw.Draw);
end;

Procedure TWeightedDrawTests.Draw_SetWeights_FrequenciesProportionalToWeights;
begin
  FDraw.SetWeights([1, 0, 3, 6]);
  CheckFrequencies(FDraw,[0.1, 0, 0.3, 0.6]);
end;

Procedure TWeightedDrawTests.Draw_WeightsSetOneByOne_FrequenciesProportionalToWeights;
begin
  // Arbitrary order, with gaps and a trailing zero weight
  FDraw.WeightCount := 6;
  FDraw.Weights[4] := 2;
  FDraw.Weights[0] := 1;
  FDraw.Weights[2] := 1;
  CheckFrequencies(FDraw,[0.25, 0, 0.25, 0, 0.5, 0]);
end;

Procedure TWeightedDrawTests.Draw_WeightChanged_TakesEffectOnNextDraw;
begin
  FDraw.SetWeights([1, 0, 1, 0, 2, 0]);
  FDraw.Draw;
  FDraw.Weights[3] := 4;
  CheckFrequencies(FDraw,[0.125, 0, 0.125, 0.5, 0.25, 0]);
end;

Procedure TWeightedDrawTests.Draw_SinglePositiveWeight_AlwaysDrawn;
begin
  FDraw.SetWeights([0, 0, 5]);
  for var Draw := 1 to 1000 do Assert.AreEqual(2,FDraw.Draw);
end;

Procedure TWeightedDrawTests.Draw_NoOptions_ReturnsMinusOne;
begin
  Assert.AreEqual(-1,FDraw.Draw);
  FDraw.SetWeights([1]);
  FDraw.WeightCount := 0;
  Assert.AreEqual(-1,FDraw.Draw);
end;

Procedure TWeightedDrawTests.Draw_AllWeightsZero_ReturnsMinusOne;
begin
  FDraw.SetWeights([0, 0, 0]);
  Assert.AreEqual(-1,FDraw.Draw);
end;

Procedure TWeightedDrawTests.Draw_Unavailable_ConsumesNoRandomNumber;
begin
  var Reference := TXoshiro256.Create(1);
  try
    FDraw.SetWeights([0, 0]);
    FDraw.Draw;
    Assert.AreEqual<UInt64>(Reference.NextUInt64,TXoshiro256(FGenerator).NextUInt64);
  finally
    Reference.Free;
  end;
end;

Procedure TWeightedDrawTests.Draw_AvailableAgain_DrawsNormally;
begin
  FDraw.SetWeights([0, 0]);
  Assert.AreEqual(-1,FDraw.Draw);
  FDraw.Weights[1] := 1;
  Assert.AreEqual(1,FDraw.Draw);
end;

Procedure TWeightedDrawTests.Draw_SharedGenerator_SeparateWeightsOneStream;
begin
  var Reference := TXoshiro256.Create(1);
  var Destinations := TWeightedDraw.Create(FGenerator);
  try
    FDraw.SetWeights([1, 1]);
    Destinations.SetWeights([0, 0, 1]);
    for var Draw := 1 to 1000 do
    begin
      // Two equal weights: option 0 if the random number is below 0.5
      Assert.AreEqual(IfThen(Reference.Next < 0.5, 0, 1),FDraw.Draw);
      // The destination draw consumes the next random number from the same stream
      Assert.AreEqual(2,Destinations.Draw);
      Reference.Next;
    end;
  finally
    Destinations.Free;
    Reference.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMersenneTwisterTests);
  TDUnitX.RegisterTestFixture(TSplitMix64Tests);
  TDUnitX.RegisterTestFixture(TXoshiro256Tests);
  TDUnitX.RegisterTestFixture(TPCG64Tests);
  TDUnitX.RegisterTestFixture(TPhilox4x32Tests);
  TDUnitX.RegisterTestFixture(TWeightedDrawTests);

end.
