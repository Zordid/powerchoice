{$A+,B-,E+,L+,F-,G+,N-,O-,V-,X+}

{$IFDEF IDE}
  {$DEFINE DEBUG}
{$ENDIF}

{$IFDEF DEBUG}
  {$D+,I+,S+,R+}
{$ELSE}
  {$D-,I-,S-,R-}
{$ENDIF}
