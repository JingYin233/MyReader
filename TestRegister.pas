unit TestRegister;

interface

procedure Register;

implementation

uses
  System.Classes,
  System.SysUtils,
  Vcl.Menus,
  ToolsAPI,
  TestDockForm,
  DeskForm,
  DeskUtil,
  uReaderKeyboard;


type
  TTestMenu = class
  public
    class procedure OpenTestDock(Sender: TObject);
  end;


var
  TestDockForm: TTestDockForm;
  ReaderKeyboardBinding: TReaderKeyboardBinding;

procedure CreateTestDockForm;
begin
  if not Assigned(TestDockForm) then
  begin
    TestDockForm := TTestDockForm.Create(nil);
    RegisterFieldAddress(
      'TestDockForm',
      @TestDockForm
    );
  end;
end;

class procedure TTestMenu.OpenTestDock(Sender: TObject);
begin
  CreateTestDockForm;
  ShowDockableForm(TestDockForm);
end;


procedure AddTestMenu;
var
  Services: INTAServices;
  ViewMenu: TMenuItem;
  Item: TMenuItem;
begin
  Services := BorlandIDEServices as INTAServices;

  ViewMenu := Services.MainMenu.Items.Find('View');

  if Assigned(ViewMenu) then
  begin
    Item := TMenuItem.Create(ViewMenu);

    Item.Caption := 'Test Dock';
    Item.OnClick := TTestMenu.OpenTestDock;

    ViewMenu.Add(Item);
  end;
end;


procedure Register;
var
  KS:IOTAKeyboardServices;
begin

  if Supports(
      BorlandIDEServices,
      IOTAKeyboardServices,
      KS)
  then
  begin

    ReaderKeyboardBinding :=
      TReaderKeyboardBinding.Create;

    KS.AddKeyboardBinding(
      ReaderKeyboardBinding
    );

  end;


  CreateTestDockForm;

  AddTestMenu;

end;


initialization

  RegisterDesktopFormClass(
  TTestDockForm,
  'TestDockSection',
  'TestDockForm'
);

end.
