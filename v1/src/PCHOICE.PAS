Program Power_Choice;
Uses PCH_DEF;
Const Version   = 'Ver 1.0e';
      CopyRight = ' (C) Softwhere Associates';
      Serial    = '--Invalid-';

Begin
  PCH_DEF.Version:=Version;
  PCH_DEF.Copyright:=Copyright;
  PCH_DEF.Serial:=Serial;
  Check_Low_Level;
  Prepare_Screen;
  Read_Menu;
  SetGroupItem;
  Menu.Run;
End.