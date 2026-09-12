unit TestDockForm;

interface

uses
  System.Classes,Vcl.Forms,Vcl.Controls,Vcl.StdCtrls,DockForm, Vcl.ToolWin,
  Vcl.ActnMan, Vcl.ActnCtrls, System.Actions,Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls,
  System.ImageList, Vcl.ImgList,Vcl.CustomizeDlg, Vcl.ExtCtrls, Winapi.Windows,
  Vcl.Graphics,System.SysUtils,System.Generics.Collections,System.IOUtils,
  Vcl.Dialogs,System.Math, System.Zip,System.RegularExpressions,Vcl.Themes,
  Xml.XMLDoc,Xml.XMLIntf,System.StrUtils,uReadingState,ToolsAPI,Vcl.Menus,uReaderColor;

type
  TBookChapter = record
    Title: string;
    Href: string;
    StartPos: Integer;
    EndPos: Integer;
  end;
  TManifestItem = record
    ID: string;
    Href: string;
  end;
  TTestDockForm = class(TDockableForm)
    ImageList1: TImageList;
    ActionManager1: TActionManager;
    ActionOpen: TAction;
    ActionPrev: TAction;
    ActionNext: TAction;
    ActionToolBar1: TActionToolBar;
    PaintBox1: TPaintBox;
    ActionPrevPage: TAction;
    ActionNextPage: TAction;
    ScrollBox1: TScrollBox;
    ActionSC: TAction;
    ChapterPanel: TPanel;
    ChapterList: TListBox;
    ActionChagColor: TAction;
    procedure PaintBox1Paint(Sender: TObject);
    procedure ActionPrevPageExecute(Sender: TObject);
    procedure ActionNextPageExecute(Sender: TObject);
    procedure ActionOpenExecute(Sender: TObject);
    procedure ActionPrevExecute(Sender: TObject);
    procedure ActionNextExecute(Sender: TObject);
    procedure ActionSCExecute(Sender: TObject);
    procedure ChapterListClick(Sender: TObject);
    procedure ActionChagColorExecute(Sender: TObject);
  private
    FBookText: string;
    FChapterVisible:Boolean;
    FChapters: TList<TBookChapter>;

    FCurrentStart: Integer;
    FCurrentEnd: Integer;
    FCurrentChapter: Integer;

    FCurrentPage: Integer;

    FPageStarts: TList<Integer>;

    FPageWidth: Integer;
    FPageHeight: Integer;

    FReadingState:TReadingState;

    FReaderColor:TReaderColor;

    procedure ToggleWindow;

    procedure CalcCurrentPage;

    procedure JumpToChapter(Index: Integer);

    procedure BuildChapterPages(Index: Integer);

    procedure SplitChapters(const Text: string;const Href: string;var BookText: string);

    function LoadEpubText(const FileName: string): string;
    function FindOpfPath(Zip: TZipFile): string;

    function FitTextToPage(const AText: string;StartPos: Integer): Integer;

    function TextFitsPage(const AText: string;StartPos: Integer;CharCount: Integer): Boolean;

    function ParseOpfAndLoadText(Zip: TZipFile;const OpfPath: string): string;

    function FindChapterTitle(const Text: string;out Title: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure NextPage;
    procedure PrevPage;
    procedure NextChapter;
    procedure PrevChapter;
    procedure ToggleReadWindow;
  end;

function GetTestDockForm:TTestDockForm;

implementation

{$R *.dfm}

var
  GTestDockForm:TTestDockForm;

const
  PAGE_MARGIN = 2;
  PAGE_FOOTER_HEIGHT = 40;

procedure TTestDockForm.SplitChapters(
  const Text: string;
  const Href: string;
  var BookText: string
);
var
  Reg: TRegEx;

  Matches: TMatchCollection;

  M: TMatch;

  LastPos: Integer;

  Chapter: TBookChapter;

  Title: string;

  Content: string;

  LastChapter: TBookChapter;

begin

  Reg :=
    TRegEx.Create(
      '第\s*[0-9零一二三四五六七八九十百千万]+\s*章(\s+|$)[^\r\n]*',
      [
        roIgnoreCase
      ]
    );


  Matches :=
    Reg.Matches(Text);



  //=================================
  // 当前文件没有章节标题
  // 说明是上一章节的延续
  //=================================

  if Matches.Count = 0 then
  begin

    if FChapters.Count > 0 then
    begin

      BookText :=
        BookText +
        Text +
        sLineBreak +
        sLineBreak;


      LastChapter :=
        FChapters[
          FChapters.Count - 1
        ];


      LastChapter.EndPos :=
        Length(BookText);


      FChapters[
        FChapters.Count - 1
      ] :=
        LastChapter;

    end;


    Exit;

  end;



  LastPos := 1;



  // 当前文件包含章节标题

  for M in Matches do
  begin


    //==============================
    // 当前标题之前的内容
    // 属于上一章节
    //==============================

    if M.Index > LastPos then
    begin

      Content :=
        Copy(
          Text,
          LastPos,
          M.Index - LastPos
        );


      if Trim(Content) <> '' then
      begin


        // 已经存在章节标题
        if Title <> '' then
        begin

          Chapter.Title :=
            Title;


          Chapter.Href :=
            Href;


          Chapter.StartPos :=
            Length(BookText)+1;


          BookText :=
            BookText +
            Content +
            sLineBreak +
            sLineBreak;


          Chapter.EndPos :=
            Length(BookText);


          FChapters.Add(
            Chapter
          );

        end;


      end;


    end;



    // 保存当前章节标题

    Title :=
      Trim(
        M.Value
      );


    LastPos :=
      M.Index +
      M.Length;


  end;



  //=================================
  // 最后一个章节正文
  //=================================

  if LastPos <= Length(Text) then
  begin

    Content :=
      Copy(
        Text,
        LastPos,
        Length(Text)-LastPos+1
      );


    if Title <> '' then
    begin

      Chapter.Title :=
        Title;


      Chapter.Href :=
        Href;


      Chapter.StartPos :=
        Length(BookText)+1;


      BookText :=
        BookText +
        Content +
        sLineBreak +
        sLineBreak;


      Chapter.EndPos :=
        Length(BookText);


      FChapters.Add(
        Chapter
      );

    end
    else
    begin

      // 理论上不会进入这里
      // 防止异常文本丢失

      BookText :=
        BookText +
        Content +
        sLineBreak +
        sLineBreak;

    end;


  end;


end;

function TTestDockForm.FindChapterTitle(const Text: string;out Title: string): Boolean;
var
  Reg: TRegEx;
  M: TMatch;

begin

  Result := False;

  Title := '';


  Reg :=
    TRegEx.Create(
      '第\s*[0-9零一二三四五六七八九十百千万]+\s*章[^\r\n]*',
      [
        roIgnoreCase
      ]
    );


  M :=
    Reg.Match(Text);


  if M.Success then
  begin

    Title :=
      Trim(
        M.Value
      );


    Result :=
      True;

  end;


end;

procedure TTestDockForm.ToggleWindow;
begin

  if Visible then
    Hide
  else
    Show;
end;

procedure TTestDockForm.ToggleReadWindow;
begin

  ToggleWindow;

end;

procedure TTestDockForm.NextPage;
begin

  ActionNextPageExecute(nil);

end;

procedure TTestDockForm.PrevPage;
begin
  ActionPrevPageExecute(nil);
end;
procedure TTestDockForm.NextChapter;
begin
  ActionNextExecute(nil);
end;
procedure TTestDockForm.PrevChapter;
begin
  ActionPrevExecute(nil);
end;

procedure TTestDockForm.JumpToChapter(
  Index: Integer
);
begin

  if Index < 0 then
    Exit;


  if Index >= FChapters.Count then
    Exit;


  BuildChapterPages(Index);


  PaintBox1.Invalidate;

end;

// 下一页
procedure TTestDockForm.ActionNextPageExecute(Sender: TObject);
begin

  if FCurrentPage + 1 < FPageStarts.Count then
  begin
    Inc(FCurrentPage);
  end

  else
  begin

    if FCurrentEnd < FChapters[FCurrentChapter].EndPos then
    begin

      FPageStarts.Add(
        FCurrentEnd + 1
      );

      Inc(FCurrentPage);

    end

    else
    begin
      if FCurrentChapter < FChapters.Count-1 then
      begin
        BuildChapterPages(
          FCurrentChapter+1
        );
        Exit;
      end
      else
        Exit;
    end;

  end;


  CalcCurrentPage;

  PaintBox1.Invalidate;

end;

{切换字体颜色}
procedure TTestDockForm.ActionChagColorExecute(Sender: TObject);
begin
  FReaderColor.SelectFontColor;

  PaintBox1.Invalidate;
end;

{下一章}
procedure TTestDockForm.ActionNextExecute(Sender: TObject);
begin
  if FCurrentChapter >= FChapters.Count-1 then
    Exit;

  JumpToChapter(
    FCurrentChapter + 1
  );
end;

// 打开文件
procedure TTestDockForm.ActionOpenExecute(Sender: TObject);
var
  Dlg: TOpenDialog;
  Ext: string;
begin
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter :=
      'Book Files (*.txt;*.epub)|*.txt;*.epub|' +
      'Text Files (*.txt)|*.txt|' +
      'EPUB Files (*.epub)|*.epub|' +
      'All Files (*.*)|*.*';

    if Dlg.Execute then
    begin
      try
        PaintBox1.Align := alNone;

        FPageWidth := PaintBox1.Parent.ClientWidth;
        FPageHeight := PaintBox1.Parent.ClientHeight;

        PaintBox1.Width := FPageWidth;
        PaintBox1.Height := FPageHeight;

        Ext := LowerCase(
          ExtractFileExt(Dlg.FileName)
        );

        if Ext = '.txt' then
          FBookText := TFile.ReadAllText(Dlg.FileName)
        else
        if Ext = '.epub' then
        begin
          FBookText := LoadEpubText(Dlg.FileName);
//
//
//          for var I := 0 to FChapters.Count - 1 do
//          begin
//            ShowMessage(
//              FChapters[I].Href
//            );
//          end;
        end
        else
          raise Exception.Create(
            '不支持的文件格式'
          );

        // 加载章节列表
        ChapterList.Items.BeginUpdate;
        try
          ChapterList.Items.Clear;
          for var I := 0 to FChapters.Count - 1 do
          begin
            ChapterList.Items.Add(
              FChapters[I].Title
            );
          end;
        finally
          ChapterList.Items.EndUpdate;
        end;

        FCurrentChapter:=0;
        BuildChapterPages(0);

        ScrollBox1.VertScrollBar.Position := 0;
        ScrollBox1.HorzScrollBar.Position := 0;

        PaintBox1.Invalidate;
      except
        on E: Exception do
          ShowMessage(
            E.ClassName +
            sLineBreak +
            E.Message
          );
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

// 打开EUPB文件
function TTestDockForm.LoadEpubText(
  const FileName: string
): string;
var
  Zip: TZipFile;
  OpfPath: string;

begin

  Result := '';

  FChapters.Clear;


  Zip := TZipFile.Create;

  try

    Zip.Open(FileName, zmRead);


    // 1. 找 content.opf
    OpfPath :=
      FindOpfPath(Zip);


    // 2. 根据opf读取章节
    Result :=
      ParseOpfAndLoadText(
        Zip,
        OpfPath
      );


  finally

    Zip.Free;

  end;

end;

function TTestDockForm.FindOpfPath(
  Zip: TZipFile
): string;

var
  Index: Integer;
  S: TStream;
  H: TZipHeader;
  Text: TStringStream;
  XmlText: string;
  P1,P2: Integer;

begin

  Result := '';

  Index :=
    Zip.IndexOf(
      'META-INF/container.xml'
    );


  if Index < 0 then
    raise Exception.Create(
      '找不到 META-INF/container.xml'
    );


  Zip.Read(Index,S,H);

  try

    Text :=
      TStringStream.Create(
        '',
        TEncoding.UTF8
      );

    try

      Text.CopyFrom(S,0);

      XmlText :=
        Text.DataString;


      P1 :=
        Pos(
          'full-path="',
          XmlText
        );


      if P1 = 0 then
        raise Exception.Create(
          'container.xml中没有full-path'
        );


      P1 :=
        P1 +
        Length(
          'full-path="'
        );


      P2 :=
        PosEx(
          '"',
          XmlText,
          P1
        );


      Result :=
        Copy(
          XmlText,
          P1,
          P2-P1
        );


    finally

      Text.Free;

    end;


  finally

    S.Free;

  end;


end;

function TTestDockForm.ParseOpfAndLoadText(
  Zip: TZipFile;
  const OpfPath: string
): string;

var
  Index: Integer;

  S: TStream;
  H: TZipHeader;

  Stream: TStringStream;

  OpfText: string;

  Manifest:
    TDictionary<string,string>;

  Spine:
    TList<string>;

  ItemID: string;
  Href: string;

  FullPath: string;

  I: Integer;

  Html: string;

  Chapter: TBookChapter;

  Reg: TRegEx;

  M: TMatch;

begin

  Result := '';


  Manifest :=
    TDictionary<string,string>.Create;

  Spine :=
    TList<string>.Create;


  try


    //=========================
    // 读取 content.opf
    //=========================

    Index :=
      Zip.IndexOf(
        OpfPath
      );


    if Index < 0 then
      raise Exception.Create(
        '找不到OPF文件: ' + OpfPath
      );


    Zip.Read(
      Index,
      S,
      H
    );


    try

      Stream :=
        TStringStream.Create(
          '',
          TEncoding.UTF8
        );

      try

        Stream.CopyFrom(S,0);

        OpfText :=
          Stream.DataString;

      finally

        Stream.Free;

      end;


    finally

      S.Free;

    end;



    //=========================
    // 解析manifest
    //=========================

    Reg :=
    TRegEx.Create(
      '<[\w:]*item\b([^>]*)>'
    );;


    for M in Reg.Matches(OpfText) do
    begin

      var Attr :=
        M.Groups[1].Value;


      var IDMatch :=
        TRegEx.Match(
          Attr,
          'id\s*=\s*["'']([^"'']+)["'']'
        );


      var HrefMatch :=
        TRegEx.Match(
          Attr,
          'href\s*=\s*["'']([^"'']+)["'']'
        );


      if IDMatch.Success and
         HrefMatch.Success then
      begin

        Manifest.Add(
          IDMatch.Groups[1].Value,
          HrefMatch.Groups[1].Value
        );

      end;

    end;



    //=========================
    // 解析spine
    //=========================

    Reg :=
    TRegEx.Create(
      '<[\w:]*itemref\b([^>]*)>'
    );

    for M in Reg.Matches(OpfText) do
    begin

      var Attr :=
        M.Groups[1].Value;


      var IDRefMatch :=
        TRegEx.Match(
          Attr,
          'idref\s*=\s*["'']([^"'']+)["'']'
        );


      if IDRefMatch.Success then
      begin

        Spine.Add(
          IDRefMatch.Groups[1].Value
        );

      end;

    end;



    //=========================
    // 按阅读顺序加载章节
    //=========================

    for I := 0 to Spine.Count - 1 do
    begin

      ItemID :=
        Spine[I];


      if not Manifest.TryGetValue(
        ItemID,
        Href
      ) then
        Continue;



     FullPath :=
        Copy(
          OpfPath,
          1,
          LastDelimiter('/', OpfPath)
        )
        +
        Href;


      FullPath :=
        StringReplace(
          FullPath,
          '\',
          '/',
          [rfReplaceAll]
        );

      Index :=
        Zip.IndexOf(
          FullPath
        );


      if Index < 0 then
      begin
        ShowMessage(
          '找不到:' + FullPath
        );
        Continue;
      end;



      Zip.Read(
        Index,
        S,
        H
      );


      try

        Stream :=
          TStringStream.Create(
            '',
            TEncoding.UTF8
          );


        try

          Stream.CopyFrom(S,0);

          Html :=
            Stream.DataString;


        finally

          Stream.Free;

        end;


      finally

        S.Free;

      end;



      // 去除html标签

      Html :=
        TRegEx.Replace(
          Html,
          '<[^>]+>',
          ''
        );



      Chapter.Title :=
        '';


      SplitChapters(
        Html,
        Href,
        Result
      );


    end;

    if FChapters.Count = 0 then
      raise Exception.Create(
        '没有解析到章节'
      );


  finally

    Manifest.Free;

    Spine.Free;

  end;

end;

procedure TTestDockForm.BuildChapterPages(
  Index: Integer
);
begin

  if Index < 0 then
    Exit;

  if Index >= FChapters.Count then
    Exit;


  FCurrentChapter := Index;


  FPageStarts.Clear;


  FPageStarts.Add(
    FChapters[Index].StartPos
  );


  FCurrentPage := 0;


  CalcCurrentPage;

end;

// 上一章
procedure TTestDockForm.ActionPrevExecute(Sender: TObject);
begin
  if FCurrentChapter <= 0 then
    Exit;

  JumpToChapter(
    FCurrentChapter - 1
  );
end;

// 上一页
procedure TTestDockForm.ActionPrevPageExecute(Sender: TObject);
begin

  if FCurrentPage > 0 then
  begin
    Dec(FCurrentPage);
  end

  else
  begin

    if FCurrentChapter > 0 then
    begin

      BuildChapterPages(
        FCurrentChapter - 1
      );

      // 不再跳最后一页
      // 因为现在没有提前计算全部分页

    end
    else
      Exit;

  end;


  CalcCurrentPage;

  PaintBox1.Invalidate;

end;

procedure TTestDockForm.ActionSCExecute(Sender: TObject);
begin
  FChapterVisible :=
    not FChapterVisible;
  ChapterPanel.Visible :=
    FChapterVisible;
end;

constructor TTestDockForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  GTestDockForm := Self;

  FChapters := TList<TBookChapter>.Create;
  FPageStarts := TList<Integer>.Create;

  FReadingState := TReadingState.Create;

  FReaderColor := TReaderColor.Create;

  FPageWidth := ScrollBox1.ClientWidth;
  FPageHeight := ScrollBox1.ClientHeight;

  ScrollBox1.Color :=
  StyleServices.GetSystemColor(clBtnFace);

  FBookText := '';

  DeskSection := 'TestDockSection';

  AutoSave := True;
  SaveStateNecessary := True;

  Caption := 'Test Dock Window';
end;

// 绘制页面
procedure TTestDockForm.PaintBox1Paint(Sender: TObject);
var
  R: TRect;
  S: string;
begin
  PaintBox1.Color := StyleServices.GetSystemColor(clWindow);

  PaintBox1.Canvas.Font.Color := FReaderColor.FontColor;

  if FBookText = '' then
    Exit;
  PaintBox1.Canvas.Brush.Style := bsClear;
  SetBkMode(
    PaintBox1.Canvas.Handle,
    TRANSPARENT
  );
  R := PaintBox1.ClientRect;
  InflateRect(
    R,
    -PAGE_MARGIN,
    -PAGE_MARGIN
  );
  // 给页码留空间
  Dec(
    R.Bottom,
    PAGE_FOOTER_HEIGHT
  );
  S := Copy(
    FBookText,
    FCurrentStart,
    FCurrentEnd - FCurrentStart + 1
  );
  DrawText(
    PaintBox1.Canvas.Handle,
    PChar(S),
    Length(S),
    R,
    DT_WORDBREAK or DT_NOPREFIX
  );
  PaintBox1.Canvas.TextOut(
    PAGE_MARGIN,
    PaintBox1.Height -
    PaintBox1.Canvas.TextHeight('A') -
    PAGE_MARGIN,
    Format(
      'Page %d',
      [FCurrentPage + 1]
    )
  );
end;

function TTestDockForm.FitTextToPage(
  const AText: string;
  StartPos: Integer
): Integer;
var
  Low: Integer;
  High: Integer;
  Mid: Integer;
  Best: Integer;
  RemainingChars: Integer;
begin
  RemainingChars :=
    Length(AText) - StartPos + 1;

  Low := 1;
  High := Min(5000, RemainingChars);

  Best := 1;

  while Low <= High do
  begin
    Mid := (Low + High) div 2;

    if TextFitsPage(
         AText,
         StartPos,
         Mid
       ) then
    begin
      Best := Mid;
      Low := Mid + 1;
    end
    else
      High := Mid - 1;
  end;

  Result :=
    StartPos + Best - 1;
end;


//{快捷键绑定}
//procedure TTestDockForm.FormKeyDown(Sender: TObject; var Key: Word;
//  Shift: TShiftState);
//begin
//  if Key = VK_LEFT then
//    ActionPrevPage.Execute
//  else if Key = VK_RIGHT then
//    ActionNextPage.Execute
//  else if Key = VK_UP then
//    ActionPrev.Execute
//  else if Key = VK_DOWN then
//    ActionNext.Execute
//end;

//procedure TTestDockForm.FormResize(Sender: TObject);
//begin
//  if FPageStarts.Count = 0 then
//    Exit;
//
//  CalcCurrentPage;
//  PaintBox1.Invalidate;
//end;

function TTestDockForm.TextFitsPage(
  const AText: string;
  StartPos: Integer;
  CharCount: Integer
): Boolean;
const
  PAGE_MARGIN = 2;
  PAGE_FOOTER_HEIGHT = 40;
var
  R: TRect;
  MaxBottom: Integer;
begin
  R := Rect(
    0,
    0,
    FPageWidth,
    FPageHeight
  );

  InflateRect(
    R,
    -PAGE_MARGIN,
    -PAGE_MARGIN
  );

  Dec(
    R.Bottom,
    PAGE_FOOTER_HEIGHT
  );

  MaxBottom := R.Bottom;

  DrawText(
    PaintBox1.Canvas.Handle,
    PChar(AText) + StartPos - 1,
    CharCount,
    R,
    DT_WORDBREAK or
    DT_CALCRECT or
    DT_NOPREFIX
  );

  Result := R.Bottom <= MaxBottom;
end;

procedure TTestDockForm.CalcCurrentPage;
begin
  FCurrentStart :=
    FPageStarts[FCurrentPage];

  FCurrentEnd :=
    FitTextToPage(
      FBookText,
      FCurrentStart
    );
end;

procedure TTestDockForm.ChapterListClick(Sender: TObject);
begin
  if ChapterList.ItemIndex>=0 then
  begin
    JumpToChapter(
      ChapterList.ItemIndex
    );
    ChapterPanel.Visible:=False;
    FChapterVisible:=False;
  end;
end;

destructor TTestDockForm.Destroy;
begin
  if GTestDockForm = Self then
    GTestDockForm := nil;

  FReadingState.Free;

  FReaderColor.Free;

  FPageStarts.Free;

  FChapters.Free;

  inherited;
end;

function GetTestDockForm:TTestDockForm;
begin
  Result := GTestDockForm;
end;


end.
