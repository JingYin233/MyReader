unit uReadingState;

interface

uses
  System.SysUtils;

type

  TReadingState = class
  public
    BookID: string;          // 书籍ID
    BookName: string;        // 书名

    CurrentPage: Integer;    // 当前页
    CurrentStart: Integer;   // 当前文本位置
    CurrentEnd: Integer;

    LastReadTime: TDateTime; // 最后阅读时间

    constructor Create;
  end;


implementation


constructor TReadingState.Create;
begin
  CurrentPage := 0;
  CurrentStart := 1;
  CurrentEnd := 0;
  LastReadTime := Now;
end;


end.
