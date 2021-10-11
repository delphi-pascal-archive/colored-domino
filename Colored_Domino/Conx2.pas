unit Conx2;
{  Cette unité est le coeur du programme. Elle contient les principales
  données ainsi que les procédures et fonctions de marche du jeu.
  Les mêmes routines servent pour le jeu du joueur et celui de l'ordinateur.
  La différence est qu'elles ne servent au joueur qu'à vérifier s'il peut
  poser le domino choisi, alors que l'ordi choisi son domino dans la liste
  des jouables. Pour ne pas pénaliser le joueur, le choix de l'ordi se fait
  au hasard et non en fonction du nombre de points réalisables.
}
interface

uses
  Windows, ExtCtrls, Controls, Classes, SysUtils, StdCtrls, Graphics, Dialogs;

type
  Tsuite = array[0..5] of byte;     // pour collecter une suite de cases
  TEss = record                     // redéfinit Tsuite
           s0,s1,s2,s3,s4,s5 : byte;
         end;
  Tref = array[1..12] of byte;
  Tstr = string[12];
  TDomino = record                // Définition d'un domino
              fOrx    : integer;       // position origine
              fOry    : integer;
              fSens  : integer;        // 1 : horizontal - 2 : vertical
              fCas1  : integer;        // couleur des cases
              fCas2  : integer;        //    "     "    "
              fPaire : integer;        // identité du domino : Cas1 * 10 + Cas2
              fBlock : boolean;        // blocage du domino joué
            end;
  TDomOk = record            // Données pou un domino jouable
             px,py : byte;      // coordonnées tableau de jeu
             nd,                // n° du domino
             pr,                // paire
             sn,                // sens du domino  1,2
             ro    : byte;      // rotation  0..3
             pt    : integer;   // nbre de points
           end;
  TSav = record                 // Enregistrement pour sauve garde des options
           col,nca : integer;
           pt1,pt2 : integer;
           caj : byte;
         end;

const
  long = 60;
  haut = 30;
                // indice des couleurs pour chaque domino
  tbCoul : array[1..30,1..2] of byte = ((1,1),(1,2),(1,3),(1,4),(1,5),(2,2),
                          (2,3),(2,4),(2,5),(3,3),(3,4),(3,5),(4,4),(4,5),(5,5),
                          (1,1),(1,2),(1,3),(1,4),(1,5),(2,2),(2,3),(2,4),(2,5),
                          (3,3),(3,4),(3,5),(4,4),(4,5),(5,5));
                // couleurs pastels + couleurs vives
  tbTeint : array[1..2,1..5] of TColor =
                           (($00A6FFA6,$006C6CFF,$00FF84FF,$0088FFFF,$00FFB69D),
                            (clLime,clRed,clFuchsia,clYellow,$00ff966E));
                // table de validité des configuration de cases
  Valide : array[1..25] of word = (12,13,14,15,16,23,24,25,26,34,35,36,45,46,56,
                                   123,125,126,136,156,234,245,345,346,456);

var
  tablo : array[0..19,0..15] of byte;         // jeu
  tablP : array[0..19,0..15] of byte;         // piles
  tbok  : array of TDomOk;            // tables des dominos jouables
  nbok  : integer;
  tbDom : array[1..30] of TDomino;
  cadre : TBitmap;                  // reçoit l'image du domino
  casx,
  casy : integer;
  domi : byte;                      // domino en cours
  dojou : array[1..30] of byte;     // dominos joués
  tbcol : array[1..5] of TColor;    // table des couleurs
  joueur,                           // numéro du joueur
  njo : byte;                       // nbre de dominos joués
  pts : integer;
  points : array[1..2] of integer;
  acl,alg,asn : byte;               // position et sens du domino testé
  ava : word;                       // configuration des cases autour du domino
  bval : boolean = true;
  inv, bfin : boolean;
  prem : byte;
  fsa : file;                       // fichier de sauvegarde
  nsa : string = 'Connexion.sav';
  rst : array[1..12] of byte;

procedure Trace(n1,n2 : integer);
function  Paire(c1,c2 : byte) : byte;
procedure EffaceTablP;
procedure TestCases;
procedure ControlCases;
procedure ChargeDomOk(pa : byte);
function  ControlDomino(nx,ny : byte) : boolean;

implementation

var
  stn : TSuite;
  ess : TEss absolute stn;
  dok : byte;

procedure Trace(n1,n2 : integer);  // utile en cours de dévellopement
begin
  ShowMessageFMT('%d - %d',[n1,n2]);
end;

procedure EffaceTablP;             // efface le tableau des piles
var  lg,cl : byte;
begin
  for lg := 0 to 15 do
    for cl := 0 to 19 do
      tablP[cl,lg] := 0;
end;

// On ne doit pas superposer plus de 3 dominos. Le tableau des piles reçoit à
// chaque pose de domino et dans la case correspondant au domino la valeur 1
// s'il est horizontal, 2 s'il est vertical. Cette fonction, en comptant les 1
// et les 2, permet d'interdire une pose irrégulière.
function ControlPile(cl,lg,sn : byte) : byte;
var  x,y,n : byte;
begin
  n := 0;
  case sn of
    1 : begin
          y := lg-1;
          while tablP[cl,y] = 1 do
          begin
            inc(n);
            dec(y);
          end;
          if n < 3 then
          begin
            n := 0;
            y := lg+1;
            while tablP[cl,y] = 1 do
            begin
              inc(n);
              inc(y);
            end;
          end;
        end;
    2 : begin
          x := cl-1;
          while tablP[x,lg] = 2 do
          begin
            inc(n);
            dec(x);
          end;
          if n < 3 then
          begin
            x := cl+1;
            while tablP[x,lg] = 2 do
            begin
              inc(n);
              inc(x);
            end;
          end;
        end;
  end;
  Result := n;
end;

// Recçoit les informations pour une case jouable et lance les contrôles.
procedure AjouteJouable(cl,lg,n : byte; vp : word);
begin
  if ControlPile(cl,lg,n) < 3 then
  begin
    acl := cl;
    alg := lg;
    ava := vp;
    asn := n;
    ControlCases;
  end;
end;

// Construit un identificateur de domino
function Paire(c1,c2 : byte) : byte;
begin
  Result := c1 * 10 + c2;
end;

{ Cette procédure parcourt le tableau de jeu dans le sens horizontal et vertical
 et, pour chaque case vide, vérifie si elle peut recevoir un domino.
 Pour ce faire, on examine les cases voisines de la manière suivante :
   5 6      a et b représentent le domino, a étant la case testé.
 4 a b 1    Pour les cases 1 à 6, si elles contiennent une valeur de 1 à 5,
   3 2      on multiplie le code configuration par 10 et on ajoute le numéro
            de la case ce qui nous donne un code dans le genre de 126...
 Ce code est ensuite comparé à la table des codes valides (voir plus haut) pour
 déterminer si la case peut être jouée.
}
procedure TestCases;
var cl,lg,i : byte;
    va : word;        // code configuration
begin
  for lg := 1 to 14 do
    for cl := 1 to 18 do
      if tablo[cl,lg] = 0 then
      begin
        va := 0;
        if tablo[cl+1,lg] = 0 then
        begin
          if cl < 18 then
            if tablo[cl+2,lg] in[1..5] then va := 1;
          if tablo[cl+1,lg+1] in[1..5] then va := va*10+2;
          if tablo[cl,lg+1] in[1..5] then va := va*10+3;
          if tablo[cl-1,lg] in[1..5] then va := va*10+4;
          if tablo[cl,lg-1] in[1..5] then va := va*10+5;
          if tablo[cl+1,lg-1] in[1..5] then va := va*10+6;
          for i := 1 to 25 do
            if va = Valide[i] then AjouteJouable(cl,lg,1,va);
        end;
        va := 0;
        if tablo[cl,lg+1] = 0 then
        begin
          if lg < 14 then
            if tablo[cl,lg+2] in[1..5] then va := 1;
          if tablo[cl-1,lg+1] in[1..5] then va := va*10+2;
          if tablo[cl-1,lg] in[1..5] then va := va*10+3;
          if tablo[cl,lg-1] in[1..5] then va := va*10+4;
          if tablo[cl+1,lg] in[1..5] then va := va*10+5;
          if tablo[cl+1,lg+1] in[1..5] then va := va*10+6;
          for i := 1 to 25 do
            if va = Valide[i] then AjouteJouable(cl,lg,2,va);
        end;
      end;
end;

procedure Inverse(var pa : byte);
var  n,n1,n2 : byte;
begin
  n1 := pa div 10;
  n2 := pa mod 10;
  n := n1;
  n1 := n2;
  n2 := n;
  pa := Paire(n1,n2)
end;

// Cette procédure collecte les séries de cases pour définir le cycle d'un
// groupe. Un cycle comportant au maximum 5 valeurs, on arrête la collecte
// à 5 cases ou moins s'il y a lieu. On explore ensuite la suite et si l'on
// trouve une valeur identique à la première de la série, on se limite à
// cette position.
procedure ChargeSuite(n : byte);
var  i,ca : byte;
     cl,lg,ss : byte;                  
begin
  for i := 0 to 5 do stn[i] := 0;
  cl := acl;
  lg := alg;
  ss := asn;
  if ss = 1 then                        // Horizontal
  begin
    case n of
      1 : begin
            i := 1;
            inc(cl);
            ca := tablo[cl+i,lg];
            while (ca in[1..5]) and (i < 6) do
            begin
              inc(stn[0]);
              stn[i] := ca;
              inc(i);
              ca := tablo[cl+i,lg];
            end;
          end;
      2 : begin
            i := 1;
            ca := tablo[cl+1,lg+i];
            while (ca in[1..5]) and (i < 6) do
            begin
              inc(stn[0]);
              stn[i] := ca;
              inc(i);
              ca := tablo[cl+1,lg+i];
            end;
          end;
      3 : begin
            i := 1;
            ca := tablo[cl,lg+i];
            while (ca in[1..5]) and (i < 6) do
            begin
              inc(stn[0]);
              stn[i] := ca;
              inc(i);
              ca := tablo[cl,lg+i];
            end;
          end;
      4 : begin
            i := 1;
            ca := tablo[cl-i,lg];
            while (ca in[1..5]) and (i < 6) do
            begin
              inc(stn[0]);
              stn[i] := ca;
              inc(i);
              ca := tablo[cl-i,lg];
            end;
          end;
      5 : begin
            i := 1;
            ca := tablo[cl,lg-i];
            while (ca in[1..5]) and (i < 6) do
            begin
              inc(stn[0]);
              stn[i] := ca;
              inc(i);
              ca := tablo[cl,lg-i];
            end;
          end;
      6 : begin
            i := 1;
            ca := tablo[cl+1,lg-i];
            while (ca in[1..5]) and (i < 6) do
            begin
              inc(stn[0]);
              stn[i] := ca;
              inc(i);
              ca := tablo[cl+1,lg-i];
            end;
          end;
    end;
    if stn[0] > 0 then
      for i := 2 to stn[0] do
        if stn[i] = stn[1] then
        begin
          stn[0] := i;
          break;
        end;
  end  // if ss = 1
  else
    begin                                 // Vertical
      case n of
        1 : begin
              i := 1;
              inc(lg);
              ca := tablo[cl,lg+i];
              while (ca in[1..5]) and (i < 6) do
              begin
                inc(stn[0]);
                stn[i] := ca;
                inc(i);
                ca := tablo[cl,lg+i];
              end;
            end;
        2 : begin
              i := 1;
              ca := tablo[cl-i,lg+1];
              while (ca in[1..5]) and (i < 6) do
              begin
                inc(stn[0]);
                stn[i] := ca;
                inc(i);
                ca := tablo[cl-i,lg+1];
              end;
            end;
        3 : begin
              i := 1;
              ca := tablo[cl-i,lg];
              while (ca in[1..5]) and (i < 6) do
              begin
                inc(stn[0]);
                stn[i] := ca;
                inc(i);
                ca := tablo[cl-i,lg];
              end;
            end;
        4 : begin
              i := 1;
              ca := tablo[cl,lg-i];
              while (ca in[1..5]) and (i < 6) do
              begin
                inc(stn[0]);
                stn[i] := ca;
                inc(i);
                ca := tablo[cl,lg-i];
              end;
            end;
        5 : begin
              i := 1;
              ca := tablo[cl+i,lg];
              while (ca in[1..5]) and (i < 6) do
              begin
                inc(stn[0]);
                stn[i] := ca;
                inc(i);
                ca := tablo[cl+i,lg];
              end;
            end;
        6 : begin
              i := 1;
              ca := tablo[cl+i,lg+1];
              while (ca in[1..5]) and (i < 6) do
              begin
                inc(stn[0]);
                stn[i] := ca;
                inc(i);
                ca := tablo[cl+i,lg+1];
              end;
            end;
      end;
      if stn[0] > 1 then
        for i := 2 to stn[0] do
          if stn[i] = stn[1] then
          begin
            stn[0] := i;
            break;
          end;
    end;
end;

{ Pour constituer la clé, on attribue le code 1 à la case testée (ca).
 Ensuite, on examine chaque position de la suite (stn[]). Si sa valeur est
 égale à celle de "ca" on lui attribue le code 1, sinon on rapproche sa valeur
 de celle des positions précédentes. En cas d'égalité on attribue le même code,
 sinon on incrémente "val" pour créer un nouveau code.
 Exemple : ca = 3  stn = 5,2,3   val = 1
                         5 <> ca : val+1 = 2  ref = 2
                         2 <> ca et <> 5 : val = 3 ref = 2,3
                         3 = ca : ref = 2,3,1
           et ref nous donne la clé 231
 Si je n'ai pas été assez clair, décortiquez donc la fonction suivante.
}
function CleCase(ca : byte) : word;
var  ref : array[1..5] of byte;
     wd : word;
     i,n,lg,val : byte;
begin
  val := 1;
  lg := stn[0];
  for i := 1 to 5 do ref[i] := 0;
  if stn[1] = ca then ref[1] := 1
  else
    begin
      inc(val);
      ref[1] := val;
    end;
  for i := 2 to lg do
  begin
    if stn[i] = ca then ref[i] := 1
    else
      for n := 1 to i-1 do
        if stn[i] = stn[n] then ref[i] := ref[n];
        if ref[i] = 0 then
        begin
          inc(val);
          ref[i] := val;
        end;
  end;
  wd := 0;
  for i := 1 to lg do
    wd := wd * 10 + ref[i];
  Result := wd;
end;

// Une case du domino est en contact latéralement avec une case ou une suite
// de cases occupées. On fait appel à la fonction CleCase et on rapproche la
// clé renvoyée de l'une des tables ce clés valides.
function CasesValides(ca : byte) : boolean;
const
  tc3 : array[1..37] of word  = (212,231,234,235,241,243,245,251,253,254,
                                 321,324,325,341,342,345,351,352,354,
                                 421,423,425,431,432,435,451,452,453,
                                 521,523,524,531,532,534,541,542,543);
  tc4 : array[1..15] of word  = (2312,2412,2512,2341,2345,2351,2354,
                                 2431,2435,2451,2453,2531,2534,2541,2543);
  tc5 : array[1..12] of word  = (23412,23512,24312,24512,25312,25412,
                                 23451,23541,24351,24531,25341,25431);
var
    ok : boolean;
    wd : word;
    i,lg : byte;
begin
  lg := stn[0];     // nbre de cases de la suite
  ok := false;
  with ess do       // ess est la redéfinition de stn[]
  begin
    case lg of
      1 : ok := true;
      2 : if ca = s2 then ok := true
          else
            if (ca <> s1) and (s1 <> s2) then ok := true;
      3 : begin
            wd := CleCase(ca);
            for i := 1 to 37 do
              if tc3[i] = wd then ok := true;
          end;
      4 : begin
            wd := CleCase(ca);
            for i := 1 to 15 do
              if tc4[i] = wd then ok := true;
          end;
      5 : begin
            wd := CleCase(ca);
            for i := 1 to 12 do
              if tc5[i] = wd then ok := true;
          end;
    end;
  end;
  Result := ok;
end;

// Calcul de clé comme pour CleCase mais en rapprochant du domino entier.
function ClePaire(p1,p2 : byte) : word;
var  ref : array[1..5] of byte;
     wd : word;
     i,n,lg,val : byte;
begin
  val := 2;
  lg := stn[0];
  for i := 1 to 5 do ref[i] := 0;
  if stn[1] = p1 then ref[1] := 1
  else
    if stn[1] = p2 then ref[1] := 2
    else
      begin
        inc(val);
        ref[1] := val;
      end;
  for i := 2 to lg do
  begin
    if stn[i] = p1 then ref[i] := 1
    else
      if stn[i] = p2 then ref[i] := 2
      else
        for n := 1 to i-1 do
          if stn[i] = stn[n] then ref[i] := ref[n];
          if ref[i] = 0 then
          begin
            inc(val);
            ref[i] := val;
          end;
  end;
  wd := 0;
  for i := 1 to lg do
    wd := wd * 10 + ref[i];
  Result := wd;
end;

// Un domino est en contact en bout avec une case ou une suite de cases.
// Si les cases sont à gauche d'un domino horizontal ou au dessus d'un
// domino vertical, on inverse le domino pour réaliser le contrôle.
function PaireValide(pa,nc : byte) : boolean;
const
  tp2 : array[1..10] of word  = (12,31,34,35,41,42,45,51,53,54);
  tp3 : array[1..16] of word  = (121,312,412,512,341,345,351,354,
                                 431,435,451,453,531,534,541,543);
  tp4 : array[1..15] of word  = (3123,4124,5125,3412,3512,4312,4512,
                                 5312,5412,3451,3541,4351,4531,5341,5431);
  tp5 : array[1..7] of word  = (34123,34512,35412,43512,45312,53412,54312);
var  i,p1,p2,p12,lg : byte;
     wd : word;
     ok : boolean;
begin
  p12 := pa;
  if nc = 4 then Inverse(p12);
  p1 := p12 div 10;
  p2 := p12 mod 10;
  ChargeSuite(nc);
  lg := stn[0];
  ok := false;
  with ess do
  begin
    if p1 = p2 then
    begin
      if (lg = 1) and (p1 = s1) then ok := true;
      if (lg = 2) and (p12 = paire(s1,s2)) then ok := true;
    end
    else
      begin
        case lg of
          1 : if p1 = p2 then
              begin
                if p1 = s1 then ok := true;
              end
              else if p1 = s1 then ok := true
                   else if s1 <> p2 then ok := true;
          2 : begin
                wd := ClePaire(p1,p2);
                for i := 1 to 10 do
                  if tp2[i] = wd then ok := true;
              end;
          3 : begin
                wd := ClePaire(p1,p2);
                for i := 1 to 16 do
                  if tp3[i] = wd then ok := true;
              end;
          4 : begin
                wd := ClePaire(p1,p2);
                for i := 1 to 15 do
                  if tp4[i] = wd then ok := true;
              end;
          5 : begin
                wd := ClePaire(p1,p2);
                for i := 1 to 7 do
                  if tp5[i] = wd then ok := true;
              end;
        end;
    end;
  end;
  Result := ok;
end;

function CleValide(ref : Tref) : boolean;
const
  tbv : array[1..47] of Tstr = ('111000000000','111100000000','111110000000',
                 '111111000000','111111100000','111111110000','111111111000',
                 '111111111100','111111111110','111111111111','121000000000',
                 '121200000000','121210000000','121212000000','121212100000',
                 '121212120000','121212121000','121212121200','121212121210',
                 '121212121212','123000000000','123100000000','123120000000',
                 '123123000000','123123100000','123123120000','123123123000',
                 '123123123100','123123123120','123123123123','123400000000',
                 '123410000000','123412000000','123412300000','123412340000',
                 '123412341000','123412341200','123412341230','123412341234',
                 '123450000000','123451000000','123451200000','123451230000',
                 '123451234000','123451234500','123451234510','123451234512');
var i,n : byte;
    ok : boolean;
    st : Tstr;
begin
  ok := false;
  st := '';
  for i := 1 to 12 do
    st := st + IntToStr(ref[i]);
  for i := 1 to 47 do
    if st = tbv[i] then ok := true;
  Result := ok;
end;

// Un peu plus compliqué mais toujours suivant le même principe, insertion
// latérale entre deux suites de cases.
function InsereCase(ca,nc : byte) : boolean;
var ste,ref : Tref;
    i,n,lg,val,lm,c1,c2 : byte;
begin
  for i := 1 to 12 do ref[i] := 0;
  if nc = 1 then    // nc indique quel bout du domino est en contact latéral
    if asn = 1 then
    begin
      c1 := 6;
      c2 := 2;
    end
    else
      begin
        c1 := 2;
        c2 := 6;
      end;
  if nc = 4 then
    if asn = 1 then
    begin
      c1 := 5;
      c2 := 3;
    end
    else
      begin
        c1 := 3;
        c2 := 5;
      end;
  ChargeSuite(c1);
  n := 1;
  lg := stn[0];
  for i := lg downto 1 do
  begin
    ste[n] := stn[i];
    inc(n);
  end;
  ste[n] := ca;
  inc(n);
  lg := lg+1;
  ChargeSuite(c2);
  for i := 1 to stn[0] do
  begin
    ste[n] := stn[i];
    inc(n);
  end;
  lg := lg+stn[0];
  ref[1] := 1;
  if ste[2] = ste[1] then ref[2] := 1
  else ref[2] := 2;
  val := ref[2];
  for i := 3 to lg do
  begin
    for n := 1 to i-1 do
      if ste[i] = ste[n] then ref[i] := ref[n];
    if ref[i] = 0 then
    begin
      inc(val);
      ref[i] := val;
    end;
  end;
  Result := CleValide(ref);
end;

// Insertion en bout entre deux suites de cases
function InserePaire(pa : byte) : boolean;
var ste,ref : Tref;
    i,n,lg,p12,val : byte;
begin
  for i := 1 to 12 do ref[i] := 0;
  p12 := pa;
  Inverse(p12);
  ChargeSuite(4);
  n := 1;
  lg := stn[0];
  for i := lg downto 1 do
  begin
    ste[n] := stn[i];
    inc(n);
  end;
  ste[n] := pa div 10;
  inc(n);
  ste[n] := pa div 10;
  inc(n);
  lg := lg+2;
  ChargeSuite(1);
  for i := 1 to stn[0] do
  begin
    ste[n] := stn[i];
    inc(n);
  end;
  lg := lg+stn[0];
  ref[1] := 1;
  if ste[2] = ste[1] then ref[2] := 1
  else ref[2] := 2;
  val := ref[2];
  for i := 3 to lg do
  begin
    for n := 1 to i-1 do
      if ste[i] = ste[n] then ref[i] := ref[n];
    if ref[i] = 0 then
    begin
      inc(val);
      ref[i] := val;
    end;
  end;
  Result := CleValide(ref);
end;

function Suite12(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(2);
  if CasesValides(ca) and
     PaireValide(pa,1) then Result := true;
end;

function Suite13(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa div 10;
  ChargeSuite(3);
  if CasesValides(ca) and
     PaireValide(pa,1) then Result := true;
end;

function Suite14(pa : byte) : boolean;
begin
  Result := false;
  if PaireValide(pa,1) and
     PaireValide(pa,4) then Result := InserePaire(pa);
end;

function Suite15(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa div 10;
  ChargeSuite(5);
  if CasesValides(ca) and
    PaireValide(pa,1) then Result := true;
end;

function Suite16(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(6);
  if CasesValides(ca) and
    PaireValide(pa,1) then Result := true;
end;

function Suite23(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(2);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(3);
    if CasesValides(ca) then Result := true;
  end;
end;

function Suite24(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(2);
  if CasesValides(ca) and
     PaireValide(pa,4) then Result := true;
end;

function Suite25(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(2);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(5);
    if CasesValides(ca) then Result := true;
  end;
end;

function Suite26(pa : byte) : boolean;
var ca : byte;
begin
  ca := pa mod 10;
  Result := InsereCase(ca,1);
end;

function Suite34(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa div 10;
  ChargeSuite(3);
  if CasesValides(ca) and
     PaireValide(pa,4) then Result := true;
end;

function Suite35(pa : byte) : boolean;
var ca : byte;
begin
  ca := pa div 10;
  Result := InsereCase(ca,4);
end;

function Suite36(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(6);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(3);
    if CasesValides(ca) then Result := true;
  end;
end;

function Suite45(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa div 10;
  ChargeSuite(5);
  if CasesValides(ca) and
     PaireValide(pa,4) then Result := true;
end;

function Suite46(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(6);
  if CasesValides(ca) and
     PaireValide(pa,4) then Result := true;
end;

function Suite56(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ChargeSuite(6);
  ca := pa mod 10;
  if CasesValides(ca) then
  begin
    ChargeSuite(5);
    ca := pa div 10;
    if CasesValides(ca) then Result := true;
  end;
end;

function Suite123(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(2);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(3);
    if CasesValides(ca) and
       PaireValide(pa,1) then Result := true;
  end;
end;

function Suite125(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(2);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(5);
    if CasesValides(ca) and
       PaireValide(pa,1) then Result := true;
  end;
end;

function Suite126(pa : byte) : boolean;
var ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  if InsereCase(ca,1) and
     PaireValide(pa,1) then Result := true;
end;

function Suite136(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(6);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(3);
    if CasesValides(ca) and
       PaireValide(pa,1) then Result := true;
  end;
end;

function Suite156(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(6);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(5);
    if CasesValides(ca) and
       PaireValide(pa,1) then Result := true;
  end;
end;

function Suite245(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(2);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(5);
    if CasesValides(ca) and
       PaireValide(pa,4) then Result := true;
  end;
end;

function Suite234(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(2);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(3);
    if CasesValides(ca) and
       PaireValide(pa,4) then Result := true;
  end;
end;

function Suite345(pa : byte) : boolean;
var ca : byte;
begin
  Result := false;
  ca := pa div 10;
  if InsereCase(ca,4) and
     PaireValide(pa,4) then Result := true;
end;

function Suite346(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(6);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(3);
    if CasesValides(ca) and
       PaireValide(pa,4) then Result := true;
  end;
end;

function Suite456(pa : byte) : boolean;
var  ca : byte;
begin
  Result := false;
  ca := pa mod 10;
  ChargeSuite(6);
  if CasesValides(ca) then
  begin
    ca := pa div 10;
    ChargeSuite(5);
    if CasesValides(ca) and
       PaireValide(pa,4) then Result := true;
  end;
end;

// En fonction du code configuration, on exécute la routine de contrôle appropriée.
function SuiteOk(pa : byte) : boolean;
var  ok : boolean;
begin
  ok := false;
  case ava of
    12 : ok := Suite12(pa);
    13 : ok := Suite13(pa);
    14 : ok := Suite14(pa);
    15 : ok := Suite15(pa);
    16 : ok := Suite16(pa);
    23 : ok := Suite23(pa);
    24 : ok := Suite24(pa);
    25 : ok := Suite25(pa);
    26 : ok := Suite26(pa);
    34 : ok := Suite34(pa);
    35 : ok := Suite35(pa);
    36 : ok := Suite36(pa);
    45 : ok := Suite45(pa);
    46 : ok := Suite46(pa);
    56 : ok := Suite56(pa);
    123 : ok := Suite123(pa);
    126 : ok := Suite126(pa);
    156 : ok := Suite156(pa);
    234 : ok := Suite234(pa);
    345 : ok := Suite345(pa);
    456 : ok := Suite456(pa);
  end;
  Result := ok;
end;
 
// De chaque case jouable, on rapproche chaque domino encore en jeu.
// S'il peut être posé, on le rajoute dans la table des dominos valides.
// Il est possible que plusieurs dominos puissent être joué sur une même case
// et inversement qu'un domino ait plusieurs possibilités de pose.
procedure ControlCases;
var  i,sp,n,pa : byte;
begin
  if joueur = 1 then sp := 0
  else sp := 15;
  for i := 1 to 15 do
  begin
    n := i+sp;
    if not tbDom[n].fBlock then
    begin
      inv := false;
      pa := tbDom[n].fPaire;
      if  SuiteOk(pa) then
      begin
        dok := n;
        ChargeDomOk(pa);
      end;
      if pa div 10 <> pa mod 10 then
      begin
        Inverse(pa);
        inv := true;
        if  SuiteOk(pa) then
        begin
          dok := n;
          ChargeDomOk(pa);
        end;
      end;
    end;
  end;
end;

function Comptage : integer;          // On compte les points...
var  i,j : byte;
     pn : integer;
     rs : array[1..6] of integer;
begin                                    
  for i := 1 to 6 do rs[i] := 1;
  for i := 1 to 6 do
  begin
    if asn = 1 then
    begin
      case i of
        1 : begin
              if tablo[acl+2,alg] in[1..5] then inc(rs[1]);
              j := 2;
              while tablo[acl+j,alg] in[1..5] do
              begin
                inc(rs[1]);
                inc(j);
              end;
            end;
        2 : begin
              j := 1;
              while tablo[acl+1,alg+j] in[1..5] do
              begin
                inc(rs[2]);
                inc(j);
              end;
            end;
        3 : begin
              j := 1;
              while tablo[acl,alg+j] in[1..5] do
              begin
                inc(rs[3]);
                inc(j);
              end;
            end;
        4 : begin
              j := 1;
              while tablo[acl-j,alg] in[1..5] do
              begin
                inc(rs[4]);
                inc(j);
              end;
            end;
        5 : begin
              j := 1;
              while tablo[acl,alg-j] in[1..5] do
              begin
                inc(rs[5]);
                inc(j);
              end;
            end;
        6 : begin
              j := 1;
              while tablo[acl+1,alg-j] in[1..5] do
              begin
                inc(rs[6]);
                inc(j);
              end;
            end;
      end;
    end
    else
      begin
        case i of
          1 : begin
                if tablo[acl,alg+2] in[1..5] then inc(rs[1]);
                j := 2;
                while tablo[acl,alg+j] in[1..5] do
                begin
                  inc(rs[1]);
                  inc(j);
                end;
              end;
          2 : begin
                j := 1;
                while tablo[acl-j,alg+1] in[1..5] do
                begin
                  inc(rs[2]);
                  inc(j);
                end;
              end;
          3 : begin
                j := 1;
                while tablo[acl-j,alg] in[1..5] do
                begin
                  inc(rs[3]);
                  inc(j);
                end;
              end;
          4 : begin
                j := 1;
                while tablo[acl,alg-j] in[1..5] do
                begin
                  inc(rs[4]);
                  inc(j);
                end;
              end;
          5 : begin
                j := 1;
                while tablo[acl+j,alg] in[1..5] do
                begin
                  inc(rs[5]);
                  inc(j);
                end;
              end;
          6 : begin
                j := 1;
                while tablo[acl+j,alg+1] in[1..5] do
                begin
                  inc(rs[6]);
                  inc(j);
                end;
              end;
        end;
      end;
  end;
  pn := rs[1];
  for i := 2 to 6 do pn := pn * rs[i];
  result := pn;
end;

// Les dominos valides sont stockés dans une table dynamique, vu qu'il n'est
// pas possible de définir la taille maxi.
procedure ChargeDomOk(pa : byte);
begin
  inc(nbok);                   
  SetLength(tbok,nbok);
  with tbok[nbok-1] do
  begin                       
    px := acl;
    py := alg;
    nd := dok;
    pr := pa;
    sn := asn;
    if asn = 1 then ro := 0
    else ro := 1;
    if inv then inc(ro,2);
    pt := Comptage;
    if pa div 10 = pa mod 10 then pt := pt * 2;
  end;
end;

// Le joueur ayant choisi un domino, cette fonction vérifie s'il existe dans la
// table des valides, pour la case choisie.
function ControlDomino(nx,ny : byte) : boolean;
var  i,pa : byte;
begin
  Result := false;
  pa := tbDom[domi].fPaire;
  for i := 0 to nbok-1 do
    with tbok[i] do
      if (px = nx) and (py = ny) then
        if pr = pa then
        begin
          pts := pt;
          Result := true
        end;
end;

end.
