unit TestUtils.RunStats;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils, Math, DUnitX.TestFramework, RunStats;

Type
  [TestFixture]
  TRunningStatisticsTests = class
  private
    Const
      Tolerance = 1E-12;
      // Mean 5, sum of squared deviations 32
      Sample: array[0..7] of Float64 = (2,4,4,4,5,5,7,9);
  public
    // Empty and single observation: undefined statistics are NaN
    [Test] Procedure TestEmpty;
    [Test] Procedure TestSingleObservation;
    // Mean and (standard) deviations of a known sample
    [Test] Procedure TestMean;
    [Test] Procedure TestVariance;
    [Test] Procedure TestStandardDeviation;
    [Test] Procedure TestPopulationStatistics;
    [Test] Procedure TestStandardError;
    // Intermediate results equal the statistics of the observations so far
    [Test] Procedure TestIntermediateResults;
    // Large offset: naive sum of squares would lose all precision
    [Test] Procedure TestNumericalStability;
    // Clear resets all statistics
    [Test] Procedure TestClear;
    // Merge equals adding all observations to a single instance
    [Test] Procedure TestMerge;
    [Test] Procedure TestMergeIntoEmpty;
    [Test] Procedure TestMergeEmpty;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TRunningStatisticsTests.TestEmpty;
begin
  var Stats := TRunningStatistics.Create;
  try
    Assert.AreEqual(Int64(0), Stats.Count);
    Assert.IsTrue(IsNaN(Stats.Mean));
    Assert.IsTrue(IsNaN(Stats.Variance));
    Assert.IsTrue(IsNaN(Stats.StandardDeviation));
    Assert.IsTrue(IsNaN(Stats.PopulationVariance));
    Assert.IsTrue(IsNaN(Stats.StandardError));
  finally
    Stats.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestSingleObservation;
begin
  var Stats := TRunningStatistics.Create;
  try
    Stats.Add(3.5);
    Assert.AreEqual(Int64(1), Stats.Count);
    Assert.AreEqual(3.5, Stats.Mean, Tolerance);
    Assert.AreEqual(0.0, Stats.PopulationVariance, Tolerance);
    Assert.IsTrue(IsNaN(Stats.Variance));
    Assert.IsTrue(IsNaN(Stats.StandardDeviation));
    Assert.IsTrue(IsNaN(Stats.StandardError));
  finally
    Stats.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestMean;
begin
  var Stats := TRunningStatistics.Create;
  try
    Stats.Add(Sample);
    Assert.AreEqual(Int64(8), Stats.Count);
    Assert.AreEqual(5.0, Stats.Mean, Tolerance);
  finally
    Stats.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestVariance;
begin
  var Stats := TRunningStatistics.Create;
  try
    Stats.Add(Sample);
    Assert.AreEqual(32/7, Stats.Variance, Tolerance);
  finally
    Stats.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestStandardDeviation;
begin
  var Stats := TRunningStatistics.Create;
  try
    Stats.Add(Sample);
    Assert.AreEqual(Sqrt(32/7), Stats.StandardDeviation, Tolerance);
  finally
    Stats.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestPopulationStatistics;
begin
  var Stats := TRunningStatistics.Create;
  try
    Stats.Add(Sample);
    Assert.AreEqual(4.0, Stats.PopulationVariance, Tolerance);
    Assert.AreEqual(2.0, Stats.PopulationStandardDeviation, Tolerance);
  finally
    Stats.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestStandardError;
begin
  var Stats := TRunningStatistics.Create;
  try
    Stats.Add(Sample);
    Assert.AreEqual(Sqrt(32/7/8), Stats.StandardError, Tolerance);
  finally
    Stats.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestIntermediateResults;
begin
  var Stats := TRunningStatistics.Create;
  try
    for var Obs := low(Sample) to high(Sample) do
    begin
      Stats.Add(Sample[Obs]);
      Assert.AreEqual(Math.Mean(Slice(Sample,Obs+1)), Stats.Mean, Tolerance);
      if Obs > 0 then
      Assert.AreEqual(Math.Variance(Slice(Sample,Obs+1)), Stats.Variance, Tolerance);
    end;
  finally
    Stats.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestNumericalStability;
begin
  var Stats := TRunningStatistics.Create;
  try
    for var Value in Sample do Stats.Add(1E9 + Value);
    Assert.AreEqual(1E9 + 5.0, Stats.Mean, 1E-6);
    Assert.AreEqual(32/7, Stats.Variance, 1E-6);
  finally
    Stats.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestClear;
begin
  var Stats := TRunningStatistics.Create;
  try
    Stats.Add(Sample);
    Stats.Clear;
    Assert.AreEqual(Int64(0), Stats.Count);
    Assert.IsTrue(IsNaN(Stats.Mean));
    Stats.Add([1.0,3.0]);
    Assert.AreEqual(2.0, Stats.Mean, Tolerance);
    Assert.AreEqual(2.0, Stats.Variance, Tolerance);
  finally
    Stats.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestMerge;
begin
  var Stats1 := TRunningStatistics.Create;
  var Stats2 := TRunningStatistics.Create;
  try
    Stats1.Add([2.0,4.0,4.0]);
    Stats2.Add([4.0,5.0,5.0,7.0,9.0]);
    Stats1.Merge(Stats2);
    Assert.AreEqual(Int64(8), Stats1.Count);
    Assert.AreEqual(5.0, Stats1.Mean, Tolerance);
    Assert.AreEqual(32/7, Stats1.Variance, Tolerance);
    // Merged statistics remain unchanged
    Assert.AreEqual(Int64(5), Stats2.Count);
  finally
    Stats1.Free;
    Stats2.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestMergeIntoEmpty;
begin
  var Stats1 := TRunningStatistics.Create;
  var Stats2 := TRunningStatistics.Create;
  try
    Stats2.Add(Sample);
    Stats1.Merge(Stats2);
    Assert.AreEqual(Int64(8), Stats1.Count);
    Assert.AreEqual(5.0, Stats1.Mean, Tolerance);
    Assert.AreEqual(32/7, Stats1.Variance, Tolerance);
  finally
    Stats1.Free;
    Stats2.Free;
  end;
end;

Procedure TRunningStatisticsTests.TestMergeEmpty;
begin
  var Stats1 := TRunningStatistics.Create;
  var Stats2 := TRunningStatistics.Create;
  try
    Stats1.Add(Sample);
    Stats1.Merge(Stats2);
    Assert.AreEqual(Int64(8), Stats1.Count);
    Assert.AreEqual(5.0, Stats1.Mean, Tolerance);
    Assert.AreEqual(32/7, Stats1.Variance, Tolerance);
  finally
    Stats1.Free;
    Stats2.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TRunningStatisticsTests);

end.
