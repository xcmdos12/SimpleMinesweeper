unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls;

type

  IntegerArray = array of integer;

  { TForm1 }

  TForm1 = class(TForm)
    B_zuruck: TButton;
    B_leicht: TButton;
    B_mittel: TButton;
    B_schwer: TButton;
    B_htp: TButton;
    GB_mode: TGroupBox;
    GB_htp: TGroupBox;
    I_icon: TImage;
    I_uhr: TImage;
    I_mine: TImage;
    LB_rest: TListBox;
    L_titel: TLabel;
    L_zeit: TLabel;
    L_minen: TLabel;
    ListBox1: TListBox;
    M_htp: TMemo;
    PC_game: TPageControl;
    PB_1: TProgressBar;
    P_info: TPanel;
    P_game: TPanel;
    T_time: TTimer;
    TS_game: TTabSheet;
    TB_htp: TTabSheet;
    TB_rest: TTabSheet;
    procedure B_htpClick(Sender: TObject);
    procedure B_leichtClick(Sender: TObject);
    procedure B_schwerClick(Sender: TObject);
    procedure B_mittelClick(Sender: TObject);
    procedure B_zuruckClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure T_timeTimer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure SpielErstellen(AnzahlFelder,Bomben:integer);
    procedure FelderLoeschen();
    procedure FeldKlick(Sender: TObject);
    procedure Verloren();
    procedure Gewonnen();
    procedure Auswertung();
    procedure FlaggeSetzen(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MinenSetzen(pos:integer);
    function UmkreisfelderErmitteln(pos:integer):IntegerArray;
    procedure FeldOeffnen(pos:integer);
    procedure NummernSetzen(pos:integer);
  end;

var
  Form1: TForm1;

  //Globale Variablen
  _AnzFelder:integer;
  _AnzGefund:integer;
  _Minen:integer;
  _Timer:integer;
  _MinenGesetzt:boolean;

  //Arrays zum Speichern des Spielfeldinformationen
  FelderObjekte: array of TImage;
  FelderWerte: array of string;
  FelderFlagge: array of string;

implementation

{$R *.lfm}

{ TForm1 }

//Startprozedure
procedure TForm1.FormCreate(Sender: TObject);
begin
  //Startwerte deklarieren und Steuerelemnete konfigurieren
  _Timer:=0;
  _AnzGefund:=0;
  T_time.Interval:=1000;
  T_time.Enabled:=false;
  PC_game.ShowTabs:=false;
  PC_game.Top:=-6;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  //Neues Spiel mit 100 Feldern und 10 Minen erstellen
  SpielErstellen(100, 10);
end;


//Prozedure für die Messung der Zeit
procedure TForm1.T_timeTimer(Sender: TObject);
begin
  //Zeit um eine Sekunde erhöhen
  _Timer:=_Timer+1;
  L_zeit.Caption:=IntToStr(_Timer) + ' Sekunden';
end;


procedure TForm1.B_leichtClick(Sender: TObject);
begin
  PC_game.ActivePageIndex:=0;
  
  //Neues Spiel mit 100 Feldern und 10 Minen erstellen
  SpielErstellen(100, 10);
end;

procedure TForm1.B_htpClick(Sender: TObject);
begin
  PC_game.ActivePageIndex:=1;
end;

procedure TForm1.B_schwerClick(Sender: TObject);
begin
  PC_game.ActivePageIndex:=0;
  
  //Neues Spiel mit 576 Feldern und 99 Minen erstellen
  SpielErstellen(576, 99);
end;

procedure TForm1.B_mittelClick(Sender: TObject);
begin
  PC_game.ActivePageIndex:=0;
  
  //Neues Spiel mit 256 Feldern und 40 Minen erstellen
  SpielErstellen(256, 40);
end;

procedure TForm1.B_zuruckClick(Sender: TObject);
begin
  PC_game.ActivePageIndex:=0;
end;

//Procedure für die Erstellung des Spielfeldes
procedure TForm1.SpielErstellen(AnzahlFelder, Bomben: integer);
VAR
  maz:single;
  i, h, x, y, start, n, size:integer;
  Feld:TImage;
begin

  //Altes Speilfeld löschen
  FelderLoeschen();


  //Spielinformationen setzen
  _AnzFelder:=AnzahlFelder;
  _Minen:=Bomben;
  _Timer:=0;
  _MinenGesetzt:=false;
  _AnzGefund:=0;
  L_minen.Caption:= '0/' + IntToStr(_Minen) + ' Bomben';
  n:=0;

  //Zeitmessung stoppen
  T_time.Enabled:=false;
  L_zeit.Caption:=IntToStr(_Timer) + ' Sekunden';

  //Listbox leeren
  LB_rest.Items.Clear;

  //Länge für Arrays mit Spielfeldinformationen setzen
  SetLength(FelderObjekte, AnzahlFelder);
  SetLength(FelderWerte, AnzahlFelder);
  SetLength(FelderFlagge, AnzahlFelder);

  //Feldgröße ermitteln
  maz:=sqrt(AnzahlFelder);
  size:=round((TS_game.Height - (2 * maz)) / maz);
  start:=round((TS_game.Width / 2) - ((size * maz) / 2));
  x:=start;
  y:=round((TS_game.Height / 2) - ((size * maz) / 2)); ;

  //Ladebalken konfigurieren
  PB_1.Max:=AnzahlFelder;
  PB_1.Min:=0;
  PB_1.Position:=0;
  PB_1.Visible:=true;

  //Felder erstellen Y-Achse
  FOR h:=1 to round(maz) DO
  begin

    //Felder erstellen X-Achse
    FOR i:=1 TO round(maz) DO
    begin

      //Neues Steuerelement (TImage) erstellen
      // --> Informationen für Objekt setzen
      Feld:=TImage.Create(TS_game);
      Feld.Parent:= TS_game;
      Feld.Width:= size;
      Feld.Height:= size;
      Feld.Left:= x;
      Feld.Top:= y;
      Feld.Name :='field_' + IntToStr(n);
      Feld.Picture.LoadFromFile('field_no.png');
      Feld.Proportional:=true;
      Feld.Center:=true;
      Feld.OnClick:=@FeldKlick;
      Feld.OnMouseDown:=@FlaggeSetzen;
      x:=x + size;

      //Informationen des Steuerelements in Arrays speichern
      FelderObjekte[StrToInt(IntToStr(n))]:=Feld;
      FelderWerte[StrToInt(IntToStr(n))]:='none';
      FelderFlagge[StrToInt(IntToStr(n))]:='none';

      n:=n+1;
      PB_1.Position:=PB_1.Position+1;
    end;
    x:=start;
    y:=y + size;
  end;
  x:=start;
  y:=x;
  PB_1.Visible:=false;
end;

procedure TForm1.FelderLoeschen;
VAR
  i:integer;
begin
  IF TS_game.ControlCount > 0 THEN FOR i:=TS_game.ControlCount - 1 DOWNTO 0 DO IF TS_game.Controls[i] is TImage THEN TS_game.Controls[i].Free;
end;

//Prozedure für Klicks auf ein Feld
procedure TForm1.FeldKlick(Sender: TObject);
VAR
  num:integer;
begin
 //Sender = geklicktes Feld
  IF Sender is TImage THEN
  begin
    //Feldnummer ermitteln
    num:=StrToInt(TImage(Sender).Name.Split(['_'])[1]);

    IF (LB_rest.Items.IndexOf(IntToStr(num)) = -1) THEN
    begin
	
      IF _MinenGesetzt = false THEN
      begin

        //Minen auf dem Spielfeld verteilen
        // --> nur beim ersten Klick auf das Spielfeld
        MinenSetzen(num);
        _MinenGesetzt:=true;

        //Zeitmessung starten
         T_time.Enabled:=true;
      end;
	  
      IF (FelderWerte[num] = 'bomp') AND (FelderFlagge[num] <> 'flag') THEN
      begin

        //Verloren
        Verloren();

      end
      ELSE IF (FelderWerte[num] <> 'none') AND (FelderFlagge[num] <> 'flag') THEN
      begin

        //Feld mit der Nummer 'num' öffen
        FeldOeffnen(num);

      end
      ELSE IF (FelderFlagge[num] = 'flag') THEN
      begin

        //Flagge auf dem Feld ermitteln
        FelderFlagge[num]:='none';
		
		//Bild in das TImage laden
        TImage(Sender).Picture.LoadFromFile('field_no.png');
		
        _AnzGefund:=_AnzGefund - 1;
        L_minen.Caption:=IntToStr(_AnzGefund) + '/' + IntToStr(_Minen) + ' Minen';

        IF (_AnzGefund = _Minen) THEN Auswertung();

      end
      ELSE
      begin

        FelderFlagge[num]:='none';
	//Feld mit der Nummer 'num' öffen
        FeldOeffnen(num);

      end;

    end;
  end;
end;

//Prozedure gewonnen
procedure TForm1.Verloren;
VAR
  i:integer;
begin
  T_time.Enabled:=false;
  FOR i:=0 TO (Length(FelderWerte) - 1) DO
  begin
    IF (LB_rest.Items.IndexOf(IntToStr(i)) = -1) THEN LB_rest.Items.Add(IntToStr(i));
    IF (FelderWerte[i] = 'bomp') THEN TImage(FelderObjekte[i]).Picture.LoadFromFile('field_mine.png');
  end;

  ShowMessage('Du hast verloren! Auf dem geklickten Feld war eine Mine!');

end;

//Prozedure Gewonnen
procedure TForm1.Gewonnen;
VAR
  i:integer;
begin
  T_time.Enabled:=false;
  
  FOR i:=0 TO (Length(FelderWerte) - 1) DO
  begin
  
    IF (LB_rest.Items.IndexOf(IntToStr(i)) = -1) THEN LB_rest.Items.Add(IntToStr(i));
    IF (FelderWerte[i] <> 'bomp') THEN TImage(FelderObjekte[i]).Picture.LoadFromFile('field_0.png');
	
  end;

  ShowMessage('Du hast gewonnen! Alle Minen wurden richtig makiert!');

end;

procedure TForm1.Auswertung;
VAR
  i,j:integer;
begin
  j:=0;
  
  
  FOR i:=0 TO _AnzFelder - 1 DO
  begin
  
    //Überprüfen ob das Feld mit der Flagge eine Mine ist
    IF (FelderWerte[i] = 'bomp') AND (FelderFlagge[i] = 'flag') THEN j:=j+1;
	
  end;
  
  IF j = _Minen THEN Gewonnen(); //Gewonnen
end;

//Prozedure zum Setzen einer Flagge
procedure TForm1.FlaggeSetzen(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
VAR
  num:integer;
  Feld:TImage;
begin
  IF Sender is TImage THEN
  begin
    Feld:=TImage(Sender);
    num:=StrToInt(Feld.Name.Split(['_'])[1]);
    CASE Button OF
       mbRight:
       begin
         IF (LB_rest.Items.IndexOf(IntToStr(num)) = -1) AND (FelderFlagge[num] <> 'flag') THEN
         begin
		   
	   //Bild in TImage laden
           Feld.Picture.LoadFromFile('field_flag.png');
		   
	   //Flagge setzen
           FelderFlagge[num]:='flag';
           _AnzGefund:=_AnzGefund+1;
		   
           L_minen.Caption:=IntToStr(_AnzGefund) + '/' + IntToStr(_Minen) + ' Minen';
		   
           IF (_AnzGefund = _Minen) THEN Auswertung();
		   
         end;
       end;
    end;
  end;
end;

//Prozedure zum Plazieren von Minen

procedure TForm1.MinenSetzen(pos: integer);
VAR
  i, j, ran :integer;
begin
  i:=round(sqrt(_AnzFelder));

  //Minenanzahl durchgehen
  FOR j:=0 TO (_Minen - 1) DO
  begin
    //Zufällige Position auf dem Spielfeld ermitteln
    // --> wird so lange ausgeführt bis 'random' ein freies Feld ist
    WHILE true DO
    begin
      ran:=random(_AnzFelder);
      IF ((ran < (pos - (i * 2))) OR (ran > (pos + (i * 2)))) AND (FelderWerte[ran] <> 'bomp') THEN
      begin
         FelderWerte[ran]:='bomp';

         //Schleife beenden
         break;
      end;
    end;

  end;
  FOR i:=0 TO (_AnzFelder - 1) DO
  begin
    //Nummern setzen
    NummernSetzen(i);
  end;
end;

//Prozedure zum Ermitteln von Feldern im Umkreis
function TForm1.UmkreisfelderErmitteln(pos: integer): IntegerArray;
VAR
  ArrEmp:array of integer;
  num,anz:integer;
begin

  //Errechnen der umliegenden Felder eines Feldes
  anz:=round(sqrt(_AnzFelder));
  num:=pos mod anz;
  IF (num = 0) THEN
  begin
	   //Feld befinden sich am linken Rand
       SetLength(ArrEmp, 6);
       ArrEmp[0]:=pos - anz + 1;
       ArrEmp[1]:=pos - anz;
       ArrEmp[2]:=pos + 1;
       ArrEmp[3]:=pos;
       ArrEmp[4]:=pos + anz + 1;
       ArrEmp[5]:=pos + anz;
  end
  ELSE IF (num = anz - 1) THEN
  begin
	   //Feld befindet sich am rechten Rand
       SetLength(ArrEmp, 6);
       ArrEmp[0]:=pos - anz - 1;
       ArrEmp[1]:=pos - anz;
       ArrEmp[2]:=pos - 1;
       ArrEmp[3]:=pos;
       ArrEmp[4]:=pos + anz - 1;
       ArrEmp[5]:=pos + anz;
  end
  ELSE
  begin
       //Feld befindet sich nicht am Rand
       SetLength(ArrEmp, 9);
       ArrEmp[0]:=pos - anz - 1;
       ArrEmp[1]:=pos - anz;
       ArrEmp[2]:=pos - anz + 1;
       ArrEmp[3]:=pos - 1;
       ArrEmp[4]:=pos;
       ArrEmp[5]:=pos + 1;
       ArrEmp[6]:=pos + anz - 1;
       ArrEmp[7]:=pos + anz;
       ArrEmp[8]:=pos + anz + 1;
  end;
  UmkreisfelderErmitteln:=ArrEmp;
end;

//Feld mit einer bestimmten Position öffen
procedure TForm1.FeldOeffnen(pos: integer);
VAR
  i:integer;
  ArrEmp: array of integer;
  Feld:TImage;
begin
  //Objekt des Feldes setzen
  Feld:=TImage(FelderObjekte[pos]);
  
  IF (FelderWerte[pos] <> 'none') AND (FelderWerte[pos] <> '0') THEN
  begin
  
    //Bild mit Nummer laden
    Feld.Picture.LoadFromFile('field_' + FelderWerte[pos] + '.png');
    LB_rest.Items.Add(IntToStr(pos));
	
  end
  ELSE IF (FelderWerte[pos] = '0') OR (FelderWerte[pos] = 'none') THEN
  begin
  
    ArrEmp:=UmkreisfelderErmitteln(pos);
    FOR i IN ArrEmp DO
    begin
	
       IF (i>=0) AND (i <= _AnzFelder - 1) AND (LB_rest.Items.IndexOf(IntToStr(i)) = -1) THEN
       begin
	   
         LB_rest.Items.Add(IntToStr(i));
         TImage(FelderObjekte[i]).Picture.LoadFromFile('field_' + FelderWerte[i] + '.png');
         FeldOeffnen(i);
		 
       end;
	   
    end;
	
  end
  ELSE ShowMessage('ELSE');
end;

//Minen im Umkreis des Feldes zählen und die Nummer auf das
//Feld mit der angegebenen Position setzen
procedure TForm1.NummernSetzen(pos: integer);
VAR
  i, bc:integer;
  ArrNum:array of integer;
begin
  IF (FelderWerte[pos] = 'bomp') THEN
  begin
    exit;
  end;
  ArrNum:=UmkreisfelderErmitteln(pos);
  bc:=0;
  FOR i IN ArrNum DO
  begin
       IF (i >= 0) AND (i <= _AnzFelder - 1) THEN
       begin
         IF (FelderWerte[i] = 'bomp') THEN bc:=bc+1;
       end;
  end;
  FelderWerte[pos]:=IntToStr(bc);
end;

end.

