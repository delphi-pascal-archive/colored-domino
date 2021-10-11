unit Conx4;    // Gestion des scores

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IniFiles, StdCtrls, ExtCtrls;

type
  tsco = record
           nom : string[8];
           val : integer;
         end;
  TScores = class(TForm)
    Image1: TImage;
    LBnom: TListBox;
    LBval: TListBox;
    BFerme: TButton;
    procedure Ouvre;
    procedure Charge;
    procedure Affiche;
    procedure Marque(va : integer; nom : string);
    procedure Sauve;
    procedure BFermeClick(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

const
  nomf = 'Connexion.sco';

var
  Scores: TScores;
  Fscore: File of tsco;
  inter : tsco;
  tbsco : array[0..9] of tsco;
  i,
  nbno : integer;

implementation

{$R *.DFM}

procedure Tri;
var  i,fin : byte;
begin
  repeat
    fin := 0;
    for i := 1 to 9 do
    begin
      if tbsco[i].val > tbsco[i-1].val then
      begin
        inter := tbsco[i-1];
        tbsco[i-1] := tbsco[i];
        tbsco[i] := inter;
        fin := 1;
      end;
    end;
  until fin = 0;
end;

procedure Tscores.Ouvre;
var  i : byte;
begin
  AssignFile(Fscore,nomf);
  Rewrite(Fscore,nomf);
  for i := 0 to 9 do Write(Fscore,tbsco[i]);
  CloseFile(Fscore);
  Affiche;
end;

procedure Tscores.Charge;
var  i : byte;
begin
  inter.nom := ' ';
  inter.val := 0;
  for i := 0 to 9 do tbsco[i] := inter;
  AssignFile(Fscore,nomf);
  {$I-}
    Reset(Fscore);
  {$I+}
  if IOResult <> 0 then Ouvre
  else
    begin
      i := 0;
      while not Eof(Fscore) do
      begin
        Read(Fscore,tbsco[i]);
        inc(i);
      end;
      Affiche;
      CloseFile(Fscore);
    end;
end;

procedure Tscores.Affiche;
var  i : byte;
begin
  LBnom.Clear;
  LBval.Clear;
  for i := 0 to 9 do
  begin
    LBnom.Items.Add(tbsco[i].nom);
    LBval.Items.Add(IntToStr(tbsco[i].val));
  end;
end;

procedure Tscores.Marque(va : integer; nom : string);
begin
  if va > tbsco[9].val then
  begin
    tbsco[9].nom := nom;
    tbsco[9].val := va;
    Tri;
  end;
  Affiche;
end;

procedure Tscores.Sauve;
var  i : byte;
begin
  AssignFile(Fscore,nomf);
  Rewrite(Fscore);
  for i := 0 to 9 do Write(Fscore,tbsco[i]);
  CloseFile(Fscore);
end;

procedure TScores.BFermeClick(Sender: TObject);
begin
  Close;
end;

end.
