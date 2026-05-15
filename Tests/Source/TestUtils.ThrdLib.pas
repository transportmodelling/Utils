unit TestUtils.ThrdLib;

////////////////////////////////////////////////////////////////////////////////
//
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

uses
  SysUtils,
  Classes,
  DUnitX.TestFramework,
  SyncObjs,
  ThrdLib;

type
  // ---------------------------------------------------------------------------
  // Helper thread classes used across all test fixtures
  // ---------------------------------------------------------------------------

  // Completes immediately without doing anything.
  TSimpleThread = class(TGuardedThread)
  strict protected
    procedure ExecuteThread; override;
  end;

  // Atomically increments a shared counter on each execution.
  TCountingThread = class(TGuardedThread)
  private
    FCounter: PInteger;
  strict protected
    procedure ExecuteThread; override;
  public
    constructor Create(ACounter: PInteger);
  end;

  // Raises an Exception with a configurable message.
  TRaisingThread = class(TGuardedThread)
  private
    FMessage: string;
  strict protected
    procedure ExecuteThread; override;
  public
    constructor Create(const AMessage: string);
  end;

  // Blocks on an external TEvent before completing; gives tests deterministic
  // control over when the thread finishes.
  TEventThread = class(TGuardedThread)
  private
    FEvent: TEvent;
  strict protected
    procedure ExecuteThread; override;
  public
    constructor Create(AEvent: TEvent);
  end;

  // Loops until Terminated is set; used to test TBlockingThreadsGuard.Terminate.
  TTerminationAwareThread = class(TGuardedThread)
  strict protected
    procedure ExecuteThread; override;
  end;

  // ---------------------------------------------------------------------------
  // TThreadsGuardTests
  // ---------------------------------------------------------------------------

  [TestFixture]
  TThreadsGuardTests = class
  private
    FGuard: TThreadsGuard<TGuardedThread>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test] procedure StartThreads_EmptyArray_ReturnsFalse;
    [Test] procedure StartThreads_SingleThread_ReturnsTrue;
    [Test] procedure StartThreads_MultipleThreads_AllRun;
    [Test] procedure WaitFor_InitiallyIdle_ReturnsSignaled;
    [Test] procedure WaitFor_AfterThreadsComplete_ReturnsSignaled;
    [Test] procedure WaitFor_WhileRunning_WithTimeout_ReturnsTimeout;
    [Test] procedure Error_NoError_ReturnsFalse;
    [Test] procedure Error_AfterThreadRaises_ReturnsMessage;
    [Test] procedure Error_WithReset_ClearsError;
    [Test] procedure Error_OnlyFirstErrorPreserved;
    [Test] procedure StartThreads_WhileRunning_NonBlocking_StartsMore;
    [Test] procedure StartThreads_AlreadyStartedThread_Raises;
  end;

  // ---------------------------------------------------------------------------
  // TBlockingThreadsGuardTerminateTests
  // (Kept in a separate fixture to avoid a DUnitX per-fixture RTTI-scan issue
  //  that causes a hang when TThreadsGuardTests contains two Terminate_* methods.)
  // ---------------------------------------------------------------------------

  [TestFixture]
  TBlockingThreadsGuardTerminateTests = class
  private
    FGuard: TBlockingThreadsGuard<TGuardedThread>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test] procedure Guard_TerminatesWithNoThreads;
    [Test] procedure Guard_TerminatesRunning;
    [Test] procedure Guard_ReusableAfterTerminate;
  end;

  // ---------------------------------------------------------------------------
  // TBlockingThreadsGuardTests
  // ---------------------------------------------------------------------------

  [TestFixture]
  TBlockingThreadsGuardTests = class
  private
    FGuard: TBlockingThreadsGuard<TGuardedThread>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test] procedure StartThreads_WhileRunning_ReturnsFalse;
    [Test] procedure StartThreads_AfterAllComplete_ReturnsTrue;
  end;

  // ---------------------------------------------------------------------------
  // TGlobalThreadsGuardTests
  // ---------------------------------------------------------------------------

  [TestFixture]
  TGlobalThreadsGuardTests = class
  public
    [Test] procedure GlobalGuard_IsNotNil;
    [Test] procedure GlobalGuard_InitiallyIdle;
  end;

  // ---------------------------------------------------------------------------
  // TParallelForTests
  // ---------------------------------------------------------------------------

  [TestFixture]
  TParallelForTests = class
  private
    FParallelFor: TParallelFor;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test] procedure MaxThreads_ReturnsCreatedCount;
    [Test] procedure Execute_AllIterationsRun;
    [Test] procedure Execute_ThreadIndexInRange;
    [Test] procedure Execute_PerThreadAccumulation;
    [Test] procedure Execute_EmptyRange_NothingRuns;
    [Test] procedure Execute_Stride;
    [Test] procedure Execute_Reusable;
    [Test] procedure Execute_NThreadsOne_UsesSingleThread;
    [Test] procedure Execute_ExceptionPropagates;
    [Test] procedure Execute_Exception_SingleThreadedPath;
    [Test] procedure Execute_Exception_OnlyFirstPropagates;
    [Test] procedure Execute_SingleThreaded_AllIterationsRun;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

// ---------------------------------------------------------------------------
// TSimpleThread
// ---------------------------------------------------------------------------

procedure TSimpleThread.ExecuteThread;
begin
  // Completes immediately; no work done.
end;

// ---------------------------------------------------------------------------
// TCountingThread
// ---------------------------------------------------------------------------

constructor TCountingThread.Create(ACounter: PInteger);
begin
  inherited Create;
  FCounter := ACounter;
end;

procedure TCountingThread.ExecuteThread;
begin
  TInterlocked.Increment(FCounter^);
end;

// ---------------------------------------------------------------------------
// TRaisingThread
// ---------------------------------------------------------------------------

constructor TRaisingThread.Create(const AMessage: string);
begin
  inherited Create;
  FMessage := AMessage;
end;

procedure TRaisingThread.ExecuteThread;
begin
  raise Exception.Create(FMessage);
end;

// ---------------------------------------------------------------------------
// TEventThread
// ---------------------------------------------------------------------------

constructor TEventThread.Create(AEvent: TEvent);
begin
  inherited Create;
  FEvent := AEvent;
end;

procedure TEventThread.ExecuteThread;
begin
  FEvent.WaitFor(Infinite);
end;

// ---------------------------------------------------------------------------
// TTerminationAwareThread
// ---------------------------------------------------------------------------

procedure TTerminationAwareThread.ExecuteThread;
begin
  while not Terminated do
    Sleep(10);
end;

// ---------------------------------------------------------------------------
// TThreadsGuardTests
// ---------------------------------------------------------------------------

procedure TThreadsGuardTests.Setup;
begin
  FGuard := TThreadsGuard<TGuardedThread>.Create;
end;

procedure TThreadsGuardTests.TearDown;
begin
  FGuard.Free;
end;

procedure TThreadsGuardTests.StartThreads_EmptyArray_ReturnsFalse;
begin
  Assert.IsFalse(FGuard.StartThreads([]));
end;

procedure TThreadsGuardTests.StartThreads_SingleThread_ReturnsTrue;
begin
  Assert.IsTrue(FGuard.StartThreads([TSimpleThread.Create]));
  FGuard.WaitFor;
end;

procedure TThreadsGuardTests.StartThreads_MultipleThreads_AllRun;
var
  LCount: Integer;
begin
  LCount := 0;
  FGuard.StartThreads([
    TCountingThread.Create(@LCount),
    TCountingThread.Create(@LCount),
    TCountingThread.Create(@LCount)
  ]);
  FGuard.WaitFor;
  Assert.AreEqual(3, LCount);
end;

procedure TThreadsGuardTests.WaitFor_InitiallyIdle_ReturnsSignaled;
begin
  Assert.IsTrue(FGuard.WaitFor(0) = wrSignaled,
    'Fresh guard should be idle; WaitFor(0) should return wrSignaled');
end;

procedure TThreadsGuardTests.WaitFor_AfterThreadsComplete_ReturnsSignaled;
begin
  FGuard.StartThreads([TSimpleThread.Create]);
  Assert.IsTrue(FGuard.WaitFor(5000) = wrSignaled,
    'Guard should become idle once all threads complete');
end;

procedure TThreadsGuardTests.WaitFor_WhileRunning_WithTimeout_ReturnsTimeout;
var
  LEvent: TEvent;
begin
  LEvent := TEvent.Create(nil, False, False, '');
  try
    FGuard.StartThreads([TEventThread.Create(LEvent)]);
    Assert.IsTrue(FGuard.WaitFor(50) = wrTimeout,
      'Guard should not be idle while a thread is still running');
  finally
    LEvent.SetEvent;
    FGuard.WaitFor;
    LEvent.Free;
  end;
end;

procedure TThreadsGuardTests.Error_NoError_ReturnsFalse;
var
  LMsg: string;
begin
  Assert.IsFalse(FGuard.Error(LMsg));
  Assert.AreEqual('', LMsg);
end;

procedure TThreadsGuardTests.Error_AfterThreadRaises_ReturnsMessage;
var
  LMsg: string;
begin
  FGuard.StartThreads([TRaisingThread.Create('test error')]);
  FGuard.WaitFor;
  Assert.IsTrue(FGuard.Error(LMsg));
  Assert.AreEqual('test error', LMsg);
end;

procedure TThreadsGuardTests.Error_WithReset_ClearsError;
var
  LMsg: string;
begin
  FGuard.StartThreads([TRaisingThread.Create('test error')]);
  FGuard.WaitFor;
  FGuard.Error(LMsg, True);
  Assert.IsFalse(FGuard.Error(LMsg), 'Error should return false after Reset');
end;

procedure TThreadsGuardTests.Error_OnlyFirstErrorPreserved;
var
  LMsg1, LMsg2: string;
begin
  FGuard.StartThreads([
    TRaisingThread.Create('error A'),
    TRaisingThread.Create('error B')
  ]);
  FGuard.WaitFor;
  Assert.IsTrue(FGuard.Error(LMsg1), 'At least one error should be recorded');
  Assert.IsTrue(FGuard.Error(LMsg2), 'Error should persist between calls');
  Assert.AreEqual(LMsg1, LMsg2, 'Error message should not change between reads');
  Assert.IsTrue((LMsg1 = 'error A') or (LMsg1 = 'error B'),
    'Recorded error must match one of the raised messages');
end;

procedure TThreadsGuardTests.StartThreads_WhileRunning_NonBlocking_StartsMore;
var
  LEvent: TEvent;
  LCount: Integer;
  LResult: Boolean;
begin
  LCount := 0;
  LEvent := TEvent.Create(nil, False, False, '');
  try
    FGuard.StartThreads([TEventThread.Create(LEvent)]);
    LResult := FGuard.StartThreads([TCountingThread.Create(@LCount)]);
    LEvent.SetEvent;
    FGuard.WaitFor;
    Assert.IsTrue(LResult, 'Non-blocking guard should start threads while others are running');
    Assert.AreEqual(1, LCount, 'The second batch thread should have run');
  finally
    LEvent.SetEvent;
    FGuard.WaitFor;
    LEvent.Free;
  end;
end;

procedure TThreadsGuardTests.StartThreads_AlreadyStartedThread_Raises;
var
  LEvent: TEvent;
  LThread: TEventThread;
begin
  LEvent := TEvent.Create(nil, False, False, '');
  try
    LThread := TEventThread.Create(LEvent);
    LThread.FreeOnTerminate := False;
    LThread.Start;
    Assert.WillRaise(
      procedure begin FGuard.StartThreads([LThread]) end,
      EInvalidOperation);
  finally
    LEvent.SetEvent;
    LThread.WaitFor;
    LThread.Free;
    LEvent.Free;
  end;
  FGuard.StartThreads([TSimpleThread.Create]);
end;

// ---------------------------------------------------------------------------
// TBlockingThreadsGuardTerminateTests
// ---------------------------------------------------------------------------

procedure TBlockingThreadsGuardTerminateTests.Setup;
begin
  FGuard := TBlockingThreadsGuard<TGuardedThread>.Create;
end;

procedure TBlockingThreadsGuardTerminateTests.TearDown;
begin
  FGuard.Terminate;
  FGuard.WaitFor;
  FGuard.Free;
end;

procedure TBlockingThreadsGuardTerminateTests.Guard_TerminatesWithNoThreads;
begin
  FGuard.Terminate;
  Assert.IsTrue(FGuard.WaitFor(0) = wrSignaled,
    'Guard should remain idle after Terminate with no threads running');
end;

procedure TBlockingThreadsGuardTerminateTests.Guard_TerminatesRunning;
begin
  FGuard.StartThreads([
    TTerminationAwareThread.Create,
    TTerminationAwareThread.Create
  ]);
  FGuard.Terminate;
  Assert.IsTrue(FGuard.WaitFor(5000) = wrSignaled,
    'All threads should stop after Terminate is called');
end;

procedure TBlockingThreadsGuardTerminateTests.Guard_ReusableAfterTerminate;
var
  LCount: Integer;
begin
  LCount := 0;
  FGuard.StartThreads([TTerminationAwareThread.Create]);
  FGuard.Terminate;
  FGuard.WaitFor;
  FGuard.StartThreads([TCountingThread.Create(@LCount)]);
  FGuard.WaitFor;
  Assert.AreEqual(1, LCount,
    'Guard should accept new threads after Terminate + WaitFor');
end;

// ---------------------------------------------------------------------------
// TBlockingThreadsGuardTests
// ---------------------------------------------------------------------------

procedure TBlockingThreadsGuardTests.Setup;
begin
  FGuard := TBlockingThreadsGuard<TGuardedThread>.Create;
end;

procedure TBlockingThreadsGuardTests.TearDown;
begin
  FGuard.Free;
end;

procedure TBlockingThreadsGuardTests.StartThreads_WhileRunning_ReturnsFalse;
var
  LEvent: TEvent;
  LResult: Boolean;
begin
  LEvent := TEvent.Create(nil, False, False, '');
  try
    FGuard.StartThreads([TEventThread.Create(LEvent)]);
    var LRejected := TSimpleThread.Create;
    LResult := FGuard.StartThreads([LRejected]);
    if not LResult then LRejected.Free;
    LEvent.SetEvent;
    FGuard.WaitFor;
    Assert.IsFalse(LResult, 'Blocking guard should refuse new batch while threads are running');
  finally
    LEvent.SetEvent;
    FGuard.WaitFor;
    LEvent.Free;
  end;
end;

procedure TBlockingThreadsGuardTests.StartThreads_AfterAllComplete_ReturnsTrue;
var
  LEvent: TEvent;
begin
  LEvent := TEvent.Create(nil, False, False, '');
  try
    FGuard.StartThreads([TEventThread.Create(LEvent)]);
    LEvent.SetEvent;
    FGuard.WaitFor;
    Assert.IsTrue(FGuard.StartThreads([TSimpleThread.Create]),
      'Blocking guard should accept new batch after all previous threads completed');
    FGuard.WaitFor;
  finally
    LEvent.SetEvent;
    FGuard.WaitFor;
    LEvent.Free;
  end;
end;

// ---------------------------------------------------------------------------
// TGlobalThreadsGuardTests
// ---------------------------------------------------------------------------

procedure TGlobalThreadsGuardTests.GlobalGuard_IsNotNil;
begin
  Assert.IsNotNull(ThreadsGuard,
    'ThreadsGuard should be initialised by the unit''s initialization section');
end;

procedure TGlobalThreadsGuardTests.GlobalGuard_InitiallyIdle;
begin
  Assert.IsTrue(ThreadsGuard.WaitFor(0) = wrSignaled,
    'Global ThreadsGuard should be idle when no threads have been started');
end;

// ---------------------------------------------------------------------------
// TParallelForTests
// ---------------------------------------------------------------------------

procedure TParallelForTests.Setup;
begin
  FParallelFor := TParallelFor.Create(4);
end;

procedure TParallelForTests.TearDown;
begin
  FParallelFor.Free;
end;

procedure TParallelForTests.MaxThreads_ReturnsCreatedCount;
begin
  Assert.AreEqual(4, FParallelFor.MaxThreads);
end;

procedure TParallelForTests.Execute_AllIterationsRun;
var
  LCount: Integer;
begin
  LCount := 0;
  FParallelFor.Execute(1, 100,
    procedure(I, T: Integer)
    begin
      TInterlocked.Increment(LCount);
    end);
  Assert.AreEqual(100, LCount, 'Every iteration in the range should run exactly once');
end;

procedure TParallelForTests.Execute_ThreadIndexInRange;
var
  LBadIndex: Integer;
begin
  LBadIndex := 0;
  FParallelFor.Execute(1, 100,
    procedure(I, T: Integer)
    begin
      if (T < 0) or (T >= FParallelFor.MaxThreads) then
        TInterlocked.Increment(LBadIndex);
    end);
  Assert.AreEqual(0, LBadIndex, 'Thread index should always be in [0, MaxThreads)');
end;

procedure TParallelForTests.Execute_PerThreadAccumulation;
var
  LCounts: array of Integer;
  LTotal: Integer;
begin
  SetLength(LCounts, FParallelFor.MaxThreads);
  FParallelFor.Execute(1, 100,
    procedure(I, T: Integer)
    begin
      Inc(LCounts[T]);
    end);
  LTotal := 0;
  for var C in LCounts do Inc(LTotal, C);
  Assert.AreEqual(100, LTotal,
    'Per-thread slot totals should sum to the full iteration count');
end;

procedure TParallelForTests.Execute_EmptyRange_NothingRuns;
var
  LCount: Integer;
begin
  LCount := 0;
  FParallelFor.Execute(10, 1,
    procedure(I, T: Integer)
    begin
      TInterlocked.Increment(LCount);
    end);
  Assert.AreEqual(0, LCount, 'ToIteration < FromIteration should run no iterations');
end;

procedure TParallelForTests.Execute_Stride;
var
  LCount: Integer;
begin
  LCount := 0;
  FParallelFor.Execute(1, 10,
    procedure(I, T: Integer)
    begin
      TInterlocked.Increment(LCount);
    end, 2);
  Assert.AreEqual(5, LCount, 'Stride 2 over 1..10 should visit exactly 5 iterations');
end;

procedure TParallelForTests.Execute_Reusable;
var
  LCount: Integer;
begin
  LCount := 0;
  FParallelFor.Execute(1, 50,
    procedure(I, T: Integer) begin TInterlocked.Increment(LCount) end);
  FParallelFor.Execute(51, 100,
    procedure(I, T: Integer) begin TInterlocked.Increment(LCount) end);
  Assert.AreEqual(100, LCount,
    'TParallelFor should accept a second Execute call after the first completes');
end;

procedure TParallelForTests.Execute_NThreadsOne_UsesSingleThread;
var
  LMaxThread: Integer;
begin
  LMaxThread := -1;
  FParallelFor.Execute(1, 1, 100,
    procedure(I, T: Integer)
    begin
      if T > LMaxThread then LMaxThread := T;
    end);
  Assert.AreEqual(0, LMaxThread,
    'NThreads=1 should route all iterations through thread index 0');
end;

procedure TParallelForTests.Execute_ExceptionPropagates;
var
  LMsg: string;
begin
  LMsg := '';
  try
    FParallelFor.Execute(1, 100,
      procedure(I, T: Integer)
      begin
        if I = 50 then
          raise Exception.Create('iteration error');
      end);
  except
    on E: Exception do LMsg := E.Message;
  end;
  Assert.AreEqual('iteration error (50)', LMsg,
    'An exception raised inside an iteration should propagate to the caller');
end;

procedure TParallelForTests.Execute_Exception_SingleThreadedPath;
var
  LPar: TParallelFor;
begin
  LPar := TParallelFor.Create(1);
  try
    Assert.WillRaise(
      procedure
      begin
        LPar.Execute(1, 10,
          procedure(I, T: Integer)
          begin
            if I = 5 then raise Exception.Create('single-thread error');
          end);
      end,
      Exception);
  finally
    LPar.Free;
  end;
end;

procedure TParallelForTests.Execute_Exception_OnlyFirstPropagates;
var
  LRaiseCount, LCatchCount: Integer;
begin
  LRaiseCount := 0;
  LCatchCount := 0;
  try
    FParallelFor.Execute(1, 100,
      procedure(I, T: Integer)
      begin
        TInterlocked.Increment(LRaiseCount);
        raise Exception.Create('error ' + I.ToString);
      end);
  except
    on E: Exception do
    begin
      Inc(LCatchCount);
      Assert.IsTrue(E.Message.StartsWith('error '),
        'Propagated message should come from one of the raising iterations');
    end;
  end;
  Assert.AreEqual(1, LCatchCount, 'Exactly one exception should reach the caller');
end;

procedure TParallelForTests.Execute_SingleThreaded_AllIterationsRun;
var
  LPar: TParallelFor;
  LCount: Integer;
begin
  LPar := TParallelFor.Create(1);
  try
    LCount := 0;
    LPar.Execute(1, 100,
      procedure(I, T: Integer) begin Inc(LCount) end);
    Assert.AreEqual(100, LCount,
      'Single-threaded TParallelFor should run all iterations in the calling thread');
  finally
    LPar.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TThreadsGuardTests);
  TDUnitX.RegisterTestFixture(TBlockingThreadsGuardTerminateTests);
  TDUnitX.RegisterTestFixture(TBlockingThreadsGuardTests);
  TDUnitX.RegisterTestFixture(TGlobalThreadsGuardTests);
  TDUnitX.RegisterTestFixture(TParallelForTests);

end.