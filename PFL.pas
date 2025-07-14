unit PFL;

////////////////////////////////////////////////////////////////////////////////
//
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
//
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
//
// Author: Jaap Baak
// https://github.com/transportmodelling/Utils
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
interface
////////////////////////////////////////////////////////////////////////////////

Uses
  Classes, SysUtils, Math, SyncObjs;

Type
  TLoopIteration = reference to Procedure(Iteration,Thread: Integer);

  TParallelFor = Class
  private
    Type
      TIterationThread = Class(TThread)
      private
        Active: TEvent;
        Loop: TParallelFor;
        Thread,Iteration,Stride: Integer;
        LoopIteration: TLoopIteration;
      public
        Constructor Create;
        Procedure Execute; override;
        Destructor Destroy; override;
      end;
    Var
      FMaxThreads: Integer;
      LoopCompleted: TEvent;
      FirstException: Exception;
      Next,IterationCount,ActiveThreads: Integer;
      ThreadPool: array of TIterationThread;
  public
    Constructor Create(ThreadCount: Integer);
    Procedure Execute(const FromIteration,ToIteration: Integer;
                      const Iteration: TLoopIteration;
                      const Stride: Integer = 1); overload;
    Procedure Execute(const NThreads,FromIteration,ToIteration: Integer;
                      const Iteration: TLoopIteration;
                      const Stride: Integer = 1); overload;
    Destructor Destroy; override;
  public
    Property MaxThreads: Integer read FMaxThreads;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Constructor TParallelFor.TIterationThread.Create;
begin
  inherited Create(true);
  Active := TEvent.Create(nil,true,false,'');
end;

Procedure TParallelFor.TIterationThread.Execute;
begin
  repeat
    Active.WaitFor(Infinite);
    // Execute iteration
    if not Terminated then
    try
      LoopIteration(Iteration,Thread);
    except
      on E: Exception do
      begin
        TMonitor.Enter(Loop);
        try
          Dec(Loop.ActiveThreads);
          if Loop.ActiveThreads = 0 then Loop.LoopCompleted.SetEvent;
          if Loop.FirstException = nil then Loop.FirstException := AcquireExceptionObject as Exception;
          Terminate;
        finally
          TMonitor.Exit(Loop);
        end;
      end;
    end;
    if not Terminated then
    begin
      TMonitor.Enter(Loop);
      try
        if (Loop.FirstException = nil) and (Loop.IterationCount > 0) then
        begin
          Iteration := Loop.Next;
          Inc(Loop.Next,Stride);
          Dec(Loop.IterationCount,Stride);
        end else
        begin
          Active.ResetEvent;
          Dec(Loop.ActiveThreads);
          if Loop.ActiveThreads = 0 then Loop.LoopCompleted.SetEvent;
        end;
      finally
        TMonitor.Exit(Loop);
      end;
    end;
  until Terminated;
end;

Destructor TParallelFor.TIterationThread.Destroy;
begin
  Active.Free;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TParallelFor.Create(ThreadCount: Integer);
begin
  inherited Create;
  FMaxThreads := ThreadCount;
  SetLength(ThreadPool,ThreadCount);
  LoopCompleted := TEvent.Create(nil,false,true,'');
  for var Thread := 0 to ThreadCount-1 do
  begin
    ThreadPool[Thread] := TIterationThread.Create;
    ThreadPool[Thread].Loop := Self;
    ThreadPool[Thread].Thread := Thread;
    ThreadPool[Thread].FreeOnTerminate := true;
    ThreadPool[Thread].Start;
  end;
end;

Procedure TParallelFor.Execute(const FromIteration,ToIteration: Integer;
                               const Iteration: TLoopIteration;
                               const Stride: Integer = 1);
begin
  Execute(FMaxThreads,FromIteration,ToIteration,Iteration,Stride);
end;

Procedure TParallelFor.Execute(const NThreads,FromIteration,ToIteration: Integer;
                               const Iteration: TLoopIteration;
                               const Stride: Integer = 1);
begin
  if ToIteration >= FromIteration then
  begin
    var ThreadCount := Min(NThreads,FMaxThreads);
    FirstException := nil;
    TMonitor.Enter(Self);
    try
      LoopCompleted.ResetEvent;
      Next := FromIteration;
      IterationCount := ToIteration-FromIteration+1;
      while (IterationCount > 0) and (ActiveThreads < ThreadCount) do
      begin
        ThreadPool[ActiveThreads].Stride := Stride;
        ThreadPool[ActiveThreads].Iteration := Next;
        ThreadPool[ActiveThreads].LoopIteration := Iteration;
        ThreadPool[ActiveThreads].Active.SetEvent;
        Inc(ActiveThreads);
        Inc(Next,Stride);
        Dec(IterationCount,Stride);
      end;
    finally
      TMonitor.Exit(Self);
    end;
    LoopCompleted.WaitFor(Infinite);
    if FirstException <> nil then raise FirstException;
  end;
end;

Destructor TParallelFor.Destroy;
begin
  for var Thread := low(ThreadPool) to high(ThreadPool) do
  begin
    ThreadPool[Thread].Terminate;
    ThreadPool[Thread].Active.SetEvent;
  end;
  LoopCompleted.Free;
  inherited Destroy;
end;

end.
