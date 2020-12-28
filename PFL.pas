unit PFL;

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
  Classes,SysUtils,SyncObjs;

Type
  TLoopIteration = reference to Procedure(Iteration,Thread: Integer);

  TParallelFor = Class
  private
    Type
      TIterationThread = Class(TThread)
      private
        Loop: TParallelFor;
        Thread,Iteration: Integer;
        LoopIteration: TLoopIteration;
      public
        Procedure Execute; override;
      end;
    Var
      LoopCompleted: TEvent;
      FirstException: Exception;
      Next,IterationCount,ThreadCount: Integer;
  public
    Constructor Create;
    Procedure Execute(FromIteration,ToIteration: Integer; const Iteration: TLoopIteration); overload;
    Procedure Execute(NThreads,FromIteration,ToIteration: Integer; const Iteration: TLoopIteration); overload;
    Destructor Destroy; override;
  end;

////////////////////////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////////////////////////

Procedure TParallelFor.TIterationThread.Execute;
begin
  repeat
    // Execute iteration
    try
      LoopIteration(Iteration,Thread);
    except
      on E: Exception do
      begin
        TMonitor.Enter(Loop);
        try
          Dec(Loop.ThreadCount);
          if Loop.ThreadCount = 0 then Loop.LoopCompleted.SetEvent;
          if Loop.FirstException = nil then Loop.FirstException := AcquireExceptionObject as Exception;
          Terminate;
        finally
          TMonitor.Exit(Loop);
        end;
      end;
    end;
    // Collect next iteration
    if not Terminated then
    begin
      TMonitor.Enter(Loop);
      try
        if (Loop.FirstException = nil) and (Loop.IterationCount > 0) then
        begin
          Iteration := Loop.Next;
          Inc(Loop.Next);
          Dec(Loop.IterationCount);
        end else
        begin
          Dec(Loop.ThreadCount);
          if Loop.ThreadCount = 0 then Loop.LoopCompleted.SetEvent;
          Terminate;
        end;
      finally
        TMonitor.Exit(Loop);
      end;
    end;
  until Terminated;
end;

////////////////////////////////////////////////////////////////////////////////

Constructor TParallelFor.Create;
begin
  inherited Create;
  LoopCompleted := TEvent.Create(nil,false,true,'');
end;

Procedure TParallelFor.Execute(FromIteration,ToIteration: Integer; const Iteration: TLoopIteration);
begin
  Execute(TThread.ProcessorCount,FromIteration,ToIteration,Iteration);
end;

Procedure TParallelFor.Execute(NThreads,FromIteration,ToIteration: Integer; const Iteration: TLoopIteration);
begin
  if ToIteration >= FromIteration then
  begin
    FirstException := nil;
    TMonitor.Enter(Self);
    try
      LoopCompleted.ResetEvent;
      Next := FromIteration;
      IterationCount := ToIteration-FromIteration+1;
      while (IterationCount > 0) and (ThreadCount < NThreads) do
      begin
        var Thread := TIterationThread.Create(true);
        Thread.Thread := ThreadCount;
        Thread.Iteration := Next;
        Thread.LoopIteration := Iteration;
        Thread.Loop := Self;
        Thread.FreeOnTerminate := true;
        Thread.Start;
        Inc(ThreadCount);
        Inc(Next);
        Dec(IterationCount);
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
  LoopCompleted.Free;
  inherited Destroy;
end;

end.
