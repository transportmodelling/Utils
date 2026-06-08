unit ThrdLib;

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  SysUtils, Classes, Math, SyncObjs;

Type
  TGuardData = Class
  private
    Count: Integer;
    Idle: TEvent;
    HasError: Boolean;
    FirstError: String;
    Procedure RemoveThread(Index: Integer); virtual;
    Procedure ThreadError(const ErrorMessage: String);
    Procedure ThreadCompleted(const Index: Integer);
  end;

  TGuardedThread = Class(TThread)
  private
    ThreadIndex: Integer;
    Guard: TGuardData;
  strict protected
    Procedure ExecuteThread; virtual; abstract;
  protected
    Procedure Execute; override; final;
    Procedure DoTerminate; override;
  public
    Constructor Create;
  end;

  TThreadsGuard<T: TGuardedThread> = Class(TGuardData)
  // Waits for all threads it created in the destructor
  private
    Blocking: Boolean;
    RunningThreads: array of T; // Threads started in last StartThreads-call
  public
    Constructor Create;
    Function StartThreads(const Threads: array of T): Boolean;
    Function Error(out ErrorMessage: String; Reset: Boolean = false): Boolean;
    Function WaitFor(Timeout: Cardinal = Infinite): TWaitResult;
    Destructor Destroy; override;
  end;

  TBlockingThreadsGuard<T: TGuardedThread> = Class(TThreadsGuard<T>)
  // Only starts threads when all previously started threads are completed
  private
    Procedure RemoveThread(Index: Integer); override;
  public
    Constructor Create;
    Procedure Terminate;
  end;

  TIteration = Class
  protected
    Procedure Execute(const Iteration,Thread: Integer); virtual; abstract;
  end;

  TThreadedIterator = Class
  // Descendent classes must instantiate the Iteration-field
  private
    Type
      TIteratorThread = Class(TGuardedThread)
      private
        Active: TEvent;
        Current,Stride: Integer;
        Iterator: TThreadedIterator;
      strict protected
        Procedure ExecuteThread; override;
        procedure TerminatedSet; override;
      public
        Constructor Create;
        Destructor Destroy; override;
      end;
    Var
      FMaxThreads,Next,IterationCount,ActiveThreads: Integer;
      LoopCompleted: TEvent;
      Iteration: TIteration;
      Guard: TBlockingThreadsGuard<TIteratorThread>;
  strict protected
    Procedure Execute(const NThreads,FromIteration,ToIteration: Integer; Stride: Integer = 1); overload;
  public
    Constructor Create(ThreadCount: Integer);
    Destructor Destroy; override;
  public
    Property MaxThreads: Integer read FMaxThreads;
  end;

  TLoopIteration = reference to Procedure(Iteration,Thread: Integer);

  TParallelFor = Class(TThreadedIterator)
  // Unlike the PPL, the parallel for loop implemented in this unit provides the
  // index of the thread in the thread pool for each iteration. This allows to avoid intensive
  // use of TInterlocked.
  //
  // For example, the PPL code:
  //
  // TParallel.For(2,1,Max,procedure(I:Int64)
  //                       begin
  //                         if IsPrime(I) then TInterlocked.Increment(NPrimes);
  //                       end);
  //
  // Can be implemented using a ParallelFor-object of type TParallelFor:
  //
  // ParallelFor.Execute(1,Max,procedure(I,Thread:Integer)
  //                           begin
  //                             if IsPrime(I) then Inc(NPrimes[Thread]);
  //                           end, 2);
  //
  // and finally summing the NPrimes-array over all threads.
  private
    Type
      TLoopIterationAdapter = Class(TIteration)
      private
        LoopIteration: TLoopIteration;
      protected
        Procedure Execute(const Iteration,Thread: Integer); override;
      end;
    Var
      Adapter: TLoopIterationAdapter;
  public
    Constructor Create(ThreadCount: Integer);
    Procedure Execute(const FromIteration,ToIteration: Integer;
                      const LoopIteration: TLoopIteration;
                      const Stride: Integer = 1); overload;
    Procedure Execute(const FromIteration,ToIteration: Integer;
                      const LoopIteration: TIteration;
                      const Stride: Integer = 1); overload;
    Procedure Execute(const NThreads,FromIteration,ToIteration: Integer;
                      const LoopIteration: TLoopIteration;
                      const Stride: Integer = 1); overload;
    Procedure Execute(const NThreads,FromIteration,ToIteration: Integer;
                      const LoopIteration: TIteration;
                      const Stride: Integer = 1); overload;
    Destructor Destroy; override;
  end;

Var
  ThreadsGuard: TThreadsGuard<TGuardedThread> = nil;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TGuardData.RemoveThread(Index: Integer);
begin
end;

Procedure TGuardData.ThreadError(const ErrorMessage: String);
begin
  TMonitor.Enter(Self);
  try
    HasError := true;
    if FirstError = '' then FirstError := ErrorMessage;
  finally
    TMonitor.Exit(Self);
  end;
end;

Procedure TGuardData.ThreadCompleted(const Index: Integer);
// Must be called at the end of a thread''s Execute-method.
// Idle is signalled *after* releasing the monitor so that the main thread
// cannot call Guard.Free (destroying the monitor''s CriticalSection) while
// this thread is still inside TMonitor.Exit.
var
  SignalIdle: Boolean;
begin
  TMonitor.Enter(Self);
  try
    RemoveThread(Index);
    Dec(Count);
    SignalIdle := (Count = 0);
  finally
    TMonitor.Exit(Self);
  end;
  if SignalIdle then Idle.SetEvent;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TGuardedThread.Create;
begin
  inherited Create(true);
  FreeOnTerminate := true;
end;

Procedure TGuardedThread.Execute;
begin
  try
    ExecuteThread;
  except
    on E: Exception do if Assigned(Guard) then Guard.ThreadError(E.Message) else raise
  end;
end;

Procedure TGuardedThread.DoTerminate;
begin
  inherited DoTerminate;
  if Assigned(Guard) then Guard.ThreadCompleted(ThreadIndex);
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TThreadsGuard<T>.Create;
begin
  inherited Create;
  Idle := TEvent.Create(nil,true,true,'');
end;

Function TThreadsGuard<T>.StartThreads(const Threads: array of T): Boolean;
begin
  if Length(Threads) > 0 then
  begin
    TMonitor.Enter(Self);
    try
      if (Count = 0) or (not Blocking) then
      begin
        Result := true;
        Idle.ResetEvent;
        SetLength(RunningThreads,Length(Threads));
        for var Thread := low(Threads) to high(Threads) do
        begin
          if Threads[Thread].Suspended then
          begin
            RunningThreads[Thread] := Threads[Thread];
            Threads[Thread].ThreadIndex := Thread;
            Threads[Thread].Guard := Self;
            Threads[Thread].Start;
            Inc(Count);
          end else
            raise EInvalidOperation.Create(Threads[Thread].ClassName + ' has already been started');
        end;
      end else
        Result := false;
    finally
      TMonitor.Exit(Self);
    end;
  end else
    Result := false;
end;

Function TThreadsGuard<T>.Error(out ErrorMessage: String; Reset: Boolean = false): Boolean;
begin
  TMonitor.Enter(Self);
  try
    ErrorMessage := FirstError;
    if Reset then
    begin
      HasError := false;
      FirstError := '';
    end;
    Result := (ErrorMessage <> '');
  finally
    TMonitor.Exit(Self);
  end;
end;

Function TThreadsGuard<T>.WaitFor(Timeout: Cardinal = Infinite): TWaitResult;
begin
  Result := Idle.WaitFor(Timeout);
end;

Destructor TThreadsGuard<T>.Destroy;
begin
  WaitFor;
  Idle.Free;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TBlockingThreadsGuard<T>.Create;
begin
  inherited Create;
  Blocking := true;
end;

Procedure TBlockingThreadsGuard<T>.RemoveThread(Index: Integer);
begin
  RunningThreads[Index] := nil;
end;

Procedure TBlockingThreadsGuard<T>.Terminate;
begin
  TMonitor.Enter(Self);
  try
    for var Thread := low(RunningThreads) to high(RunningThreads) do
    if Assigned(RunningThreads[Thread]) then RunningThreads[Thread].Terminate;
  finally
    TMonitor.Exit(Self);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TThreadedIterator.TIteratorThread.Create;
begin
  inherited Create;
  Active := TEvent.Create(nil,true,false,'');
end;

Procedure TThreadedIterator.TIteratorThread.ExecuteThread;
var
  HadException: Boolean;
begin
  repeat
    // Wait until the owning iterator signals work is available (or Terminate is called)
    Active.WaitFor(Infinite);
    HadException := false;
    if not Terminated then
    try
      Iterator.Iteration.Execute(Current,ThreadIndex);
    except
      on E: Exception do
      begin
        // Record error and mark locally so this thread goes idle unconditionally below.
        // HadException must be set before entering the Iterator monitor to avoid a
        // window where the main thread could nil Iterator.Iteration between
        // ThreadError returning and TMonitor.Enter.
        Iterator.Guard.ThreadError(E.Message + ' (' + Current.ToString + ')');
        HadException := true;
      end;
    end;
    TMonitor.Enter(Iterator);
    try
      if (not Terminated) and (not HadException) and (not Iterator.Guard.HasError) and (Iterator.IterationCount > 0) then
      begin
        // Claim the next iteration
        Current := Iterator.Next;
        Inc(Iterator.Next,Stride);
        Dec(Iterator.IterationCount,Stride);
      end else
      begin
        // No more work (or termination/error): go idle and notify if last active thread
        Active.ResetEvent;
        Dec(Iterator.ActiveThreads);
        if Iterator.ActiveThreads = 0 then Iterator.LoopCompleted.SetEvent;
      end;
    finally
      TMonitor.Exit(Iterator);
    end;
  until Terminated;
end;

procedure TThreadedIterator.TIteratorThread.TerminatedSet;
begin
  inherited TerminatedSet;
  Active.SetEvent;
end;

Destructor TThreadedIterator.TIteratorThread.Destroy;
begin
  Active.Free;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TThreadedIterator.Create(ThreadCount: Integer);
Var
  Threads: array of TIteratorThread;
begin
  inherited Create;
  FMaxThreads := ThreadCount;
  if ThreadCount > 1 then
  begin
    Guard := TBlockingThreadsGuard<TIteratorThread>.Create;
    LoopCompleted := TEvent.Create(nil,false,true,'');
    SetLength(Threads,ThreadCount);
    for var Thread := 0 to ThreadCount-1 do
    begin
      Threads[Thread] := TIteratorThread.Create;
      Threads[Thread].Iterator := Self;
    end;
    Guard.StartThreads(Threads);
  end;
end;

Procedure TThreadedIterator.Execute(const NThreads,FromIteration,ToIteration: Integer; Stride: Integer = 1);
Var
  ErrorMesage: String;
begin
  if ToIteration >= FromIteration then
  begin
    var ThreadCount := Min(NThreads,FMaxThreads);
    if ThreadCount = 1 then
    begin
      // Single threaded, avoid synchronization overhead
      var Iter := FromIteration;
      while Iter <= ToIteration do
      begin
        Iteration.Execute(Iter,0);
        Inc(Iter,Stride);
      end;
    end else
    begin
      // Multi threaded
      TMonitor.Enter(Guard);
      try
        Guard.HasError := false;
        Guard.FirstError := '';
      finally
        TMonitor.Exit(Guard);
      end;
      TMonitor.Enter(Self);
      try
        LoopCompleted.ResetEvent;
        Next := FromIteration;
        IterationCount := ToIteration-FromIteration+1;
        while (IterationCount > 0) and (ActiveThreads < ThreadCount) do
        begin
          Guard.RunningThreads[ActiveThreads].Stride := Stride;
          Guard.RunningThreads[ActiveThreads].Current := Next;
          Guard.RunningThreads[ActiveThreads].Active.SetEvent;
          Inc(ActiveThreads);
          Inc(Next,Stride);
          Dec(IterationCount,Stride);
        end;
      finally
        TMonitor.Exit(Self);
      end;
      LoopCompleted.WaitFor(Infinite);
      if Guard.Error(ErrorMesage,true) then raise Exception.Create(ErrorMesage);
    end;
  end;
end;

Destructor TThreadedIterator.Destroy;
begin
  if Guard <> nil then
  begin
    Guard.Terminate;
    Guard.WaitFor;
    Guard.Free;
    LoopCompleted.Free;
  end;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Procedure TParallelFor.TLoopIterationAdapter.Execute(const Iteration,Thread: Integer);
begin
  LoopIteration(Iteration,Thread);
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TParallelFor.Create(ThreadCount: Integer);
begin
  inherited Create(ThreadCount);
  Adapter := TLoopIterationAdapter.Create;
end;

Procedure TParallelFor.Execute(const FromIteration,ToIteration: Integer;
                               const LoopIteration: TLoopIteration;
                               const Stride: Integer = 1);
begin
  Execute(FMaxThreads,FromIteration,ToIteration,LoopIteration,Stride);
end;

Procedure TParallelFor.Execute(const FromIteration,ToIteration: Integer;
                               const LoopIteration: TIteration;
                               const Stride: Integer = 1);
begin
  Execute(FMaxThreads,FromIteration,ToIteration,LoopIteration,Stride);
end;

Procedure TParallelFor.Execute(const NThreads,FromIteration,ToIteration: Integer;
                               const LoopIteration: TLoopIteration;
                               const Stride: Integer = 1);
begin
  Adapter.LoopIteration := LoopIteration;
  Execute(NThreads,FromIteration,ToIteration,Adapter,Stride);
  Adapter.LoopIteration := nil;
end;

Procedure TParallelFor.Execute(const NThreads,FromIteration,ToIteration: Integer;
                               const LoopIteration: TIteration;
                               const Stride: Integer = 1);
begin
  Iteration := LoopIteration;
  Execute(NThreads,FromIteration,ToIteration,Stride);
end;

Destructor TParallelFor.Destroy;
begin
  Adapter.Free;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Initialization
  ThreadsGuard := TThreadsGuard<TGuardedThread>.Create;
Finalization
  ThreadsGuard.Free;
end.


