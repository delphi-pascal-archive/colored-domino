unit Conx1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Jpeg, ExtCtrls, StdCtrls, Buttons, ImgList,
  Conx2, Conx3, Conx4, Conx5, UFinJeu;

type
  TV5 = class(TForm)
    Plato: TImage;
    Titre: TImage;
    SBNouveau: TSpeedButton;
    SBQuitter: TSpeedButton;
    SBOptions: TSpeedButton;
    Nom1: TPanel;
    Nom2: TPanel;
    SBAnnule: TSpeedButton;
    SBValide: TSpeedButton;
    ImaList: TImageList;
    Lab: TLabel;
    PList: TImageList;
    Point1: TPanel;
    Point2: TPanel;
    PMess: TPanel;
    BtSOS: TBitBtn;
    Dom1: TImage;
    Dom2: TImage;
    Dom3: TImage;
    Dom4: TImage;
    Dom5: TImage;
    Dom6: TImage;
    Dom7: TImage;
    Dom8: TImage;
    Dom9: TImage;
    Dom10: TImage;
    Dom11: TImage;
    Dom12: TImage;
    Dom13: TImage;
    Dom14: TImage;
    Dom15: TImage;
    Dom16: TImage;
    Dom17: TImage;
    Dom18: TImage;
    Dom19: TImage;
    Dom20: TImage;
    Dom21: TImage;
    Dom22: TImage;
    Dom23: TImage;
    Dom24: TImage;
    Dom25: TImage;
    Dom26: TImage;
    Dom27: TImage;
    Dom28: TImage;
    Dom29: TImage;
    Dom30: TImage;
    ImaListv: TImageList;
    SBScore: TSpeedButton;
    SBAide: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Initialise;
    procedure PMessage(txt : string);
    procedure PeintCadre(ss,c1,c2 : byte);
    procedure SBNouveauClick(Sender: TObject);
    procedure SBQuitterClick(Sender: TObject);
    procedure SBOptionsClick(Sender: TObject);
    procedure Nom1Click(Sender: TObject);
    procedure SBAnnuleClick(Sender: TObject);
    procedure SBValideClick(Sender: TObject);
    procedure JeuHum;
    procedure JeuOrdi;
    procedure AffLab(x,y : integer);
    procedure DomMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DomMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure DomMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PlatoMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Passer;
    procedure Finjeu;
    procedure Nom2Click(Sender: TObject);
    procedure BtSOSClick(Sender: TObject);
    function  Domino(no : byte) : TImage;
    procedure Deplace(no : byte; x,y : integer);
    procedure Pivoter(no : byte);
    procedure Retour(no : byte);
    procedure SauveJeu;
    procedure RestoreJeu;
    procedure FormActivate(Sender: TObject);
    procedure SBScoreClick(Sender: TObject);
    procedure SBAideClick(Sender: TObject);
  end;
var
  V5 : TV5;
  chemin : string;

implementation

{$R *.dfm}

var
  rond,
  vide,
  cadre : TBitmap;
  d1,d2 : byte;
  bjex : boolean = false;    // dominos existent si true
  bron : boolean = false;    // affichage des indications si true
  bdeb : boolean = false;    // une partie est commencée
  movok : boolean = false;
  ex,ey : integer;
  posok : boolean;
  bpass : array[1..2] of byte;
  nbDom : array[1..2] of byte;  // nbre de dominos restants

procedure TV5.FormCreate(Sender: TObject);
var  i,x,y : integer;
begin
  Randomize;
  DoubleBuffered := true;
  chemin := ExtractFilePath(Application.ExeName);
  for y := 0 to 13 do
    for x := 0 to 8 do
      Imalist.Draw(Plato.Canvas,x*60,y*30,0);
  Plato.Canvas.Brush.Color := clGray;
  Plato.Canvas.FrameRect(Rect(0,0,540,420));
  rond := TBitmap.Create;
  PList.GetBitmap(5,rond);
  vide := TBitmap.Create;
  PList.GetBitmap(6,vide);
  for i := 1 to 5 do
    tbcol[i] := tbTeint[rbcol,i];
end;

procedure TV5.FormActivate(Sender: TObject);
begin                               
  Scores.Charge;
  if FileExists(nsa) then RestoreJeu;
end;

procedure TV5.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  vide.Free;
  rond.Free;
end;

procedure TV5.SBQuitterClick(Sender: TObject);
begin
  Scores.Sauve;
  SauveJeu;
  Close;
end;

procedure TV5.PMessage(txt : string);
begin
  Pmess.Caption := txt;
  Pmess.Visible := true;
  PMess.Repaint;
  Beep;
  Sleep(2000);
  Pmess.Visible := false;
end;

// Dessin des dominos
procedure TV5.PeintCadre(ss,c1,c2 : byte);
begin
  cadre := TBitmap.Create;
  if ss = 1 then
  begin
    cadre.Width := 60;
    cadre.Height := 30;
    ImaList.GetBitmap(noca,cadre);
    if noca = 4 then
    begin
      PList.Draw(cadre.Canvas,2,2,c1-1);
      PList.Draw(cadre.Canvas,32,2,c2-1);
      exit;
    end;
    cadre.Canvas.Brush.Color := tbcol[c1];
    cadre.Canvas.FloodFill(15,15,clBlack,fsBorder);
    cadre.Canvas.Brush.Color := tbcol[c2];
    cadre.Canvas.FloodFill(45,15,clBlack,fsBorder);
  end
  else
    begin
      cadre.Width := 30;
      cadre.Height := 60;
      ImaListv.GetBitmap(noca-2,cadre);
      if noca = 4 then
      begin
        PList.Draw(cadre.Canvas,2,2,c1-1);
        PList.Draw(cadre.Canvas,2,32,c2-1);
        exit;
      end;
      cadre.Canvas.Brush.Color := tbcol[c1];
      cadre.Canvas.FloodFill(15,15,clBlack,fsBorder);
      cadre.Canvas.Brush.Color := tbcol[c2];
      cadre.Canvas.FloodFill(15,45,clBlack,fsBorder);
    end;
end;

procedure TV5.Initialise;
var  i : byte;
begin                                  
  if bjex then             // Remet les dominos à leur place d'origine
    for i := 1 to 30 do
      with tbDom[i] do
      begin
        if fSens = 2 then Pivoter(i);
        Domino(i).Left := fOrx;
        Domino(i).Top := fOry;
      end;
   for i := 1 to 30 do
   begin
     PeintCadre(1,tbCoul[i,1],tbCoul[i,2]);
     Domino(i).Picture.Bitmap := cadre;
     cadre.Free;
     tbDom[i].fCas1 := tbCoul[i,1];
     tbDom[i].fCas2 := tbCoul[i,2];
     tbDom[i].fPaire := tbCoul[i,1] * 10 + tbCoul[i,2];
  end;
  bjex := true;
  bpass[1] := 0;
  bpass[2] := 0;
  bfin := false;
  nbDom[1] := 14;
  nbDom[2] := 14;                     
end;

// démarrage d'une partie
procedure TV5.SBNouveauClick(Sender: TObject);
var  i : byte;
     x,y : integer;
     ok : boolean;
begin                      
  initialise;
  for x := 0 to 19 do
  begin
    tablo[x,0] := 9;
    tablo[x,15] := 9;
  end;
  for y := 1 to 14 do
  begin
    tablo[0,y] := 9;
    tablo[14,y] := 9;
  end;
  for x := 1 to 18 do
    for y := 1 to 14 do tablo[x,y] := 0;
  for x := 1 to 18 do
    for y := 1 to 14 do
      Plato.Canvas.Draw((x-1)*30+2,(y-1)*30+2,vide);
  for i := 1 to 30 do
    with tbDom[i] do
    begin
      fOrx := Domino(i).Left;
      fOry := Domino(i).Top;
      fBlock := false;
      fSens := 1;
      dojou[i] := 0;
    end;
  njo := 0;
  domi := 15;
  points[1] := 0;
  points[2] := 0;
  Point1.Caption := '0';
  Point2.Caption := '0';
  EffaceTablP;
  d1 := Random(15)+1;     // choix des dominos de début de jeu
  repeat
    ok := true;
    d2 := Random(15)+16;
    if ((tbDom[d1].fCas1 = tbDom[d1].fCas2) and
        (tbDom[d2].fCas1 = tbDom[d2].fCas2))
    or ((tbDom[d1].fCas1 = tbDom[d2].fCas1) and
        (tbDom[d1].fCas2 = tbDom[d2].fCas2))
    or ((tbDom[d1].fCas1 = tbDom[d1].fCas2) and
        ((tbDom[d1].fCas1 = tbDom[d2].fCas1) or (tbDom[d1].fCas1 = tbDom[d2].fCas2)))
    or ((tbDom[d2].fCas1 = tbDom[d2].fCas2) and
        ((tbDom[d2].fCas1 = tbDom[d1].fCas1) or (tbDom[d2].fCas1 = tbDom[d1].fCas2)))
    then ok := false;
  until ok;
  Deplace(d1,390,240);
  tbDom[d1].fBlock := true;
  tablo[9,7] := tbDom[d1].fCas1;
  tablo[10,7] := tbDom[d1].fCas2;
  tablP[9,7] := 1;
  Deplace(d2,390,270);
  tbDom[d2].fBlock := true;
  tablo[9,8] := tbDom[d2].fCas1;
  tablo[10,8] := tbDom[d2].fCas2;
  tablP[9,8] := 1;
  joueur := Random(2)+1;           // choix du joueur qui commence
  prem := joueur;
  bdeb := true;
  if joueur = 1 then JeuHum
  else JeuOrdi;
end;

procedure TV5.JeuHum;    //------------------------------------------------
var i : byte;
    ax,ay : integer;
begin
  if bfin then exit;
  joueur := 1;
  posok := false;
  Nom2.Color := $00FFDDCC;
  Nom1.Color := clYellow;
  SetLength(tbok,0);
  nbok := 0;
  TestCases;
  if nbok = 0 then
  begin
    PMessage('Vous ne pouvez plus jouer...');
    PMessage('Vous passez !');
    Passer;
  end
  else
  begin
    bpass[1] := 0;
    if bron then
      for i := 0 to nbok-1 do
      begin
        with tbok[i] do
        begin
          ax := (px-1) * 30;
          ay := (py-1) * 30;
          Plato.Canvas.Draw(ax+2,ay+2,rond);
        end;
      end;
  end;
end;

// Choix d'un domino
procedure TV5.DomMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var  no : byte;
begin
  if not bval then
  begin
    Pmessage('Il faut valider ou annuler!');
    exit;
  end;
  no := (sender as TImage).Tag;
  if (no > 15)
  or (tbDom[no].fBlock) then exit;
  if Button = mbRight then
    with Domino(no) do
    begin
      if (Left < Plato.Left) or (Left > Plato.Left+Plato.Width)
      or (Top < Plato.Top) or (Top > Plato.Top+Plato.Height) then Exit;
      Pivoter(no);
      asn := tbDom[no].fsens;
      Exit;
    end;
  domi := no;
  if njo = 0 then
  begin
    inc(njo);
    dojou[njo] := domi;
  end
  else if no <> dojou[njo] then
       begin
         tbDom[dojou[njo]].fBlock := true;    // on bloque le domino précédent
         inc(njo);
         dojou[njo] := domi;
       end;
  Domino(domi).BringToFront;
  ex := x;
  ey := y;
  movok := true;
end;

procedure TV5.DomMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if movok then
    with Domino(domi) do
    begin
      Left := Left + X - ex;
      Top := Top + y - ey;
    end;
end;

procedure TV5.DomMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if movok then
    with Domino(domi) do
    begin
      if (Left < Plato.Left) or (Left > Plato.Left+Plato.Width)
      or (Top < Plato.Top) or (Top > Plato.Top+Plato.Height) then
        SBAnnuleClick(self);
    end;
  movok := false;
end;

// Mise en place du domino, contrôle et rejet éventuel
procedure TV5.PlatoMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var  px,py : integer;
begin                               
  if Button = mbRight then
  begin
//    AffLab(X,Y);
    Exit;
  end;
  if domi > 0 then
  begin
    with Domino(domi) do
    begin
      px := (Left + 15) div 30 * 30;
      py := (Top + 15) div 30 * 30;
      casx := (px - 150) div 30 + 1;
      casy := (py - 60) div 30 + 1;
      if ControlDomino(casx,casy) then
      begin
        Left := px;
        Top := py;
        posok := true;
        bval := false;
      end
      else PMessage('Ce n''est pas le bon');
    end;
  end;  
end;

// Validation du coup joué
procedure TV5.SBValideClick(Sender: TObject);
var  x,y : integer;
begin                                 
  if not posok then
  begin
    PMessage('Pas de pièce jouée!');
    exit;
  end;
  with tbDom[domi] do
  begin
    fBlock := true;
    tablo[casx,casy] := fCas1;      // Mise à jour du tableau de jeu
    tablP[casx,casy] := fSens;      // Mise à jour du tableau des piles de 3
    if fSens = 1 then tablo[casx+1,casy] := fCas2
    else tablo[casx,casy+1] := fCas2;
  end;
  inc(points[1],pts);
  Point1.Caption := IntToStr(points[1]);
  Point1.Repaint;
  if bron then              // effacement des indications d'aide au jeu
    for x := 1 to 18 do
      for y := 1 to 14 do
        if tablo[x,y] = 0 then
          Plato.Canvas.Draw((x-1)*30+2,(y-1)*30+2,vide);
  Dec(nbdom[1]);
  bval := true;
  JeuOrdi;
end;

// Renvoie un domino en dehors de la grille de jeu
procedure TV5.SBAnnuleClick(Sender: TObject);
begin
  if njo = 0 then exit;
  posok := false;
  if domi = 0 then
    domi := dojou[njo];
  if tbDom[domi].fBlock then exit;
  Retour(domi);
  bval := true;
  dojou[njo] := 0;
  dec(njo);
  if njo > 0 then
  begin
    domi := dojou[njo];
    tbDom[domi].fBlock := false;
  end
  else domi := 0;
end;

// Le joueur passe (automatique)
procedure TV5.Passer;
begin
  if bpass[2] = 1 then FinJeu
  else
  begin
    bpass[1] := 1;
    JeuOrdi;
  end;
end;

// le programme joue à la place du joueur
procedure TV5.BtSOSClick(Sender: TObject);
var  x,y : integer;
     i,n : byte;
begin
  if not bval then
  begin
    Pmessage('Il faut valider le précédent!');
    exit;
  end;
  if nbok > 0 then
  begin
    n := Random(nbok);
    with tbok[n] do
    begin
      if ro > 0 then
        for i := 1 to ro do Pivoter(nd);
      x := (px-1) * 30 + 150;
      y := (py-1) * 30 + 60;
      casx := px;
      casy := py;
      Deplace(nd,x,y);
      domi := nd;
      posok := true;
      pts := 0;
    end;
    SBValideClick(self);
  end;
end;

procedure TV5.JeuOrdi;    //-------------------------------------------------
var  x,y : integer;
     i,n : byte;
begin
  if bfin then exit;
  bpass[2] := 0;
  joueur := 2;
  Nom1.Color := $00FFDDCC;
  Nom2.Color := clYellow;
  Nom2.Repaint;
  SetLength(tbok,0);
  nbok := 0;
  TestCases;
  if nbok = 0 then
  begin
    PMessage('Je ne peux pas jouer...');
    PMessage('Je passe !');
    if bpass[1] = 1 then      // si le joueur à également passé : fin du jeu
    begin
      FinJeu;
      exit;
    end
    else bpass[2] := 1;
  end
  else
  begin                      // pose d'un domino
    n := Random(nbok);
    with tbok[n] do
    begin
      if ro > 0 then
        for i := 1 to ro do Pivoter(nd);
      x := (px-1) * 30 + 150;
      y := (py-1) * 30 + 60;
      Deplace(nd,x,y);
      tbDom[nd].fBlock := true;
      tbDom[nd].fSens := sn;
      tablP[px,py] := tbDom[nd].fSens;
      tablo[px,py] := tbDom[nd].fCas1;
      if tbDom[nd].fSens = 1 then
        tablo[px+1,py] := tbDom[nd].fCas2
      else tablo[px,py+1] := tbDom[nd].fCas2;
      dec(nbdom[2]);
      inc(points[2],pt);
      Point2.Caption := IntToStr(points[2]);
      Point2.Repaint;
    end;
  end;                                
  JeuHum;
end;
//------------------------------------------------------------------------------
procedure TV5.SBOptionsClick(Sender: TObject);
var  i : byte;
begin
  FOptions.ShowModal;
  with FOptions do
  begin
    if CBCajou.Checked then bron := true else bron := false;
    for i := 1 to 5 do
      tbcol[i] := tbTeint[rbcol,i];
  end;
end;

procedure TV5.Nom1Click(Sender: TObject);
var  st : string;
begin
  st := InputBox('Identification du joueur','Donnez un nom','');
  if st = '' then exit;
  Nom1.Caption := st;
end;

procedure TV5.Nom2Click(Sender: TObject);
var  st : string;
begin
   st := InputBox('Identification de l''ordi','Donnez un nom','');
  if st = '' then exit;
  Nom2.Caption := st;
end;
//--------------------------------------------- Réservé aux tests
procedure TV5.AffLab(x,y : integer);
//var i : byte;
//    nx,ny : integer;
begin
{  nx := x div 30 + 1;
  ny := y div 30 + 1;
  for i := 0 to nbok-1 do
  begin
    if (nx = tbok[i].px) and (ny = tbok[i].py) then
      trace(tbok[i].pr,tbok[i].nd);
  end;   }
end;

procedure TV5.FinJeu;
var  i,n : byte;
begin                              
  for i := 1 to 15 do
  begin
    if tbDom[i].fBlock then n := 0
    else n := i;
    if n > 0 then
      with tbDom[n] do
        if fCas1 = fCas2 then dec(points[1],5)
        else dec(points[1],25);
  end;
  for i := 16 to 30 do
  begin
    if tbDom[i].fBlock then n := 0
    else n := i;
    if n > 0 then
      with tbDom[n] do
        if fCas1 = fCas2 then dec(points[2],5)
        else dec(points[2],25);
  end;      
  Point1.Caption := IntToStr(points[1]);
  Point1.Repaint;
  Point2.Caption := IntToStr(points[2]);
  Point2.Repaint;
  PMessage('Le jeu est terminé');
  if points[1] > points[2] then
  begin
    DlgFin.Affiche(Nom1.Caption+' gagne');
    Scores.Marque(points[1],Nom1.Caption);
  end
  else
    if points[2] > points[1] then
    begin
      DlgFin.Affiche(Nom2.Caption+' gagne');
      Scores.Marque(points[2],Nom2.Caption);
    end
      else DlgFin.Affiche('Match nul');
  DlgFin.ShowModal;
  bfin := true;
end;

//---------------------------------------- Gestion images Domino ---------------
function TV5.Domino(no : byte) : TImage;
begin
  Result := FindComponent('Dom'+ IntToStr(no)) as TImage;
end;

procedure TV5.Deplace(no : byte; x,y : integer);
var xo, yo,
    xd, yd,
    ix, iy, ic : integer;
begin             // déplacement glissé
  with Domino(no) do
  begin
  BringToFront;
  xo := Left;       // position initiale de la pièce
  yo := Top;
  xd := x;       // position finale
  yd := y;
  ic := 50;       // nbre de pas
  repeat
    ix := (xd-xo) div ic;
    iy := (yd-yo) div ic;
    xo := xo+ix;
    yo := yo+iy;
    Left := xo;              // on déplace la pièce
    Top := yo;
    Repaint;
    Parent.Refresh;
    dec(ic);
    sleep(10);
  until ic = 0;
  Left := x;
  Top := y;
  tbDom[no].fBlock := false;
  end;
end;

procedure TV5.Pivoter(no : byte);
var  n : byte;
begin
  case tbDom[no].fSens of
    1 : begin                     // horizontal -> vertcal
          Domino(no).Left := Domino(no).Left + 15;
          Domino(no).Top := Domino(no).Top - 15;
          tbDom[no].fSens := 2;
          Domino(no).Width := 30;
          Domino(no).Height := 60;
          PeintCadre(2,tbDom[no].fCas1,tbDom[no].fCas2);
          Domino(no).Picture.Bitmap := cadre;
          cadre.Free;
        end;
    2 : begin                     // vertical -> horizontal
          Domino(no).Left := Domino(no).Left - 15;
          Domino(no).Top := Domino(no).Top + 15;
          tbDom[no].fSens := 1;
          n := tbDom[no].fCas1;
          tbDom[no].fCas1 := tbDom[no].fCas2;
          tbDom[no].fCas2 := n;
          tbDom[no].fPaire := tbDom[no].fCas1 * 10 + tbDom[no].fCas2;
          Domino(no).Width := 60;
          Domino(no).Height := 30;
          PeintCadre(1,tbDom[no].fCas1,tbDom[no].fCas2);
          Domino(no).Picture.Bitmap := cadre;
          cadre.Free;
        end;
  end;
end;

procedure TV5.Retour(no : byte);
begin
  with tbdom[no] do
  begin
    if fSens = 2 then Pivoter(no);
    Deplace(no,fOrx,fOry);
  end;
end;
//------------------------------------------------------------------------------
// Sauvegarde des options
procedure TV5.SauveJeu;
var  parm : TSav;
     pxy : TPoint;
     i,x,y : byte;
begin
  AssignFile(fsa,nsa);
  Rewrite(fsa,1);
  with parm do
  begin
    col := rbcol;
    nca := noca;
    pt1 := Points[1];
    pt2 := Points[2];
    if Foptions.CBcajou.Checked then caj := 1 else caj := 0;
  end;
  BlockWrite(fsa,parm,Sizeof(parm));
  if bdeb and not bfin then          // si le jeu n'est pas terminé
  begin                              // on sauvegarde l'état du jeu
    for i := 1 to 30 do
    begin
      pxy.X := Domino(i).Left;
      pxy.Y := Domino(i).Top;
      BlockWrite(fsa,pxy,Sizeof(TPoint));
      BlockWrite(fsa,tbDom[i],Sizeof(tbDom[i]));
    end;
    for y := 0 to 15 do
      for x := 0 to 19 do
      begin
        BlockWrite(fsa,tablo[x,y],1);
        BlockWrite(fsa,tablP[x,y],1);
      end;
  end;
  CloseFile(fsa);
end;

// Chargement des options et éventuellement du jeu à terminer
procedure TV5.RestoreJeu;
var  parm : TSav;
     pxy : TPoint;
     i,x,y : byte;
begin
  AssignFile(fsa,nsa);
  Reset(fsa,1);
  BlockRead(fsa,parm,SizeOf(TSav));
  with parm do
  begin
    rbcol := col;
    noca := nca;
    with FOptions do
    begin
      PoseNoca(noca-1);
      PoseRbcol(rbcol);
      if caj = 1 then CBcajou.Checked := true else CBcajou.Checked := false;
      if CBCajou.Checked then bron := true else bron := false;
      for i := 1 to 5 do
        tbcol[i] := tbTeint[rbcol,i];
    end;
  end;
  if not EOF(fsa) then     // on réinstalle un jeu non terminé
  begin
    Points[1] := parm.pt1;
    Point1.Caption := IntToStr(points[1]);
    Points[2] := parm.pt2;
    Point2.Caption := IntToStr(points[2]);
    for i := 1 to 30 do
    begin
      BlockRead(fsa,pxy,Sizeof(TPoint));
      Domino(i).Left := pxy.X;
      Domino(i).Top := pxy.Y;
      BlockRead(fsa,tbDom[i],Sizeof(tbDom[i]));
      if tbDom[i].fSens = 2 then
      begin
        Domino(i).Width := 31;
        Domino(i).Height := 61;
      end;
      PeintCadre(tbDom[i].fSens,tbDom[i].fCas1,tbDom[i].fCas2);
      Domino(i).Picture.Bitmap := cadre;       
      cadre.Free;
    end;
    for y := 0 to 15 do
      for x := 0 to 19 do
      begin
        BlockRead(fsa,tablo[x,y],1);
        BlockRead(fsa,tablP[x,y],1);
      end;  
    bjex := true;
    bdeb := true;
    JeuHum;
  end;
end;

procedure TV5.SBScoreClick(Sender: TObject);
begin
  Scores.ShowModal;
end;

procedure TV5.SBAideClick(Sender: TObject);
begin
  FAide.ShowModal;
end;

end.

