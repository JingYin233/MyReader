unit uReaderColor;

interface

uses
  System.Classes, Vcl.Graphics, Vcl.Dialogs;

type
  TReaderColor = class
  private
    FFontColor: TColor;

  public
    constructor Create;

    procedure SetFontColor(const AColor: TColor);

    procedure SelectFontColor;

    property FontColor: TColor read FFontColor;

  end;

implementation

constructor TReaderColor.Create;
begin

  FFontColor := clWindowText;

end;

procedure TReaderColor.SetFontColor(const AColor: TColor);
begin

  FFontColor := AColor;

end;

procedure TReaderColor.SelectFontColor;
var
  Dlg: TColorDialog;
begin

  Dlg := TColorDialog.Create(nil);

  try

    Dlg.Color := FFontColor;

    if Dlg.Execute then
    begin

      FFontColor := Dlg.Color;

    end;

  finally

    Dlg.Free;

  end;

end;

end.

