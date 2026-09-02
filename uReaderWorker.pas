unit uReaderWorker;

interface

uses
  System.Classes,
  System.SysUtils;

type

  TReaderWorker = class(TThread)
  private
    FFileName: string;
    FBookText: string;

    procedure DoFinished;

  protected
    procedure Execute; override;

  public

    constructor Create(
      const AFileName: string
    );

    property BookText: string read FBookText;

  end;


implementation


constructor TReaderWorker.Create(
  const AFileName: string
);
begin

  inherited Create(True);

  FreeOnTerminate := True;

  FFileName :=
    AFileName;

end;


procedure TReaderWorker.Execute;
begin

  try

    // 后面把 EPUB读取放这里

    FBookText :=
      '测试加载内容';


    Synchronize(
      DoFinished
    );


  except

    on E: Exception do
    begin

      // 后面处理错误

    end;

  end;

end;


procedure TReaderWorker.DoFinished;
begin

  // 这里运行在主线程

  // 通知窗体：
  // 加载完成

end;


end.
