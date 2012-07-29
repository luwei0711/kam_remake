unit KM_Points;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils;

type
  TKMDirection = (dir_NA=0, dir_N=1, dir_NE=2, dir_E=3, dir_SE=4, dir_S=5, dir_SW=6, dir_W=7, dir_NW=8);

type
  //Records must be packed so they are stored identically in MP saves (padding bytes are unknown values)
  TKMPoint = packed record X,Y: Word; end;
  TKMPointDir = packed record Loc: TKMPoint; Dir: TKMDirection; end;
  TKMPointF = packed record X,Y: Single; end;
  TKMPointI = packed record X,Y: Integer; end; //Allows negative values

  //We have our own TKMRect that consistently matches TKMPoint range
  //Rects are often used without range checking and include negative off-map coords
  TKMRect = packed record Left, Top, Right, Bottom: SmallInt end;

  function KMPoint(X,Y:word): TKMPoint; overload;
  function KMPoint(P:TKMPointI): TKMPoint; overload;
  function KMPointI(X,Y: Integer): TKMPointI;
  function KMPointF(X,Y:single): TKMPointF; overload;
  function KMPointF(P:TKMPoint):  TKMPointF; overload;
  function KMPointDir(X,Y: Word; Dir: TKMDirection): TKMPointDir; overload;
  function KMPointDir(P:TKMPoint; Dir: TKMDirection): TKMPointDir; overload;
  function KMPointX1Y1(P:TKMPoint): TKMPoint; overload;
  function KMPointBelow(P:TKMPoint): TKMPoint; overload;

  function KMPointRound(const P: TKMPointF): TKMPoint;
  function KMSamePoint(P1,P2:TKMPoint): boolean;
  function KMSamePointF(P1,P2:TKMPointF): boolean; overload;
  function KMSamePointF(P1,P2:TKMPointF; Epsilon:single): boolean; overload;
  function KMSamePointDir(P1,P2:TKMPointDir): boolean;

  function KMRect(aLeft, aTop, aRight, aBottom: SmallInt): TKMRect; overload;
  function KMRect(aPoint: TKMPoint): TKMRect; overload;
  function KMRect(aPoint: TKMPointF): TKMRect; overload;
  function KMRectGrow(aRect: TKMRect; aInset: Integer): TKMRect;
  function KMClipRect(aRect: TKMRect; X1,Y1,X2,Y2: Word): TKMRect;
  function KMInRect(aPoint: TKMPoint; aRect: TKMRect): Boolean; overload;
  function KMInRect(aPoint: TKMPointF; aRect: TKMRect): Boolean; overload;
  function KMRectArea(aRect: TKMRect):Integer;

  function KMGetDirection(X,Y: integer): TKMDirection; overload;
  function KMGetDirection(FromPos,ToPos: TKMPoint):TKMDirection; overload;
  function KMGetDirection(FromPos,ToPos: TKMPointF):TKMDirection; overload;
  function GetDirModifier(Dir1,Dir2:TKMDirection): byte;
  function KMGetVertexDir(X,Y: integer):TKMDirection;
  function KMGetVertexTile(P:TKMPoint; Dir: TKMDirection):TKMPoint;
  function KMGetVertex(Dir: TKMDirection):TKMPointF;
  function KMGetPointInDir(aPoint:TKMPoint; aDir: TKMDirection): TKMPointDir;

  function KMNextDirection(aDir: TKMDirection): TKMDirection;
  function KMPrevDirection(aDir: TKMDirection): TKMDirection;

  function KMGetDiagVertex(P1,P2:TKMPoint): TKMPoint;
  function KMStepIsDiag(P1,P2:TKMPoint):boolean;

  function GetLength(A,B:TKMPoint): single; overload;
  function GetLength(A,B:TKMPointF): single; overload;
  function KMLength(A,B:TKMPoint): single;

  function Mix(A,B:TKMPointF; MixValue:single):TKMPointF; overload;

  procedure KMSwapPoints(var A,B:TKMPoint);

  function TypeToString(t:TKMPoint):string; overload;
  function TypeToString(T: TKMDirection): String; overload;


implementation


function KMPoint(X,Y:word): TKMPoint;
begin
  Result.X := X;
  Result.Y := Y;
end;


function KMPoint(P:TKMPointI): TKMPoint;
begin
  Assert((P.X>=0) and (P.Y>=0));
  Result.X := P.X;
  Result.Y := P.Y;
end;


function KMPointI(X,Y: Integer): TKMPointI;
begin
  Result.X := X;
  Result.Y := Y;
end;


function KMPointF(P:TKMPoint): TKMPointF;
begin
  Result.X := P.X;
  Result.Y := P.Y;
end;


function KMPointF(X, Y: single): TKMPointF;
begin
  Result.X := X;
  Result.Y := Y;
end;


function KMPointDir(X,Y: Word; Dir: TKMDirection): TKMPointDir;
begin
  Result.Loc.X := X;
  Result.Loc.Y := Y;
  Result.Dir := Dir;
end;


function KMPointDir(P:TKMPoint; Dir: TKMDirection): TKMPointDir;
begin
  Result.Loc := P;
  Result.Dir := Dir;
end;


function KMPointX1Y1(P:TKMPoint): TKMPoint;
begin
  Result.X := P.X+1;
  Result.Y := P.Y+1;
end;


function KMPointBelow(P:TKMPoint): TKMPoint; overload;
begin
  Result.X := P.X;
  Result.Y := P.Y+1;
end;


function KMPointRound(const P: TKMPointF):TKMPoint;
begin
  Result.X := Round(P.X);
  Result.Y := Round(P.Y);
end;


function KMSamePoint(P1,P2: TKMPoint): boolean;
begin
  Result := ( P1.X = P2.X ) and ( P1.Y = P2.Y );
end;


function KMSamePointF(P1,P2: TKMPointF): boolean;
begin
  Result := ( P1.X = P2.X ) and ( P1.Y = P2.Y );
end;


function KMSamePointF(P1,P2:TKMPointF; Epsilon:single): boolean;
begin
  Result := (abs(P1.X - P2.X) < Epsilon) and (abs(P1.Y - P2.Y) < Epsilon);
end;


function KMSamePointDir(P1,P2: TKMPointDir): boolean;
begin
  Result := ( P1.Loc.X = P2.Loc.X ) and ( P1.Loc.Y = P2.Loc.Y ) and ( P1.Dir = P2.Dir );
end;


function KMRect(aLeft, aTop, aRight, aBottom: SmallInt): TKMRect;
begin
  Result.Left   := aLeft;
  Result.Right  := aRight;
  Result.Top    := aTop;
  Result.Bottom := aBottom;
end;


//Make rect with single point
function KMRect(aPoint: TKMPoint): TKMRect;
begin
  Result.Left   := aPoint.X;
  Result.Right  := aPoint.X;
  Result.Top    := aPoint.Y;
  Result.Bottom := aPoint.Y;
end;


//Encompass PointF into fixed-point rect (2x2)
function KMRect(aPoint: TKMPointF): TKMRect;
begin
  Result.Left   := Floor(aPoint.X) - Byte(Frac(aPoint.X) = 0);
  Result.Right  := Ceil(aPoint.X)  + Byte(Frac(aPoint.X) = 0);
  Result.Top    := Floor(aPoint.Y) - Byte(Frac(aPoint.Y) = 0);
  Result.Bottom := Ceil(aPoint.Y)  + Byte(Frac(aPoint.Y) = 0);
end;


function KMRectGrow(aRect: TKMRect; aInset: Integer): TKMRect;
begin
  Result.Left   := Math.Max(aRect.Left   - aInset, 0);
  Result.Right  := Math.Max(aRect.Right  + aInset, 0);
  Result.Top    := Math.Max(aRect.Top    - aInset, 0);
  Result.Bottom := Math.Max(aRect.Bottom + aInset, 0);
end;


function KMClipRect(aRect: TKMRect; X1,Y1,X2,Y2: Word): TKMRect;
begin
  Result.Left   := EnsureRange(aRect.Left, X1, X2);
  Result.Right  := EnsureRange(aRect.Right, X1, X2);
  Result.Top    := EnsureRange(aRect.Top, Y1, Y2);
  Result.Bottom := EnsureRange(aRect.Bottom, Y1, Y2);
end;


function KMInRect(aPoint: TKMPoint; aRect: TKMRect): Boolean;
begin
  Result := InRange(aPoint.X, aRect.Left, aRect.Right) and InRange(aPoint.Y, aRect.Top, aRect.Bottom);
end;


function KMInRect(aPoint: TKMPointF; aRect: TKMRect): Boolean;
begin
  Result := InRange(aPoint.X, aRect.Left, aRect.Right) and InRange(aPoint.Y, aRect.Top, aRect.Bottom);
end;


function KMRectArea(aRect: TKMRect):Integer;
begin
  Result := (aRect.Right - aRect.Left) * (aRect.Bottom  - aRect.Top);
end;


function KMGetDirection(X,Y: integer): TKMDirection;
const DirectionsBitfield:array[-1..1,-1..1]of TKMDirection =
        ((dir_SE,dir_E,dir_NE),(dir_S,dir_NA,dir_N),(dir_SW,dir_W,dir_NW));
var Scale:integer; a,b:shortint;
begin
  Scale := max(abs(X),abs(Y));
  a := round(X/Scale);
  b := round(Y/Scale);
  Result := DirectionsBitfield[a, b]; //-1,0,1
end;


function KMGetDirection(FromPos,ToPos: TKMPoint): TKMDirection;
const DirectionsBitfield:array[-1..1,-1..1]of TKMDirection =
        ((dir_NW,dir_W,dir_SW),(dir_N,dir_NA,dir_S),(dir_NE,dir_E,dir_SE));
var Scale:integer; a,b:shortint;
begin
  Scale := max(abs(ToPos.X-FromPos.X),abs(ToPos.Y-FromPos.Y));
  a := round((ToPos.X-FromPos.X)/Scale);
  b := round((ToPos.Y-FromPos.Y)/Scale);
  Result := DirectionsBitfield[a,b]; //-1,0,1
end;


function KMGetDirection(FromPos,ToPos: TKMPointF): TKMDirection;
const DirectionsBitfield:array[-1..1,-1..1]of TKMDirection =
        ((dir_NW,dir_W,dir_SW),(dir_N,dir_NA,dir_S),(dir_NE,dir_E,dir_SE));
var Scale:single; a,b:shortint;
begin
  Scale := max(abs(ToPos.X-FromPos.X),abs(ToPos.Y-FromPos.Y));
  a := round((ToPos.X-FromPos.X)/Scale);
  b := round((ToPos.Y-FromPos.Y)/Scale);
  Result := DirectionsBitfield[a,b]; //-1,0,1
end;


//How big is the difference between directions (in fights hit from behind is 5 times harder)
//  1 0 1
//  2   2
//  3 4 3
function GetDirModifier(Dir1,Dir2:TKMDirection): byte;
begin
  Result := abs(byte(Dir1) - ((byte(Dir2)+4) mod 8));

  if Result > 4 then
    Result := 8 - Result; //Mirror it, as the difference must always be 0..4
end;


function KMGetVertexDir(X,Y: integer):TKMDirection;
const DirectionsBitfield:array[-1..0,-1..0]of TKMDirection =
        ((dir_SE,dir_NE),(dir_SW,dir_NW));
begin
  Result := DirectionsBitfield[X,Y];
end;


function KMGetVertexTile(P:TKMPoint; Dir: TKMDirection):TKMPoint;
const
  XBitField: array[TKMDirection] of smallint = (0,0,1,0,1,0,0,0,0);
  YBitField: array[TKMDirection] of smallint = (0,0,0,0,1,0,1,0,0);
begin
  Result := KMPoint(P.X+XBitField[Dir], P.Y+YBitField[Dir]);
end;


function KMGetVertex(Dir: TKMDirection):TKMPointF;
const
  XBitField: array[TKMDirection] of single = (0, 0, 0.7,1,0.7,0,-0.7,-1,-0.7);
  YBitField: array[TKMDirection] of single = (0,-1,-0.7,0,0.7,1, 0.7, 0,-0.7);
begin
  Result := KMPointF(XBitField[Dir], YBitField[Dir]);
end;


function KMGetPointInDir(aPoint:TKMPoint; aDir: TKMDirection): TKMPointDir;
const
  XBitField: array[TKMDirection] of smallint = (0, 0, 1,1,1,0,-1,-1,-1);
  YBitField: array[TKMDirection] of smallint = (0,-1,-1,0,1,1, 1, 0,-1);
begin
  Result.Dir := aDir;
  Result.Loc.X := aPoint.X+XBitField[aDir];
  Result.Loc.Y := aPoint.Y+YBitField[aDir];
end;


function KMNextDirection(aDir: TKMDirection): TKMDirection;
begin
  if aDir < dir_NW then
    Result := Succ(aDir)
  else
    Result := dir_N; //Rewind to start
end;


function KMPrevDirection(aDir: TKMDirection): TKMDirection;
begin
  if aDir > dir_N then
    Result := Pred(aDir)
  else
    Result := dir_NW; //Rewind to end
end;


function KMGetDiagVertex(P1,P2:TKMPoint): TKMPoint;
begin
  //Returns the position of the vertex inbetween the two diagonal points (points must be diagonal)
  Result.X := max(P1.X,P2.X);
  Result.Y := max(P1.Y,P2.Y);
end;


function KMStepIsDiag(P1,P2:TKMPoint):boolean;
begin
  Result := (sign(P2.X-P1.X) <> 0) and (sign(P2.Y-P1.Y) <> 0);
end;


function GetLength(A,B:TKMPoint): single; overload;
begin
  Result := sqrt(sqr(A.x-B.x) + sqr(A.y-B.y));
end;


function GetLength(A,B:TKMPointF): single; overload;
begin
  Result := sqrt(sqr(A.x-B.x) + sqr(A.y-B.y));
end;


//Length as straight and diagonal
function KMLength(A, B: TKMPoint): Single;
begin
  if Abs(A.X-B.X) > Abs(A.Y-B.Y) then
    Result := Abs(A.X-B.X) + Abs(A.Y-B.Y) * 0.41
  else
    Result := Abs(A.Y-B.Y) + Abs(A.X-B.X) * 0.41
end;


function Mix(A,B:TKMPointF; MixValue:single):TKMPointF;
begin
  Result.X := A.X*MixValue + B.X*(1-MixValue);
  Result.Y := A.Y*MixValue + B.Y*(1-MixValue);
end;


procedure KMSwapPoints(var A,B:TKMPoint);
var w:word;
begin
  w:=A.X; A.X:=B.X; B.X:=w;
  w:=A.Y; A.Y:=B.Y; B.Y:=w;
end;


function TypeToString(t:TKMPoint):string;
begin
  Result := '('+inttostr(t.x)+';'+inttostr(t.y)+')';
end;


function TypeToString(T: TKMDirection): String;
const S: array [TKMDirection] of string = ('N/A', 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW');
begin
  Result := S[T];
end;

end.
