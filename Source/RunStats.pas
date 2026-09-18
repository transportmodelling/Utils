unit RunStats;

////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak
// https://github.com/transportmodelling/Utils
//
// Running (on the fly) mean and standard deviation, using Welford's algorithm.
// The mean is updated with the method of successive averages; the sum of
// squared deviations from the mean is updated alongside it, which is
// numerically stable, contrary to the naive sum of squares approach.
//
// References:
// - B.P. Welford (1962), Note on a method for calculating corrected sums of
//   squares and products, Technometrics 4(3), 419-420.
// - T.F. Chan, G.H. Golub & R.J. LeVeque (1983), Algorithms for computing the
//   sample variance: analysis and recommendations, The American Statistician
//   37(3), 242-247 (used for merging statistics).
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  Math;

Type
  TRunningStatistics = Class
  private
    FCount: Int64;
    FMean: Float64;
    FSumSqrDev: Float64; // Sum of squared deviations from the mean
    Function GetMean: Float64;
    Function GetVariance: Float64;
    Function GetStandardDeviation: Float64;
    Function GetPopulationVariance: Float64;
    Function GetPopulationStandardDeviation: Float64;
    Function GetStandardError: Float64;
  public
    Procedure Clear;
    Procedure Add(const Value: Float64); overload;
    Procedure Add(const Values: array of Float64); overload;
    Procedure Merge(const Statistics: TRunningStatistics);
  public
    Property Count: Int64 read FCount;
    // Undefined statistics return NaN: the mean for Count < 1,
    // the population (standard) deviation for Count < 1,
    // the sample (standard) deviation and standard error for Count < 2
    Property Mean: Float64 read GetMean;
    Property Variance: Float64 read GetVariance;
    Property StandardDeviation: Float64 read GetStandardDeviation;
    Property PopulationVariance: Float64 read GetPopulationVariance;
    Property PopulationStandardDeviation: Float64 read GetPopulationStandardDeviation;
    Property StandardError: Float64 read GetStandardError;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Function TRunningStatistics.GetMean: Float64;
begin
  if FCount > 0 then Result := FMean else Result := NaN;
end;

Function TRunningStatistics.GetVariance: Float64;
begin
  if FCount > 1 then Result := FSumSqrDev/(FCount-1) else Result := NaN;
end;

Function TRunningStatistics.GetStandardDeviation: Float64;
begin
  Result := Sqrt(GetVariance);
end;

Function TRunningStatistics.GetPopulationVariance: Float64;
begin
  if FCount > 0 then Result := FSumSqrDev/FCount else Result := NaN;
end;

Function TRunningStatistics.GetPopulationStandardDeviation: Float64;
begin
  Result := Sqrt(GetPopulationVariance);
end;

Function TRunningStatistics.GetStandardError: Float64;
begin
  if FCount > 1 then Result := Sqrt(GetVariance/FCount) else Result := NaN;
end;

Procedure TRunningStatistics.Clear;
begin
  FCount := 0;
  FMean := 0.0;
  FSumSqrDev := 0.0;
end;

Procedure TRunningStatistics.Add(const Value: Float64);
begin
  Inc(FCount);
  var Delta := Value-FMean;
  FMean := FMean + Delta/FCount;
  FSumSqrDev := FSumSqrDev + Delta*(Value-FMean);
end;

Procedure TRunningStatistics.Add(const Values: array of Float64);
begin
  for var Value in Values do Add(Value);
end;

Procedure TRunningStatistics.Merge(const Statistics: TRunningStatistics);
// Combines the statistics of two independent sets of observations (Chan et al.)
begin
  if Statistics.FCount > 0 then
  if FCount = 0 then
  begin
    FCount := Statistics.FCount;
    FMean := Statistics.FMean;
    FSumSqrDev := Statistics.FSumSqrDev;
  end else
  begin
    var Count := FCount + Statistics.FCount;
    var Delta := Statistics.FMean-FMean;
    FMean := FMean + Delta*Statistics.FCount/Count;
    FSumSqrDev := FSumSqrDev + Statistics.FSumSqrDev + Delta*Delta*FCount*Statistics.FCount/Count;
    FCount := Count;
  end;
end;

end.
