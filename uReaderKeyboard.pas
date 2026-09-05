unit uReaderKeyboard;

interface

uses
  ToolsAPI,
  Vcl.Menus,
  System.Classes,
  Winapi.Windows,
  Vcl.Dialogs,
  TestDockForm;

type

  TReaderKeyboardBinding = class(
    TNotifierObject,
    IOTAKeyboardBinding
  )
  public

    procedure BindKeyboard(
      const BindingServices: IOTAKeyBindingServices
    );

    function GetBindingType: TBindingType;

    function GetDisplayName: string;

    function GetName: string;

    procedure NextPage(
      const Context: IOTAKeyContext;
      KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult
    );

    procedure PrevPage(
      const Context: IOTAKeyContext;
      KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult
    );
    procedure NextChapter(
      const Context: IOTAKeyContext;
      KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult
    );
    procedure PrevChapter(
      const Context: IOTAKeyContext;
      KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult
    );

  end;


implementation


procedure TReaderKeyboardBinding.BindKeyboard(
  const BindingServices: IOTAKeyBindingServices);
begin

  OutputDebugString(
    'BindKeyboard'
  );


  BindingServices.AddKeyBinding(
    [TextToShortCut('Ctrl+Right')],
    NextPage,
    nil
  );

  BindingServices.AddKeyBinding(
    [TextToShortCut('Ctrl+Left')],
    PrevPage,
    nil
  );

  BindingServices.AddKeyBinding(
    [TextToShortCut('Ctrl+Up')],
    PrevChapter,
    nil
  );

  BindingServices.AddKeyBinding(
    [TextToShortCut('Ctrl+Down')],
    NextChapter,
    nil
  );

end;



procedure TReaderKeyboardBinding.NextPage(
  const Context: IOTAKeyContext;
  KeyCode: TShortcut;
  var BindingResult: TKeyBindingResult);
var
  Form: TTestDockForm;
begin

  Form := GetTestDockForm;

  if Assigned(Form) then
    Form.NextPage;

  BindingResult := krHandled;

end;


procedure TReaderKeyboardBinding.PrevPage(
  const Context: IOTAKeyContext;
  KeyCode: TShortcut;
  var BindingResult: TKeyBindingResult);
var
  Form: TTestDockForm;
begin
  Form := GetTestDockForm;
  if Assigned(Form) then
    Form.PrevPage;
  BindingResult := krHandled;
end;


procedure TReaderKeyboardBinding.NextChapter(
  const Context: IOTAKeyContext;
  KeyCode: TShortcut;
  var BindingResult: TKeyBindingResult);
var
  Form: TTestDockForm;
begin
  Form := GetTestDockForm;

  if Assigned(Form) then
    Form.NextChapter;

  BindingResult := krHandled;
end;


procedure TReaderKeyboardBinding.PrevChapter(
  const Context: IOTAKeyContext;
  KeyCode: TShortcut;
  var BindingResult: TKeyBindingResult);
var
  Form: TTestDockForm;
begin
  Form := GetTestDockForm;

  if Assigned(Form) then
    Form.PrevChapter;

  BindingResult := krHandled;
end;


function TReaderKeyboardBinding.GetBindingType:
TBindingType;
begin
  Result :=
    btPartial;
end;


function TReaderKeyboardBinding.GetDisplayName:
string;
begin
  Result :=
    'Reader Keyboard';
end;


function TReaderKeyboardBinding.GetName:
string;
begin
  Result :=
    'ReaderKeyboardBinding';
end;


end.
