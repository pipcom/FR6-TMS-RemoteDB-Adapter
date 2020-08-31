{ --------------------------------------------------------------------------- }
{ TMS RemoteDB FastReport v 6.0 enduser components }
{ }
{ Initially created by: Pierre Pede <p.pede@pipcom.de> }
{ --------------------------------------------------------------------------- }
{$I frx.inc}
unit frxtmsrdbRTTI;

interface

implementation

uses
  Windows, Classes, Types, SysUtils, Forms, Variants, DB,
  RemoteDB.Client.Dataset, RemoteDB.Client.Database,
  fs_iinterpreter, frxtmsrdbComponents;

type
  TfrxTmsRdbFunctions = class(TfsRTTIModule)
  private
    function CallMethod(Instance: TObject; ClassType: TClass;
      const MethodName: String; Caller: TfsMethodHelper): Variant;
    function GetProp(Instance: TObject; ClassType: TClass;
      const PropName: String): Variant;
    procedure SetProp(Instance: TObject; ClassType: TClass;
      const PropName: String; Value: Variant);
  public
    constructor Create(AScript: TfsScript); override;
  end;

  { ------------------------------------------------------------------------------- }
constructor TfrxTmsRdbFunctions.Create(AScript: TfsScript);
begin
  inherited Create(AScript);
  with AScript do
  begin
    AddClass(TXDataSet, 'TDataSet');
    AddClass(TRemoteDBDatabase, 'TComponent');

    with AddClass(TfrxTmsRdbDatabase, 'TfrxCustomDatabase') do
    begin
      AddProperty('Database', 'TRemoteDBDatabase', GetProp, nil);
      AddProperty('ServerUri', 'String', GetProp, SetProp);
      AddProperty('Username', 'String', GetProp, SetProp);
      AddProperty('Password', 'String', GetProp, SetProp);
      AddProperty('Connected', 'Boolean', GetProp, SetProp);
    end;

    with AddClass(TfrxTmsRdbQuery, 'TfrxCustomQuery') do
    begin
      AddMethod('procedure EnableControls', CallMethod);
      AddMethod('procedure DisableControls', CallMethod);
      AddMethod(
        'function CreateBlobStream(Field: TField; Mode: TBlobStreamMode) :TStream',
        CallMethod);
      AddMethod('function FindField(const FieldName: String): TField',
        CallMethod);
      AddMethod('procedure SetChangeFieldEvent(cFieldName, cEventName: String)',
        CallMethod);
      AddMethod(
        'procedure SetGetTextFieldEvent(cFieldName, cEventName: String)',
        CallMethod);
      AddMethod('procedure Prepare', CallMethod);
      AddMethod('function ParamByName(const AValue: String): TfrxParamItem',
        CallMethod);
      AddProperty('Query', 'TXDataSet', GetProp, nil);
      AddProperty('ParamCount', 'LongInt', GetProp, nil);
      AddProperty('RecNo', 'LongInt', GetProp, SetProp);
    end;

  end;
end;

{ ------------------------------------------------------------------------------- }
function TfrxTmsRdbFunctions.CallMethod(Instance: TObject; ClassType: TClass;
  const MethodName: String; Caller: TfsMethodHelper): Variant;
begin
  Result := 0;

  if ClassType = TfrxTmsRdbQuery then
  begin
    if MethodName = 'ENABLECONTROLS' then
      TfrxTmsRdbQuery(Instance).EnableControls
    else if MethodName = 'DISABLECONTROLS' then
      TfrxTmsRdbQuery(Instance).DisableControls
    else if MethodName = 'CREATEBLOBSTREAM' then
      Result := frxInteger(TfrxTmsRdbQuery(Instance)
        .CreateBlobStream(TField(frxInteger(Caller.Params[0])),
        Caller.Params[1]))
    else if MethodName = 'FINDFIELD' then
      Result := frxInteger(TfrxTmsRdbQuery(Instance)
        .FindField(Caller.Params[0]))
    else if MethodName = 'SETCHANGEFIELDEVENT' then
      TfrxTmsRdbQuery(Instance).SetChangeFieldEvent(Caller.Params[0],
        Caller.Params[1])
    else if MethodName = 'SETGETTEXTFIELDEVENT' then
      TfrxTmsRdbQuery(Instance).SetGetTextFieldEvent(Caller.Params[0],
        Caller.Params[1])
    else if MethodName = 'PREPARE' then
      TfrxTmsRdbQuery(Instance).Prepare
    else if MethodName = 'PARAMBYNAME' then
      Result := frxInteger(TfrxTmsRdbQuery(Instance)
        .ParamByName(Caller.Params[0]));
  end;

end;

{ ------------------------------------------------------------------------------- }
function TfrxTmsRdbFunctions.GetProp(Instance: TObject; ClassType: TClass;
  const PropName: String): Variant;
begin
  Result := 0;
  if ClassType = TfrxTmsRdbDatabase then
  begin
    if PropName = 'SERVERURI' then
      Result := TfrxTmsRdbDatabase(Instance).ServerUri
    else if PropName = 'USERNAME' then
      Result := TfrxTmsRdbDatabase(Instance).Username
    else if PropName = 'PASSWORD' then
      Result := TfrxTmsRdbDatabase(Instance).Password
    else if PropName = 'CONNECTED' then
      Result := frxInteger(TfrxTmsRdbDatabase(Instance).Connected);
  end
  else if ClassType = TfrxTmsRdbQuery then
  begin
    if PropName = 'QUERY' then
      Result := frxInteger(TfrxTmsRdbQuery(Instance).Query)
    else if PropName = 'PARAMCOUNT' then
      Result := TXDataSet(Instance).Params.Count
    else if PropName = 'RECNO' then
      Result := TXDataSet(Instance).RecNo;
  end;
end;

{ ------------------------------------------------------------------------------- }
procedure TfrxTmsRdbFunctions.SetProp(Instance: TObject; ClassType: TClass;
  const PropName: String; Value: Variant);
begin
  if ClassType = TfrxTmsRdbDatabase then
  begin

    if PropName = 'SERVERURI' then
      TfrxTmsRdbDatabase(Instance).ServerUri := Value
    else if PropName = 'USERNAME' then
      TfrxTmsRdbDatabase(Instance).Username := Value
    else if PropName = 'PASSWORD' then
      TfrxTmsRdbDatabase(Instance).Password := Value
    else if PropName = 'CONNECTED' then
      TfrxTmsRdbDatabase(Instance).Connected := Value;

  end
  else if ClassType = TfrxTmsRdbQuery then
  begin
    if PropName = 'RECNO' then
      TfrxTmsRdbQuery(Instance).RecNo := Value;
  end;
end;

{ ------------------------------------------------------------------------------- }
initialization

fsRTTIModules.Add(TfrxTmsRdbFunctions);

finalization

if fsRTTIModules <> nil then
  fsRTTIModules.Remove(TfrxTmsRdbFunctions);

end.
