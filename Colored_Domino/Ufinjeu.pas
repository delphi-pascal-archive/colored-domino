unit Ufinjeu;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

type
  TDlgFin = class(TForm)
    OKBtn: TButton;
    PnFin: TPanel;
    Ima1: TImage;

    procedure Affiche(jr : string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DlgFin: TDlgFin;

implementation

{$R *.DFM}

procedure TDlgFin.Affiche(jr : string);
begin
  DlgFin.Color := clYellow;
  PnFin.Caption := jr;
end;

end.
