unit Conx3;      // Gestion des options

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TFOptions = class(TForm)
    CBcajou: TCheckBox;
    Button1: TButton;
    GB2: TGroupBox;
    Image2: TImage;
    RB21: TRadioButton;
    RB22: TRadioButton;
    GB1: TGroupBox;
    Image1: TImage;
    RB11: TRadioButton;
    RB12: TRadioButton;
    RB13: TRadioButton;
    procedure RB11Click(Sender: TObject);
    procedure RB21Click(Sender: TObject);
    procedure PoseNoca(n : integer);
    procedure PoseRbcol(n : integer);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  FOptions: TFOptions;
  noca : integer = 2;
  rbCol : integer = 1;

implementation

{$R *.dfm}

procedure TFOptions.RB11Click(Sender: TObject);
var nc : integer;
begin
  nc := (sender as TRadioButton).Tag;
  PoseNoca(nc);
end;

procedure TFOptions.PoseNoca(n : integer);
begin
  case n of
    1 : begin
          RB11.Checked := true;
          RB12.Checked := false;
          RB13.Checked := false;
          noca := 2;
        end;
    2 : begin
          RB11.Checked := false;
          RB12.Checked := true;
          RB13.Checked := false;
          noca := 3;
        end;
    3 : begin
          RB11.Checked := false;
          RB12.Checked := false;
          RB13.Checked := true;
          noca := 4;
        end;
  end;
end;

procedure TFOptions.RB21Click(Sender: TObject);
var nc : integer;
begin
  nc := (sender as TRadioButton).Tag;
  PoseRbcol(nc);
end;

procedure TFOptions.PoseRbcol(n : integer);
begin
  case n of
    1 : begin
          RB22.Checked := false;
          RB21.Checked := true;
          rbCol := 1;
        end;
    2 : begin
          RB21.Checked := false;
          RB22.Checked := true;
          rbCol := 2;
        end;
  end;
end;

end.
