{$A+,B-,E+,L+,F-,G+,N-,O-,V-,X+}

{$IFDEF CHECKING}
  {$I+,S+,R-}
{$ELSE}
  {$I-,S-,R-}
{$ENDIF}

{$IFDEF DEBUG}
  {$D+}
{$ELSE}
  {$D-}
{$ENDIF}
