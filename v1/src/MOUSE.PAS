{$B-,D+,F-,I-,L+,N-,O-,R-,S-,V+}
{$M 16384,0,655360}
unit mouse;
interface
  uses dos,crt;

  var buttons               : byte;

  procedure mouseon;
  procedure mouseoff;
  procedure setmouse   (x,y         : integer);
  procedure mousewindow(x1,y1,x2,y2 : integer);
  function  xmouse    : integer;
  function  ymouse    : integer;
  function  lbutton   : boolean;
  function  mbutton   : boolean;
  function  rbutton   : boolean;

implementation

var reg       : registers;

procedure mi(func:integer);
begin
  reg.ax:=func;
  intr($33,reg);
end;

procedure mouseon;
begin
  mi(1);
end;

procedure mouseoff;
begin
  mi(2);
end;

function ymouse:integer;
begin
  mi(3);
  ymouse:=reg.dx;
end;

function xmouse:integer;
begin
  mi(3);
  xmouse:=reg.cx;
end;

procedure setmouse(x,y:integer);
begin
  reg.cx:=x;
  reg.dx:=y;
  mi(4);
end;

procedure mousewindow(x1,y1,x2,y2:integer);
begin
  reg.cx:=x1;
  reg.dx:=x2;
  mi(7);
  reg.cx:=y1;
  reg.dx:=y2;
  mi(8);
end;

function lbutton:boolean;
begin
  lbutton:=false;
  mi(3);
  if (reg.bx and 1)=1 then lbutton:=true;
end;

function mbutton:boolean;
begin
  mbutton:=false;
  mi(3);
  if (reg.bx and 4)=4 then mbutton:=true;
end;

function rbutton:boolean;
begin
  rbutton:=false;
  mi(3);
  if (reg.bx and 2)=2 then rbutton:=true;
end;

begin
  mi(0);
  buttons:=reg.bx;
end.