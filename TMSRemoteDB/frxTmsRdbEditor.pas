{ --------------------------------------------------------------------------- }
{ TMS RemoteDB FastReport v 6.0 enduser components                            }
{                                                                             }
{ Initially created by: Pierre Pede <p.pede@pipcom.de>                        }
{ --------------------------------------------------------------------------- }
{$I frx.inc}
unit frxtmsrdbEditor;

interface

implementation

uses
  Windows, Classes, SysUtils, Forms, Dialogs, Controls, Variants,
  frxCustomDB, frxEditQueryParams, frxCustomDBEditor, frxDsgnIntf, frxRes
  , RemoteDB.Client.Dataset, RemoteDB.Client.Database
  , frxtmsrdbComponents;

type
  TfrxTmsRdbParamsProperty = class(TfrxClassProperty)
  public
    function GetAttributes: TfrxPropertyAttributes; override;
    function Edit: Boolean; override;
  end;

  TfrxTmsRdbDatabaseProperty = class(TfrxComponentProperty)
  public
    function GetValue: String; override;
    procedure SetValue(const AValue: String); override;
  end;


{-------------------------------------------------------------------------------}
{ TfrxTmsRdbParamsProperty                                                      }
{-------------------------------------------------------------------------------}
function TfrxTmsRdbParamsProperty.GetAttributes: TfrxPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

function TfrxTmsRdbParamsProperty.Edit: Boolean;
var
  oQuery: TfrxTmsRdbQuery;
begin
  Result := False;
  oQuery := TfrxTmsRdbQuery(Component);
  if oQuery.Params.Count <> 0 then
    with TfrxParamsEditorForm.Create(Designer) do
    try
      Params := oQuery.Params;
      Result := ShowModal = mrOk;
      if Result then begin
        oQuery.UpdateParams;
        Self.Designer.UpdateDataTree;
      end;
    finally
      Free;
    end;
end;

{-------------------------------------------------------------------------------}
{ TfrxFDDatabaseProperty                                                        }
{-------------------------------------------------------------------------------}
function TfrxTmsRdbDatabaseProperty.GetValue: String;
var
  db: TfrxTmsRdbDatabase;
begin
  db := TfrxTmsRdbDatabase(GetOrdValue);
  if db = nil then begin
    if (GRDBComponents <> nil) and (GRDBComponents.DefaultDatabase <> nil) then
      Result := GRDBComponents.DefaultDatabase.Name
    else
      Result := frxResources.Get('prNotAssigned');
  end
  else
    Result := inherited GetValue;
end;

{-------------------------------------------------------------------------------}
procedure TfrxTmsRdbDatabaseProperty.SetValue(const AValue: String);
begin
  inherited SetValue(AValue);
  Designer.UpdateDataTree;
end;

initialization

  frxPropertyEditors.Register(TypeInfo(TfrxTmsRdbDatabase), TfrxTmsRdbQuery, 'Database',
    TfrxTmsRdbDatabaseProperty);

  frxPropertyEditors.Register(TypeInfo(TfrxParams), TfrxTmsRdbQuery, 'Params',
    TfrxTmsRdbParamsProperty);

end.

