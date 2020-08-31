{ --------------------------------------------------------------------------- }
{ TMS RemoteDB FastReport v 6.0 enduser components                            }
{                                                                             }
{ Initially created by: Pierre Pede <p.pede@pipcom.de>                        }
{ --------------------------------------------------------------------------- }
{$I frx.inc}
unit frxtmsrdbComponents;

interface

uses
  Windows, Classes, SysUtils, DB, frxClass, frxCustomDB, frxXML, Variants, RemoteDB.Client.Dataset,
  RemoteDB.Client.Database, System.Generics.Collections,
  Sparkle.Http.Client,
  Sparkle.Http.Headers,
  Sparkle.Sys.Timer
{$IFDEF QBUILDER}
    , fqbClass
{$ENDIF};

type

  THackRemoteDBDatabase = class(TRemoteDBDatabase);

  TfrxRemoteDBProvider = class(TRemoteDBProvider)
  protected
    property DB;
  end;

  TfrxXDataset = class(TXDataset)
  protected
    procedure InitFieldDefsFromProvider(Provider: TXDatasetProvider);
  end;

{$IFDEF DELPHI16}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
{$ENDIF}
  TfrxTmsRdbComponents = class(TfrxDBComponents)
  private
    FDefaultDatabase: TRemoteDBDatabase;
    FOldComponents: TfrxTmsRdbComponents;
    procedure SetDefaultDatabase(const AValue: TRemoteDBDatabase);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetDescription: String; override;
  published
    property DefaultDatabase: TRemoteDBDatabase read FDefaultDatabase write SetDefaultDatabase;
  end;

  TfrxTmsRdbDatabase = class(TfrxCustomDatabase)
  private
    FDatabase: TRemoteDBDatabase;
    function GetSqlDialect: String;

    function GetServerUri: string;
    procedure SetPassword(const Value: string);
    procedure SetServerUri(const Value: string);
    procedure SetUsername(const Value: String);
    function GetPassword: string;
    function GetUsername: String;

  protected
    procedure SetConnected(AValue: Boolean); override;
    function GetConnected: Boolean; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function GetDescription: String; override;

    procedure SetLogin(const ALogin, APassword: String); override;

    function ToString: WideString; override;
    procedure FromString(const AConnection: WideString); override;

    property Database: TRemoteDBDatabase read FDatabase;
    property SqlDialect: String read GetSqlDialect;
  published
    property ServerUri: string read GetServerUri write SetServerUri;

    property Connected;
    property Password: string read GetPassword write SetPassword;
    property Username: String read GetUsername write SetUsername;

  end;

  TfrxDataSetNotifyEvent = type String;
  TfrxFilterRecordEvent = type String;

  TfrxTmsRdbQuery = class(TfrxCustomQuery)
  private
    FLocked: boolean;
    FDatabase: TfrxTmsRdbDatabase;

    FAfterOpen: TfrxDataSetNotifyEvent;
    FBeforeScroll: TfrxDataSetNotifyEvent;
    FOnFilterRecord: TfrxFilterRecordEvent;
    FBeforeOpen: TfrxDataSetNotifyEvent;
    FAfterScroll: TfrxDataSetNotifyEvent;

    FChangeFieldEventList: TStrings;
    FGetTextFieldEventList: TStrings;

    procedure SetDatabase(const Value: TfrxTmsRdbDatabase);

    procedure DoAfterOpen(Dataset: TDataSet);
    procedure DoBeforeOpen(Dataset: TDataSet);
    procedure DoAfterScroll(Dataset: TDataSet);
    procedure DoBeforeScroll(Dataset: TDataSet);
    procedure DoFilterRecord(Dataset: TDataSet; var Accept: Boolean);

    procedure DoChangeField(Field: TField);
    procedure DoGetTextField(Field: TField; var Text: String; DisplayText: Boolean);

    function GetRecNo: LongInt;
    procedure SetRecNo(const Value: LongInt);
    function GetQuery: TfrxXDataset;
    procedure SetQuery(const Value: TfrxXDataset);
  protected
    procedure SetSQL(Value: TStrings); override;
    function GetSQL: TStrings; override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure SetMaster(const AValue: TDataSource); override;
    procedure SetMasterFields(const AValue: String); override;
    //procedure OnChangeSQL(Sender: TObject); override;
    procedure SetName(const AName: TComponentName); override;
  public
    constructor Create(AOwner: TComponent); override;
    constructor DesignCreate(AOwner: TComponent; AFlags: Word); override;
    destructor Destroy(); override;

    class function GetDescription(): String; override;
    procedure WriteNestedProperties(Item: TfrxXmlItem; aAcenstor: TPersistent = nil); override;
    function ReadNestedProperty(Item: TfrxXmlItem): Boolean; override;

    procedure BeforeStartReport(); override;
    procedure FetchParams(); virtual;
    procedure UpdateParams(); override;

    procedure SetChangeFieldEvent(cFieldName, cEventName: String);
    procedure SetGetTextFieldEvent(cFieldName, cEventName: String);
    procedure GetFieldList(List: TStrings); override;


    procedure EnableControls();
    procedure DisableControls();
    function CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream;
    function FindField(const FieldName: String): TField;
    procedure Prepare; virtual;
    // {$IFDEF QBUILDER}
    // function QBEngine :TfqbEngine; override;
    // {$ENDIF}
    property Query: TfrxXDataset read GetQuery write SetQuery;
    property RecNo: LongInt read GetRecNo write SetRecNo;

  published
    property SQL;
    property Database: TfrxTmsRdbDatabase read FDatabase write SetDatabase;
    property MasterFields;
    property Active default False;

    property AfterOpen: TfrxDataSetNotifyEvent read FAfterOpen write FAfterOpen;
    property BeforeOpen: TfrxDataSetNotifyEvent read FBeforeOpen write FBeforeOpen;
    property AfterScroll: TfrxDataSetNotifyEvent read FAfterScroll write FAfterScroll;
    property BeforeScroll: TfrxDataSetNotifyEvent read FBeforeScroll write FBeforeScroll;
    property OnFilterRecord: TfrxFilterRecordEvent read FOnFilterRecord write FOnFilterRecord;
    property Left;
    property Top;

  end;

  TRdbCharSet = {$IFDEF NEXTGEN} TSysCharSet {$ELSE} set of AnsiChar {$ENDIF};
(*

    {$IFDEF QBUILDER}
    TfrxEngineFD = class(TfqbEngine)
    private
    FQuery: TFDQuery;
    public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ReadTableList(ATableList: TStrings); override;
    procedure ReadFieldList(const ATableName: string; var AFieldList: TfqbFieldList); override;
    function ResultDataSet: TDataSet; override;
    procedure SetSQL(const AValue: string); override;
    end;
    {$ENDIF}

  *)

var
  GRDBComponents: TfrxTmsRdbComponents;

implementation

uses
  Dialogs, StrUtils,
  frxTmsRdbRTTI,
  IOUtils,
  ZLib, Bcl.Utils,
  Sparkle.Json.Reader,
  Sparkle.Utils,
  {$IFNDEF NO_EDITORS}
  frxtmsrdbEditor,
  {$ENDIF}
  frxDsgnIntf, frxUtils, frxRes;

//  {$R *.res}

{$WARNINGS OFF}
function RdbInSet(AChar: Char; ASet: TRdbCharSet): Boolean;
begin
  if Ord(AChar) <= 255 then
    Result := AChar in ASet
  else
    Result := False;
end;
{$WARNINGS ON}

{ ------------------------------------------------------------------------------- }
{ TfrxTmsRdbDatabase }
{ ------------------------------------------------------------------------------- }
constructor TfrxTmsRdbDatabase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDatabase := TRemoteDBDatabase.Create(nil);
  Component := FDatabase;
end;

{ ------------------------------------------------------------------------------- }
destructor TfrxTmsRdbDatabase.Destroy;
begin
  inherited Destroy;
end;

{ ------------------------------------------------------------------------------- }
class function TfrxTmsRdbDatabase.GetDescription(): String;
begin
  Result := 'RDB Database';
end;

function TfrxTmsRdbDatabase.GetPassword: string;
begin
  result := FDatabase.Password;
end;

{ ------------------------------------------------------------------------------- }
function TfrxTmsRdbDatabase.GetConnected: Boolean;
begin
  Result := FDatabase.Connected;
end;

function TfrxTmsRdbDatabase.GetServerUri: string;
begin
  Result := FDatabase.ServerUri;
end;

function TfrxTmsRdbDatabase.GetSqlDialect: String;
begin
  Result := FDatabase.SqlDialect;
end;

function TfrxTmsRdbDatabase.GetUsername: String;
begin
  result := FDatabase.username;
end;

{ ------------------------------------------------------------------------------- }
procedure TfrxTmsRdbDatabase.SetConnected(AValue: Boolean);
begin
  BeforeConnect(AValue);
  FDatabase.Connected := AValue;
end;

{ ------------------------------------------------------------------------------- }
procedure TfrxTmsRdbDatabase.SetLogin(const ALogin, APassword: String);
begin
  FDatabase.UserName := ALogin;
  FDatabase.Password := APassword;
end;

procedure TfrxTmsRdbDatabase.SetServerUri(const Value: string);
begin
  FDatabase.ServerUri := Value;
end;

{ ------------------------------------------------------------------------------- }
procedure TfrxTmsRdbDatabase.FromString(const AConnection: WideString);
begin
  FDatabase.ServerUri := AConnection;
end;

procedure TfrxTmsRdbDatabase.SetPassword(const Value: string);
begin
  FDatabase.Password := Value;
end;

procedure TfrxTmsRdbDatabase.SetUsername(const Value: String);
begin
  FDatabase.Username := Value;
end;

{ ------------------------------------------------------------------------------- }
function TfrxTmsRdbDatabase.ToString: WideString;
begin
  Result := FDatabase.ServerUri;
end;

{ TfrxTmsRdbComponents }
constructor TfrxTmsRdbComponents.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOldComponents := GRDBComponents;
  GRDBComponents := Self;
end;

{ ------------------------------------------------------------------------------- }
destructor TfrxTmsRdbComponents.Destroy();
begin
  if GRDBComponents = Self then
    GRDBComponents := FOldComponents;
  inherited Destroy();
end;

function TfrxTmsRdbComponents.GetDescription: String;
begin
  Result := 'RDB';
end;

procedure TfrxTmsRdbComponents.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = FDefaultDatabase) and (Operation = opRemove) then
    FDefaultDatabase := nil;
end;

procedure TfrxTmsRdbComponents.SetDefaultDatabase(const AValue: TRemoteDBDatabase);
begin
  if FDefaultDatabase <> AValue then
  begin
    if FDefaultDatabase <> nil then
      FDefaultDatabase.RemoveFreeNotification(Self);
    FDefaultDatabase := AValue;
    if FDefaultDatabase <> nil then
      FDefaultDatabase.FreeNotification(Self);
  end;
end;

{ ------------------------------------------------------------------------------- }
{ TfrxTmsRdbQuery }

{$WARNINGS OFF}
function CheckInSet(AChar: Char; ASet: TSysCharSet): Boolean;
begin
  if Ord(AChar) <= 255 then
    Result := AChar in ASet
  else
    Result := False;
end;
{$WARNINGS ON}

procedure frxParamsToRdbParams(ADataSet: TfrxCustomDataset; AFrxParams: TfrxParams; ARdbParams: TParams;
  AMasterDetail: Boolean = False);
var
  i, j, iFld: Integer;

  lDesignTime: Boolean;
  oQuery: TXDataset;
  oParam: TParam;
  oFrxParam: TfrxParamItem;
  oMasterFields: TStringList;
  lSkip: Boolean;
  sExpr: String;
  vRes: Variant;

  function CanExpandEscape(AReport: TfrxReport; AExpr: String): Boolean;
  var
    sVar: String;
    i: Integer;
    lIsVar: Boolean;

  begin

    Result := oQuery.Database <> nil;

    if Result then
    begin

      sVar := AExpr;

      // 1st iteration of check
      lIsVar := (sVar[1] = '<') and (sVar[Length(sVar)] = '>');
      if lIsVar then
      begin

        i := AReport.Variables.IndexOf(Copy(sVar, 2, Length(sVar) - 2));

        Result := (i <> -1);

        if Result then
          vRes := VarToStr(AReport.Variables.Items[i].Value)
        else
          Exit;

      end;

    end;

  end;

begin
  oFrxParam := nil;

  oQuery := TfrxTmsRdbQuery(ADataSet).Query;

  if oQuery = nil then
    Exit;

  lDesignTime := (ADataSet.IsLoading or ADataSet.IsDesigning);

    for i := 0 to ARdbParams.Count - 1 do
    begin

      oParam := ARdbParams[i];
      j := AFrxParams.IndexOf(oParam.Name);

      if j <> -1 then
      begin
        oFrxParam := AFrxParams[j];
        oParam.Clear;
        oParam.DataType := oFrxParam.DataType;
        oParam.Bound := lDesignTime;
        if AMasterDetail and (ADataSet is TfrxTmsRdbQuery) then
        begin
          oMasterFields := TStringList.Create();
          try
            oMasterFields.Delimiter := ';';
            oMasterFields.DelimitedText := ADataSet.MasterFields;
            lSkip := False;
            for iFld := 0 to oMasterFields.Count - 1 do
            begin
              lSkip := AnsiCompareText(oParam.Name, oMasterFields[iFld]) = 0;
              if lSkip then Break;
            end;
            if lSkip then Continue;
          finally
            oMasterFields.Free;
          end;
        end;

      end;

      if Assigned(oFrxParam) then
      begin

        sExpr := oFrxParam.Expression;

        if Trim(sExpr) <> '' then
        begin

          if ADataSet.Report <> nil then
            if CanExpandEscape(ADataSet.Report, sExpr) then
              oFrxParam.Value := vRes
            else if not(ADataSet.IsLoading or ADataSet.IsDesigning) then
            begin

              ADataSet.Report.CurObject := ADataSet.Name;
              oFrxParam.Value := ADataSet.Report.Calc(oFrxParam.Expression);

            end
            else
            begin

              if oParam.DataType in [ftString, ftWideString, ftFixedWideChar, ftWideMemo, ftFmtMemo, ftMemo] then
                oFrxParam.Value := ''
              else if oParam.DataType in [ftVariant, ftInteger, ftWord, ftLargeint, ftTimeStamp, ftFMTBcd,
                ftOraTimeStamp, ftLongWord, ftShortint, ftByte, ftExtended, ftSingle] then
                oFrxParam.Value := 0
              else
                oFrxParam.Value := Unassigned;

            end;

        end;

        if not VarIsEmpty(oFrxParam.Value) then
        begin
          oParam.Bound := True;
          oParam.Value := oFrxParam.Value;
        end;

      end;

    end;

end;

procedure frxRdbParamsToParams(ADataSet :TfrxCustomDataSet; ARdbParams :TParams; AfrxParams :TfrxParams; AIgnoreDuplicates :Boolean = True; AMasterDataSet :TDataSet = Nil);
var
  i, j      :Integer;
  NewParams :TfrxParams;
begin

 if AfrxParams = nil then
   Exit;

 NewParams := TfrxParams.Create();
 try

   for i := 0 to ARdbParams.Count - 1 do
     if not ((NewParams.IndexOf(ARdbParams[i].Name) <> -1) and AIgnoreDuplicates) then
       with NewParams.Add() do begin

          Name     := ARdbParams[i].Name;
          j        := AfrxParams.IndexOf(Name);
          DataType := ARdbParams.Items[i].DataType;

          if Assigned(AMasterDataSet) and
             Assigned(AMasterDataSet.FindField(Name)) and
             (DataType = ftUnknown) then
            DataType := AMasterDataSet.FindField(Name).DataType;

          if j <> -1 then begin
            Value := AfrxParams.Items[j].Value;
            Expression := AfrxParams.Items[j].Expression;
          end else
            Value := ARdbParams.Items[i].Value;

       end;

   AfrxParams.Clear;
   AfrxParams.Assign(NewParams);

 finally
    NewParams.Free;
 end;

end;


procedure TfrxTmsRdbQuery.BeforeStartReport;
begin
  if Query = nil then
    Exit;

  SetDatabase(FDatabase);
end;

constructor TfrxTmsRdbQuery.Create(AOwner: TComponent);
begin
  FLocked := false;

  try
    Query := TfrxXDataset.Create(nil);
  except
    Query := nil;
  end;

  SetDatabase(nil);

  Query.AfterOpen := DoAfterOpen;
  Query.BeforeOpen := DoBeforeOpen;
  Query.AfterScroll := DoAfterScroll;
  Query.BeforeScroll := DoBeforeScroll;
  Query.OnFilterRecord := DoFilterRecord;

  FChangeFieldEventList := TStringList.Create();
  FGetTextFieldEventList := TStringList.Create();

  inherited Create(AOwner);

  frComponentStyle := frComponentStyle + [csHandlesNestedProperties];

  if Query = nil then
    raise Exception.Create('DataSet is nil.');
end;

function TfrxTmsRdbQuery.CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream;
begin
  Result := Query.CreateBlobStream(Field, Mode);
end;

constructor TfrxTmsRdbQuery.DesignCreate(AOwner: TComponent; AFlags: Word);
var
  i: Integer;
  l: TList;
begin
  inherited DesignCreate(AOwner, AFlags);
  l := Report.AllObjects;
  for i := 0 to l.Count - 1 do
    if TObject(l[i]) is TfrxTmsRdbDatabase then
    begin
      SetDatabase(TfrxTmsRdbDatabase(l[i]));
      Break;
    end;
end;

destructor TfrxTmsRdbQuery.Destroy;
begin
  FreeAndNil(FChangeFieldEventList);
  FreeAndNil(FGetTextFieldEventList);
  inherited Destroy();
end;

procedure TfrxTmsRdbQuery.DisableControls;
begin
  Query.DisableControls;
end;

procedure TfrxTmsRdbQuery.DoAfterOpen(Dataset: TDataSet);
var
  vArr: Variant;
begin
  if FAfterOpen <> '' then
  begin
    vArr := VarArrayOf([frxInteger(Dataset)]);
    if Report <> nil then
      Report.DoParamEvent(FAfterOpen, vArr);
  end;
end;

procedure TfrxTmsRdbQuery.DoAfterScroll(Dataset: TDataSet);
var
  vArr: Variant;
begin
  if FAfterScroll <> '' then
  begin
    vArr := VarArrayOf([frxInteger(Dataset)]);
    if Report <> nil then
      Report.DoParamEvent(FAfterScroll, vArr);
  end;
end;

procedure TfrxTmsRdbQuery.DoBeforeOpen(Dataset: TDataSet);
var
  vArr: Variant;
begin
  if FBeforeOpen <> '' then
  begin
    vArr := VarArrayOf([frxInteger(Dataset)]);
    if Report <> nil then
      Report.DoParamEvent(FBeforeOpen, vArr);
  end;
end;

procedure TfrxTmsRdbQuery.DoBeforeScroll(Dataset: TDataSet);
var
  vArr: Variant;
begin
  if FBeforeScroll <> '' then
  begin
    vArr := VarArrayOf([frxInteger(Dataset)]);
    if Report <> nil then
      Report.DoParamEvent(FBeforeScroll, vArr);
  end;
end;

//procedure TfrxTmsRdbQuery.OnChangeSQL(Sender: TObject);
//var
//  i, ind: Integer;
//  frxParam: TfrxParamItem;
//  oParam: TParam;
//  nCount: Integer;
//  tmpSql: string;
//begin
//
//  if not FLocked then
//  begin
//    FLocked := True;
//    try
//
////      nCount := Query.Params.Count;
////      tmpSql := Query.SQL.Text;
////
////      // needed to update parameters
////      Query.SQL.Text := '';
////      Query.SQL.Text := tmpSql;
//
////      if (Query.Params.Count <> nCount) and (MasterFields <> '') then
////        frxParamsToRdbParams(Self, Params, Query.Params);
//
//      inherited;
//
//      // fill datatype automatically, if possible
////      for i := 0 to Query.Params.Count - 1 do
////      begin
////
////        oParam := Query.Params[i];
////        ind := Params.IndexOf(oParam.Name);
////
////        if ind <> -1 then
////        begin
////
////          frxParam := Params[ind];
////
////          if (frxParam.DataType = ftUnknown) and Self.IsDesigning then
////          begin
////
////            if Assigned(Self.Master) and Assigned(Self.Master.Dataset) then
////            begin
////
////              if (not Self.Master.Dataset.Active) and (Self.Master.Dataset.FieldCount = 0) and
////                (Self.Master.FieldAliases.IndexOfName(oParam.Name) > -1) then
////                Self.Master.Dataset.Active := True;
////
////              if Assigned(Self.Master.Dataset.FindField(oParam.Name)) then
////              begin
////                frxParam.DataType := Self.Master.Dataset.FindField(oParam.Name).DataType;
////                oParam.DataType := frxParam.DataType;
////              end; { if }
////
////            end; { if }
////
////          end; { if }
////
////          if (frxParam.DataType = ftUnknown) and (oParam.DataType <> ftUnknown) then
////            frxParam.DataType := oParam.DataType;
////
////        end; { if }
////
////      end; { for }
//    finally
//      FLocked := False;
//
//    end;
//  end;
//
//end;

procedure TfrxTmsRdbQuery.DoChangeField(Field: TField);
var
  vArr: Variant;
begin
  if not Assigned(Field) then
  begin
    raise Exception.Create('DoChangeField: Field not Found.');
    Exit;
  end;
  vArr := VarArrayOf([frxInteger(Field)]);
  if Report <> nil then
    Report.DoParamEvent(FChangeFieldEventList.Values[Field.FieldName], vArr);
end;

procedure TfrxTmsRdbQuery.DoFilterRecord(Dataset: TDataSet; var Accept: Boolean);
var
  vArr: Variant;
begin
  if FOnFilterRecord <> '' then
  begin
    vArr := VarArrayOf([frxInteger(Dataset), Accept]);
    if Report <> nil then
      Report.DoParamEvent(FOnFilterRecord, vArr);
    Accept := vArr[1];
  end;
end;

procedure TfrxTmsRdbQuery.DoGetTextField(Field: TField; var Text: String; DisplayText: Boolean);
var
  vArr: Variant;
begin
  if not Assigned(Field) then
  begin
    raise Exception.Create('DoGetTextField: Field not Found.');
    Exit;
  end;
  vArr := VarArrayOf([frxInteger(Field), Text, DisplayText]);
  if Report <> nil then
    Report.DoParamEvent(FGetTextFieldEventList.Values[Field.FieldName], vArr);
  Text := vArr[1];
end;

procedure TfrxTmsRdbQuery.EnableControls;
begin
  Query.EnableControls;
end;

procedure TfrxTmsRdbQuery.FetchParams;
begin
  if Query = nil then
    Exit;
  frxRdbParamsToParams(Self, Query.Params, Params, IgnoreDupParams);
end;

function TfrxTmsRdbQuery.FindField(const FieldName: String): TField;
begin
  Result := Query.FindField(FieldName);
end;

class function TfrxTmsRdbQuery.GetDescription: String;
begin
  Result := 'RDB Query';
end;

procedure TfrxTmsRdbQuery.GetFieldList(List: TStrings);
var
  upperSQL: string;
  afterPos: integer;
  newSql: string;
  lProvider: TXDatasetProvider;
  lDatabase: TRemoteDBDatabase;
  I: Integer;
begin
  inherited;
  upperSQL := uppercase(trim(Sql.text));
  if (length(upperSQL) = 0) then exit;

  if Assigned(Query.database) and (List.Count = 0) then
  begin
    afterPos := Pos('WHERE', upperSQL);
    if (afterPos = 0) then
    begin
      afterPos := Pos('GROUP BY', upperSQL);
      if (afterPos = 0) then
      begin
        afterPos := Pos('HAVING', upperSQL);
        if (afterPos = 0) then
        begin
          afterPos := Pos('UNION', upperSQL);
          if (afterPos = 0) then
          begin
            afterPos := Pos('ORDER BY', upperSQL);
          end;
        end;
      end;
    end;

    if afterPos > 0 then
    begin
      newSQL := trim(copy(sql.text,1, afterPos-1))+#13#10+'WHERE 1=2';
    end
    else
    begin
      newSQL := trim(sql.text)+#13#10+'WHERE 1=2';
    end;

    if Assigned(TfrxXDataset(DataSet).Database) then
    begin
      lDatabase := TRemoteDBDatabase(TfrxXDataset(DataSet).Database);
      lProvider := THackRemoteDBDatabase(lDataBase).CreateProvider;
      try
        lProvider.changeSql(newSql);
        TfrxXDataset(DataSet).InitFieldDefsFromProvider(lProvider);
        TfrxXDataset(DataSet).FieldDefs.Updated := true;
        list.beginUpdate;
        try
          for I := 0 to TfrxXDataset(DataSet).FieldDefs.count -1 do
          begin
            list.add( TfrxXDataset(DataSet).FieldDefs[i].name);
          end;
        finally
          list.EndUpdate;
        end;
      finally
        FreeAndNil(lProvider);
      end;
    end;
  end;
end;

function TfrxTmsRdbQuery.GetQuery: TfrxXDataset;
begin
  result := TfrxXDataset(DataSet);
end;

function TfrxTmsRdbQuery.getRecNo: LongInt;
begin
  Result := Query.RecNo;
end;

function TfrxTmsRdbQuery.GetSQL: TStrings;
begin
  Result := Query.Sql;
end;

procedure TfrxTmsRdbQuery.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);
  if (AOperation = opRemove) and (AComponent = FDatabase) then
    SetDatabase(nil);
end;

procedure TfrxTmsRdbQuery.Prepare;
begin
  UpdateParams;
end;

procedure TfrxTmsRdbQuery.SetChangeFieldEvent(cFieldName, cEventName: String);
begin
  if not Assigned(Query.FindField(cFieldName)) then
  begin
    raise Exception.Create('SetChangeFieldEvent: Field ' + cFieldName + ' not Found.');
    Exit;
  end;
  if cEventName <> '' then
  begin
    FChangeFieldEventList.Values[cFieldName] := cEventName;
    Query.FieldByName(cFieldName).OnChange := DoChangeField;
  end
  else
  begin
    with FChangeFieldEventList do
      Delete(IndexOfName(cFieldName));
    Query.FieldByName(cFieldName).OnChange := nil;
  end;
end;

procedure TfrxTmsRdbQuery.SetDatabase(const Value: TfrxTmsRdbDatabase);
begin

 if Query = nil then Exit;

 FDatabase := Value;

if Value <> nil then
   Query.database := Value.Database
 else
 if GRDBComponents <> nil then
   Query.database := GRDBComponents.DefaultDatabase
 else
   Query.database := nil;

 DBConnected := Query.database <> nil;
end;

procedure TfrxTmsRdbQuery.SetRecNo(const Value: LongInt);
begin
  Query.RecNo := Value;
end;

procedure TfrxTmsRdbQuery.SetGetTextFieldEvent(cFieldName, cEventName: String);
begin
  if not Assigned(Query.FindField(cFieldName)) then
  begin
    raise Exception.Create('SetGetTextFieldEvent: Field ' + cFieldName + ' not Found.');
    Exit;
  end;

  if cEventName <> '' then
  begin
    FGetTextFieldEventList.Values[cFieldName] := cEventName;
    Query.FieldByName(cFieldName).OnGetText := DoGetTextField;
  end
  else
  begin
    with FGetTextFieldEventList do
      Delete(IndexOfName(cFieldName));
    Query.FieldByName(cFieldName).OnGetText := nil;
  end;
end;

procedure TfrxTmsRdbQuery.SetMaster(const AValue: TDataSource);
begin
  if Query = nil then Exit;
  Query.DataSource := AValue;
end;

procedure TfrxTmsRdbQuery.SetMasterFields(const AValue: String);
var
  oMasterFields: TStringList;
  i: Integer;
  j: Integer;
  tmpSQL: string;
  selectStmt: string;
  afterStmt: string;
  wherePos: Integer;
  afterPos: Integer;
  whereStmt: string;
  andStmt: string;
  oParam: TParam;
begin
  if Query = nil then
    Exit;
  if IsDesigning then
  begin
    oMasterFields := TStringList.Create();
    try
      oMasterFields.Delimiter := ';';
      oMasterFields.DelimitedText := MasterFields;
      for i := oMasterFields.Count - 1 downto 0 do
      begin
        j := Params.IndexOf(oMasterFields.ValueFromIndex[i]);
        if j <> -1 then
          oMasterFields.Delete(i);
      end;

      if oMasterFields.Count > 0 then
      begin
        tmpSQL := uppercase(SQL.Text);
        wherePos := Pos('WHERE', tmpSQL);
        afterPos := Pos('GROUP BY', tmpSQL);
        if (afterPos = 0) then
        begin
          afterPos := Pos('HAVING', tmpSQL);
          if (afterPos = 0) then
          begin
            afterPos := Pos('UNION', tmpSQL);
            if (afterPos = 0) then
            begin
              afterPos := Pos('ORDER BY', tmpSQL);
            end;
          end;
        end;

        if wherePos = 0 then
          whereStmt := ' WHERE'
        else
          whereStmt := ' AND' ;

        andStmt := '';
        for i := 0 to oMasterFields.Count - 1 do
        begin
          if i > 0 then
            andStmt := ' AND';
          whereStmt := whereStmt + andStmt + ' (' + oMasterFields.Names[i] + '=:' + oMasterFields.ValueFromIndex[i] + ')';
        end;

        tmpSQL := trim(SQL.Text);

        if (afterPos = 0) then
        begin
          selectStmt := tmpSQL;
          tmpSql :=  selectStmt + #13#10 + Trim(whereStmt);
        end
        else if (wherePos > 0) then
        begin
          selectStmt := trim(Copy(tmpSQL, 1, afterPos-1));
          afterStmt := trim(Copy(tmpSQL, afterPos));
          tmpSQL :=  selectStmt + #13#10 + whereStmt + #13#10 + afterStmt;
        end
        else
        begin
          selectStmt := trim(Copy(tmpSQL, 1, afterPos-1));
          afterStmt := trim(Copy(tmpSQL, afterPos));
          tmpSQL :=  selectStmt + #13#10 + whereStmt + #13#10 + afterStmt;
        end;
        SQL.text := tmpSQL;

        for I := 0 to Query.Params.Count -1 do
          begin
            oParam := Query.Params[i];
            if oParam.DataType = ftUnknown then
            begin
              if Assigned(Master.Dataset) then
              begin
                j := Master.Dataset.FieldDefs.IndexOf(oParam.Name);
                if (j <> -1) then
                begin
                  oParam.DataType := Master.Dataset.FieldDefs[j].DataType;
                  j := self.Params.IndexOf(oParam.Name);
                  if (j <> -1) then
                  begin
                    Params[j].DataType := oParam.DataType;
                  end;
                end;
              end;
            end;
          end;

      end;
    finally
      oMasterFields.Free;
    end;

  end;
end;

procedure TfrxTmsRdbQuery.SetName(const AName: TComponentName);
begin
  inherited;
  if Query = nil then Exit;
  Query.Name := AName;
end;

procedure TfrxTmsRdbQuery.SetQuery(const Value: TfrxXDataset);
begin
  DataSet := Value;
end;

procedure TfrxTmsRdbQuery.WriteNestedProperties(Item: TfrxXmlItem; aAcenstor: TPersistent = nil);
begin
  if Self.Params.Count > 0 then
    frxWriteCollection(Self.Params, 'Parameters', Item, Self, nil);
end;

function TfrxTmsRdbQuery.ReadNestedProperty(Item: TfrxXmlItem): Boolean;
begin
  Result := True;
  if CompareText(Item.Name, 'Parameters') = 0 then
  begin
    Self.Params.Clear;
    frxReadCollection(Self.Params, Item, Self, nil)
  end
  else
    Result := False;

  if Result then  UpdateParams();
end;

procedure TfrxTmsRdbQuery.SetSQL(Value: TStrings);
begin
  Query.SQL.Assign(Value);
end;

procedure TfrxTmsRdbQuery.UpdateParams;
begin
  if Query = nil then Exit;
  frxParamsToRdbParams(Self, Params, Query.Params, ASSIGNED(Master));
end;

{ TfrxXDataset }

procedure TfrxXDataset.InitFieldDefsFromProvider(Provider: TXDatasetProvider);
var
  RowNumIndex: integer;
  I: Integer;
  Fld: TField;
  GenDef: TXFieldDef;
  FldDef: TFieldDef;
  lParams: TRDBParams;

const
  RowNumFieldName = 'row_num_internal';

begin
  FieldDefs.Clear;
  if Provider = nil then Exit;
  if not (csDesigning in ComponentState) and (FieldCount > 0) then
    InitFieldDefsFromFields
  else
  begin
    lParams := TRDBParams.Create;
    try
      for GenDef in Provider.GetFieldDefs(lParams) do
      begin
        FldDef := FieldDefs.AddFieldDef;
        FldDef.Name := GenDef.Name;
        FldDef.DataType := GenDef.DataType;
        FldDef.Size := GenDef.Size;
        FldDef.Required := GenDef.Required;
        FldDef.Precision := GenDef.Precision;
      end;
    finally
      lParams.Free;
    end;
  end;

  RowNumIndex := FieldDefs.IndexOf(RowNumFieldName);
  if RowNumIndex >= 0 then
    FieldDefs.Delete(RowNumIndex);

  for I := 0 to FieldDefs.Count - 1 do
  begin
    Fld := Self.FindField(FieldDefs[I].Name);
    if Fld = nil then Continue;
    if Fld.Size <> FieldDefs[I].Size then
      FieldDefs[I].Size := Fld.Size;
  end;
end;

initialization

frxResources.Add('TfrxDataSetNotifyEvent', 'PascalScript=(DataSet: TDataSet);' + #13#10 + 'C++Script=(TDataSet DataSet)'
  + #13#10 + 'BasicScript=(DataSet)' + #13#10 + 'JScript=(DataSet)');

frxResources.Add('TfrxFilterRecordEvent', 'PascalScript=(DataSet: TDataSet; var Accept: Boolean);' + #13#10 +
  'C++Script=(TDataSet DataSet; Boolean &Accept)' + #13#10 + 'BasicScript=(DataSet, byref Accept)' + #13#10 +
  'JScript=(DataSet, byref Accept)');

frxObjects.RegisterObject1(TfrxTmsRdbDatabase, nil, '', {$IFDEF DB_CAT}'DATABASES'{$ELSE}''{$ENDIF}, 0,51);
frxObjects.RegisterObject1(TfrxTmsRdbQuery, nil, '', {$IFDEF DB_CAT}'QUERIES'{$ELSE}''{$ENDIF}, 0,53);

finalization

frxObjects.UnRegister(TfrxTmsRdbDatabase);
frxObjects.UnRegister(TfrxTmsRdbQuery);

end.
