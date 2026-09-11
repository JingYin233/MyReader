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
  TestDockForm: TTestDockForm = nil;
  ReaderKeyboardBinding: TReaderKeyboardBinding = nil;
  TestMenuItem: TMenuItem = nil;



procedure CreateTestDockForm;
begin
  if not Assigned(TestDockForm) then
  begin
    TestDockForm :=
      TTestDockForm.Create(nil);

    RegisterFieldAddress(
      'TestDockForm',
      @TestDockForm
    );
  end;
end;



class procedure TTestMenu.OpenTestDock(Sender: TObject);
begin
  CreateTestDockForm;

  ShowDockableForm(
    TestDockForm
  );
end;



procedure AddTestMenu;
var
  Services: INTAServices;
  ViewMenu: TMenuItem;

begin

  Services :=
    BorlandIDEServices as INTAServices;


  ViewMenu :=
    Services.MainMenu.Items.Find('View');


  if Assigned(ViewMenu) then
  begin

    if Assigned(TestMenuItem) then
      Exit;


    TestMenuItem :=
      TMenuItem.Create(ViewMenu);


    TestMenuItem.Caption :=
      'Test Dock';


    TestMenuItem.OnClick :=
      TTestMenu.OpenTestDock;


    ViewMenu.Add(
      TestMenuItem
    );

  end;

end;



procedure RegisterReaderKeyboard;
var
  KS: IOTAKeyboardServices;

begin

  if Supports(
       BorlandIDEServices,
       IOTAKeyboardServices,
       KS)
  then
  begin

    if not Assigned(ReaderKeyboardBinding) then
    begin

      ReaderKeyboardBinding :=
        TReaderKeyboardBinding.Create;


      KS.AddKeyboardBinding(
        ReaderKeyboardBinding
      );

    end;

  end;

end;



procedure Register;

begin

  RegisterReaderKeyboard;

  AddTestMenu;

end;



procedure Cleanup;

begin

  //
  // 菜单由插件创建，需要释放
  //
  if Assigned(TestMenuItem) then
  begin

    TestMenuItem.Free;

    TestMenuItem := nil;

  end;


  //
  // 以下两个对象不要 Free
  //
  // BDS OTA 管理它们生命周期
  //
  ReaderKeyboardBinding := nil;

  TestDockForm := nil;

end;



initialization

  RegisterDesktopFormClass(
    TTestDockForm,
    'TestDockSection',
    'TestDockForm'
  );



finalization

  Cleanup;



end.
