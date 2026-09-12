unit uReadingState;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

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

    function GetStateFileName: string;

    procedure SaveToFile(const FileName: string);

    procedure LoadFromFile(const FileName: string);

    function GetChapterCacheFileName: string;
  end;

implementation

constructor TReadingState.Create;
begin
  CurrentPage := 0;
  CurrentStart := 1;
  CurrentEnd := 0;
  LastReadTime := Now;
end;

function TReadingState.GetStateFileName: string;
begin

  Result := TPath.Combine(TPath.Combine(TPath.GetHomePath, 'MyReader\ReadingStates'), BookID + '.txt');

end;

procedure TReadingState.SaveToFile(const FileName: string);
var
  SL: TStringList;
begin

  SL := TStringList.Create;

  try

    SL.Add('BookID=' + BookID);

    SL.Add('BookName=' + BookName);

    SL.Add('CurrentPage=' + IntToStr(CurrentPage));

    SL.Add('CurrentStart=' + IntToStr(CurrentStart));

    SL.Add('CurrentEnd=' + IntToStr(CurrentEnd));

    SL.Add('LastReadTime=' + DateTimeToStr(LastReadTime));

    ForceDirectories(ExtractFilePath(FileName));

    SL.SaveToFile(FileName, TEncoding.UTF8);

  finally

    SL.Free;

  end;

end;

procedure TReadingState.LoadFromFile(const FileName: string);
var
  SL: TStringList;
begin

  if not FileExists(FileName) then
    Exit;

  SL := TStringList.Create;

  try

    SL.LoadFromFile(FileName, TEncoding.UTF8);

    BookID := SL.Values['BookID'];

    BookName := SL.Values['BookName'];

    CurrentPage := StrToIntDef(SL.Values['CurrentPage'], 0);

    CurrentStart := StrToIntDef(SL.Values['CurrentStart'], 1);

    CurrentEnd := StrToIntDef(SL.Values['CurrentEnd'], 0);

    LastReadTime := StrToDateTimeDef(SL.Values['LastReadTime'], Now);

  finally

    SL.Free;

  end;

end;

function TReadingState.GetChapterCacheFileName: string;
var
  CacheDir: string;
begin

  CacheDir := TPath.Combine(TPath.GetHomePath, 'MyReader\ChapterCache');

  ForceDirectories(CacheDir);

  Result := TPath.Combine(CacheDir, BookID + '.ini');

end;

end.

