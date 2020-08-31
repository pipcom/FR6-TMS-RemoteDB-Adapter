{ --------------------------------------------------------------------------- }
{ TMS RemoteDB FastReport v 6.0 enduser components                            }
{                                                                             }
{ Initially created by: Pierre Pede <p.pede@pipcom.de>                        }
{ --------------------------------------------------------------------------- }
{$I frx.inc}

unit frxtmsrdbReg;

interface

procedure Register;

implementation

uses
  Windows, Messages, SysUtils, Classes, DesignIntf, DesignEditors
  ,frxtmsrdbComponents;

procedure Register;
begin
 RegisterComponents('FastReport 6.0', [TfrxTmsRdbComponents]);
end;

end.
