program Connexion;

uses
  Forms,
  Conx1 in 'Conx1.pas' {V5},
  Conx3 in 'Conx3.pas' {FOptions},
  Conx2 in 'Conx2.pas',
  Ufinjeu in 'Ufinjeu.pas' {DlgFin},
  Conx4 in 'Conx4.pas' {Scores},
  Conx5 in 'Conx5.pas' {FAide};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TV5, V5);
  Application.CreateForm(TFOptions, FOptions);
  Application.CreateForm(TDlgFin, DlgFin);
  Application.CreateForm(TScores, Scores);
  Application.CreateForm(TFAide, FAide);
  Application.Run;
end.
