{***************************************************************************}
{                                                                           }
{           iORM - (interfaced ORM)                                         }
{                                                                           }
{           Copyright (C) 2016 Maurizio Del Magno                           }
{                                                                           }
{           mauriziodm@levantesw.it                                         }
{           mauriziodelmagno@gmail.com                                      }
{           https://github.com/mauriziodm/iORM.git                          }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}



unit iORM.LiveBindings.ActiveInterfaceObjectBindSourceAdapter;

interface

uses
  iORM.LiveBindings.InterfaceObjectBindSourceAdapter,
  iORM.LiveBindings.Interfaces, iORM.LiveBindings.Notification,
  iORM.CommonTypes, System.Classes, iORM.Context.Properties.Interfaces,
  Data.Bind.ObjectScope, iORM.Where.Interfaces;

type

  TioActiveInterfaceObjectBindSourceAdapter = class(TInterfaceObjectBindSourceAdapter, IioContainedBindSourceAdapter, IioActiveBindSourceAdapter, IioNaturalBindSourceAdapterSource)
  strict private
    FWhere: IioWhere;
    FWhereDetailsFromDetailAdapters: Boolean;
    FTypeName, FTypeAlias: String;
    FLocalOwnsObject: Boolean;
    FAutoLoadData: Boolean;
    FAutoPersist: Boolean;
    FReloadDataOnRefresh: Boolean;
    FMasterPropertyName: String;
    FMasterAdaptersContainer: IioDetailBindSourceAdaptersContainer;
    FDetailAdaptersContainer: IioDetailBindSourceAdaptersContainer;
    FBindSource: IioNotifiableBindSource;
    FonNotify: TioBSANotificationEvent;
//    FNaturalBSA_MasterBindSourceAdapter: IioActiveBindSourceAdapter;
    FInsertObj_Enabled: Boolean;
    FInsertObj_NewObj: TObject;
    // =========================================================================
    // Part for the support of the IioNotifiableBindSource interfaces (Added by iORM)
    //  because is not implementing IInterface (NB: RefCount DISABLED)
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
{$IFDEF AUTOREFCOUNT}
    function __ObjAddRef: Integer; override;
    function __ObjRelease: Integer; override;
{$ENDIF}
    // =========================================================================
    procedure DoBeforeOpen; override;
    procedure DoBeforeRefresh; override;
    procedure DoBeforeDelete; override;
    procedure DoAfterDelete; override;
    procedure DoAfterPost; override;
    procedure DoAfterScroll; override;
    procedure DoAfterInsert; override;
    procedure SetObjStatus(AObjStatus: TioObjectStatus);
    function UseObjStatus: Boolean;
    procedure DoNotify(ANotification:IioBSANotification);
    // AutoPersist property
    function GetioAutoPersist: Boolean;
    procedure SetioAutoPersist(const Value: Boolean); protected
    // WhereStr property
    procedure SetIoWhere(const Value: IioWhere);
    function GetioWhere: IioWhere;
    // ioWhereDetailsFromDetailAdapters property
    function GetioWhereDetailsFromDetailAdapters: Boolean;
    procedure SetioWhereDetailsFromDetailAdapters(const Value: Boolean);
  public
    constructor Create(const ATypeName, ATypeAlias: String; const AWhere:IioWhere; const AOwner: TComponent; const AObject: TObject; const AutoLoadData: Boolean); overload;
    destructor Destroy; override;
    procedure SetMasterAdapterContainer(AMasterAdapterContainer:IioDetailBindSourceAdaptersContainer);
    procedure SetMasterProperty(AMasterProperty: IioContextProperty);
    procedure SetBindSource(ANotifiableBindSource:IioNotifiableBindSource);
    procedure ExtractDetailObject(AMasterObj: TObject);
    procedure Persist(ReloadData:Boolean=False);
    function NewDetailBindSourceAdapter(const AOwner:TComponent; const AMasterPropertyName:String; const AWhere:IioWhere): TBindSourceAdapter;
    function NewNaturalObjectBindSourceAdapter(const AOwner:TComponent): TBindSourceAdapter;
    function GetDetailBindSourceAdapterByMasterPropertyName(const AMasterPropertyName: String): IioActiveBindSourceAdapter;
    procedure Append(AObject:TObject); overload;
    procedure Insert(AObject:TObject); overload;
    procedure Notify(Sender:TObject; ANotification:IioBSANotification); virtual;
    procedure Refresh(ReloadData:Boolean); overload;
//    FNaturalBSA_MasterBindSourceAdapter: IioActiveBindSourceAdapter;  *** NB: Code presente (commented) in the unit body ***
    function GetDataObject: TObject;
    procedure SetDataObject(const AObj: TObject; const AOwnsObject:Boolean=True);
    procedure ClearDataObject;
    function GetCurrentOID: Integer;
    function IsDetail: Boolean;
    function GetMasterPropertyName: String;

    property ioAutoPersist:Boolean read GetioAutoPersist write SetioAutoPersist;
    property ioOnNotify:TioBSANotificationEvent read FonNotify write FonNotify;
    property ioWhere:IioWhere read GetIoWhere write SetIoWhere;
    property ioWhereDetailsFromDetailAdapters: Boolean read GetioWhereDetailsFromDetailAdapters write SetioWhereDetailsFromDetailAdapters;
  end;


implementation

uses
  iORM, System.SysUtils, iORM.LiveBindings.Factory, iORM.Context.Factory,
  System.Rtti, iORM.Context.Map.Interfaces, iORM.Where.Factory;

{ TioActiveInterfaceObjectBindSourceAdapter }

{$IFDEF AUTOREFCOUNT}
function TioActiveInterfaceObjectBindSourceAdapter.__ObjAddRef: Integer;
begin
  // Nothing (event the "inherited")
end;
function TioActiveInterfaceObjectBindSourceAdapter.__ObjRelease: Integer;
begin
  // Nothing (event the "inherited")
end;
{$ENDIF}

procedure TioActiveInterfaceObjectBindSourceAdapter.Append(AObject: TObject);
begin
  // Set sone InsertObj subsystem variables
  // Then call the standard code
  FInsertObj_NewObj := AObject;
  FInsertObj_Enabled := True;
  Self.Append;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.ClearDataObject;
begin
  Self.SetDataObject(nil, False);
end;

constructor TioActiveInterfaceObjectBindSourceAdapter.Create(const ATypeName, ATypeAlias: String; const AWhere: IioWhere;
  const AOwner: TComponent; const AObject: TObject; const AutoLoadData: Boolean);
begin
  FAutoPersist := True;
  FAutoLoadData := AutoLoadData;
  FReloadDataOnRefresh := True;
  inherited Create(AOwner, AObject, ATypeAlias, ATypeName);
  FLocalOwnsObject := False;  // Always false because it's a BSA for an interface (AutoRefCount)
  FWhere := AWhere;
  FWhereDetailsFromDetailAdapters := False;
  // Set Master & Details adapters reference
  FMasterAdaptersContainer := nil;
  FDetailAdaptersContainer := TioLiveBindingsFactory.DetailAdaptersContainer(Self);
  // Init InsertObj subsystem values
  FInsertObj_Enabled := False;
  FInsertObj_NewObj := nil;
end;

destructor TioActiveInterfaceObjectBindSourceAdapter.Destroy;
begin
  // Detach itself from MasterAdapterContainer (if it's contained)
  if Assigned(FMasterAdaptersContainer) then
    FMasterAdaptersContainer.RemoveBindSourceAdapter(Self);
  // Free the DetailAdaptersContainer
  FDetailAdaptersContainer.Free;
  inherited;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.DoAfterDelete;
begin
  inherited;
  // Send a notification to other ActiveBindSourceAdapters & BindSource
  Notify(
         Self,
         TioLiveBindingsFactory.Notification(Self, Self.Current, ntAfterDelete)
        );
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.DoAfterInsert;
var
  ObjToFree: TObject;
begin
  // If enabled subsitute the new object with the FInsertObj_NewObj (Append(AObject:TObject))
  //  then destroy the "old" new object
  if FInsertObj_Enabled then
  begin
    try
      ObjToFree := Self.DataObject as TObject;
      ObjToFree.Free;
      Self.SetDataObject(FInsertObj_NewObj, FLocalOwnsObject);
    finally
      // Reset InsertObj subsystem
      FInsertObj_Enabled := False;
      FInsertObj_NewObj := nil;
    end;
  end;
  // Execute AfterInsert event handler
  inherited;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.DoAfterPost;
begin
  inherited;
  Self.SetObjStatus(osDirty);
  // If AutoPersist is enabled then persist
  if Self.FAutoPersist then io.Persist(Self.Current);
  // Send a notification to other ActiveBindSourceAdapters & BindSource
  Notify(
         Self,
         TioLiveBindingsFactory.Notification(Self, Self.Current, ntAfterPost)
        );
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.DoAfterScroll;
begin
  inherited;
  Self.FDetailAdaptersContainer.SetMasterObject(Self.Current);
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.DoBeforeDelete;
begin
  inherited;
  // If ObjectStatus exists in the class then set it as osDirty
  if Self.UseObjStatus then
  begin
    Self.SetObjStatus(osDeleted);
    Abort;
  end;
  // If AutoPersist is enabled then persist
  if Self.FAutoPersist then io.Delete(Self.Current);
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.DoBeforeOpen;
begin
  inherited;
  // Load the object and assign it to the Adapter
  if FAutoLoadData
    then Self.SetDataObject(   io.Load(FTypeName, FTypeAlias)._Where(GetioWhere).ToObject   , FLocalOwnsObject);  // Use GetioWhere to fill the WhereDetails
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.DoBeforeRefresh;
var
  PrevDataObject: TObject;
begin
  inherited;
  if FReloadDataOnRefresh then
  begin
    // Deactivate the adapter
    Self.Active := False;
    // Get actual DataObject
    PrevDataObject := Self.DataObject as TObject;
    // If ActualDataObject is assigned and OwnsObject = True then destroy the object
    if Assigned(PrevDataObject) and Self.FLocalOwnsObject then PrevDataObject.Free;
    // Activate the Adapter (after the adapter fire the onBeforeOpen event that Load
    //  the NewObject
    Self.Active := True;
  end;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.DoNotify(ANotification: IioBSANotification);
begin
  if Assigned(FonNotify)
    then ioOnNotify(Self, ANotification);
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.ExtractDetailObject(AMasterObj: TObject);
var
  ADetailObj: TObject;
  AValue: TValue;
  AMap: IioMap;
  AMasterProperty: IioContextProperty;
begin
  ADetailObj := nil;
  // Check parameter, if the MasterObject is not assigned
  //  then close the BSA
  if not Assigned(AMasterObj) then
  begin
    Self.SetDataObject(nil, False);  // 2� parameter false ABSOLUTELY!!!!!!!
    Exit;
  end;
  // Extract master property value
  AMap := TioContextFactory.Map(AMasterObj.ClassType);
  AMasterProperty := AMap.GetProperties.GetPropertyByName(FMasterPropertyName);
  AValue := AMasterProperty.GetValue(AMasterObj);
  // Retrieve the object from the TValue
  if not AValue.IsEmpty then
    if AMasterProperty.IsInterface then
      ADetailObj := TObject(AValue.AsInterface)
    else
      ADetailObj := AValue.AsObject;
  // Set it to the Adapter itself
  Self.SetDataObject(ADetailObj, False);  // 2� parameter false ABSOLUTELY!!!!!!!
end;

function TioActiveInterfaceObjectBindSourceAdapter.GetCurrentOID: Integer;
var
  AMap: IioMap;
begin
  // Create context for current child object
  AMap := TioContextFactory.Map(Self.Current.ClassType);
  Result := AMap.GetProperties.GetIdProperty.GetValue(Self.Current).AsInteger;
end;

function TioActiveInterfaceObjectBindSourceAdapter.GetDataObject: TObject;
begin
  Result := Self.DataObject as TObject;
end;

function TioActiveInterfaceObjectBindSourceAdapter.GetDetailBindSourceAdapterByMasterPropertyName(
  const AMasterPropertyName: String): IioActiveBindSourceAdapter;
begin
  Result := FDetailAdaptersContainer.GetBindSourceAdapterByMasterPropertyName(AMasterPropertyName);
end;

function TioActiveInterfaceObjectBindSourceAdapter.NewDetailBindSourceAdapter(const AOwner:TComponent; const AMasterPropertyName:String; const AWhere:IioWhere): TBindSourceAdapter;
begin
  // Return the requested DetailBindSourceAdapter and set the current master object
  Result := FDetailAdaptersContainer.NewBindSourceAdapter(AOwner, BaseObjectRttiType.Name, AMasterPropertyName, AWhere);
  FDetailAdaptersContainer.SetMasterObject(Self.Current);
end;

function TioActiveInterfaceObjectBindSourceAdapter.GetioAutoPersist: Boolean;
begin
  Result := FAutoPersist;
end;

function TioActiveInterfaceObjectBindSourceAdapter.GetioWhere: IioWhere;
begin
  Result := FWhere;
  // Fill the WhereDetails from the DetailAdapters container if enabled
  //  NB: Create it if not assigned
  if FWhereDetailsFromDetailAdapters then
  begin
    if not Assigned(FWhere) then
      FWhere := TioWhereFactory.NewWhere;
    FDetailAdaptersContainer.FillWhereDetails(FWhere.Details);
  end;
end;

function TioActiveInterfaceObjectBindSourceAdapter.GetioWhereDetailsFromDetailAdapters: Boolean;
begin
  Result := FWhereDetailsFromDetailAdapters;
end;

function TioActiveInterfaceObjectBindSourceAdapter.GetMasterPropertyName: String;
begin
  Result := FMasterPropertyName;
end;

function TioActiveInterfaceObjectBindSourceAdapter.NewNaturalObjectBindSourceAdapter(const AOwner: TComponent): TBindSourceAdapter;
begin
  Result := TioLiveBindingsFactory.NaturalObjectBindSourceAdapter(AOwner, Self);
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.Insert(AObject: TObject);
begin
  // Set sone InsertObj subsystem variables
  // Then call the standard code
  FInsertObj_NewObj := AObject;
  FInsertObj_Enabled := True;
  Self.Insert;
end;

function TioActiveInterfaceObjectBindSourceAdapter.IsDetail: Boolean;
begin
  Result := not FMasterPropertyName.IsEmpty;
end;

//procedure TioActiveInterfaceObjectBindSourceAdapter.NaturalBSA_SetMasterBindSourceAdapter(
//  AActiveBindSourceAdapter: IioActiveBindSourceAdapter);
//begin
//  Self.FNaturalBSA_MasterBindSourceAdapter := AActiveBindSourceAdapter;
//end;

procedure TioActiveInterfaceObjectBindSourceAdapter.Notify(Sender: TObject; ANotification: IioBSANotification);
begin
  // Fire the event handler
  if Sender <> Self
    then Self.DoNotify(ANotification);
  // Replicate notification to the BindSource
  if Assigned(FBindSource) and (Sender <> TObject(FBindSource))
    then FBindSource.Notify(Self, ANotification);
  // Replicate notification to the DetailAdaptersContainer
  if Sender <> TObject(FDetailAdaptersContainer)
    then FDetailAdaptersContainer.Notify(Self, ANotification);
  // Replicate notification to the MasterAdaptersContainer
  if Assigned(FMasterAdaptersContainer) and (Sender <> TObject(FMasterAdaptersContainer))
    then FMasterAdaptersContainer.Notify(Self, ANotification);
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.Persist(ReloadData: Boolean);
begin
  // Persist
  io.Persist(Self.DataObject);
  // Reload
  if ReloadData then Self.DoBeforeOpen;
end;

function TioActiveInterfaceObjectBindSourceAdapter.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  // RefCount disabled
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.Refresh(ReloadData: Boolean);
var
  PrecReloadData: Boolean;
begin
  // Se il BindSourceAdapter � un dettaglio allora propaga il Refresh al suo Master
  //  questo perch� solo il master esegue realmente le query e quindi � quest'ultimo che
  //  deve gestire il refresh con reload.
  if IsDetail and Assigned(FMasterAdaptersContainer) then
    FMasterAdaptersContainer.GetMasterBindSourceAdapter.Refresh(ReloadData)
  else
  begin
    PrecReloadData := FReloadDataOnRefresh;
    Self.FReloadDataOnRefresh := ReloadData;
    inherited Refresh;
    Self.FReloadDataOnRefresh := PrecReloadData;
  end;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.SetBindSource(ANotifiableBindSource: IioNotifiableBindSource);
begin
  FBindSource := ANotifiableBindSource;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.SetDataObject(const AObj: TObject; const AOwnsObject:Boolean);
var
  LPrecAutoLoadData: Boolean;
begin
  // Disable the adapter
  Self.First;  // Bug
  Self.Active := False;
  // AObj is assigned then set it as DataObject
  //  else set DataObject to nil and set MasterObject to nil
  //  to disable all Details adapters also
  if Assigned(AObj) then
  begin
    // Set the provided DataObject
    inherited SetDataObject(AObj, AOwnsObject);
    // Prior to reactivate the adapter force the "AutoLoadData" property to False to prevent double values
    //  then restore the original value of the "AutoLoadData" property.
    LPrecAutoLoadData := FAutoLoadData;
    try
      FAutoLoadData := False;
      Self.Active := True;
    finally
      FAutoLoadData := LPrecAutoLoadData;
    end;
  end
  else
  begin
    inherited SetDataObject(nil, AOwnsObject);
    Self.FDetailAdaptersContainer.SetMasterObject(nil);
  end;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.SetioAutoPersist(const Value: Boolean);
begin
  FAutoPersist := Value;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.SetIoWhere(
  const Value: IioWhere);
begin
  FWhere := Value;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.SetioWhereDetailsFromDetailAdapters(
  const Value: Boolean);
begin
  FWhereDetailsFromDetailAdapters := Value;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.SetMasterAdapterContainer(
  AMasterAdapterContainer: IioDetailBindSourceAdaptersContainer);
begin
  FMasterAdaptersContainer := AMasterAdapterContainer;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.SetMasterProperty(AMasterProperty: IioContextProperty);
begin
  FMasterPropertyName := AMasterProperty.GetName;
end;

procedure TioActiveInterfaceObjectBindSourceAdapter.SetObjStatus(AObjStatus: TioObjectStatus);
begin
  TioContextFactory.Context(Self.Current.ClassName, nil, Self.Current).ObjectStatus := AObjStatus;
end;

function TioActiveInterfaceObjectBindSourceAdapter.UseObjStatus: Boolean;
begin
  Result := TioContextFactory.Context(Self.Current.ClassName, nil, Self.Current).ObjStatusExist;
end;

function TioActiveInterfaceObjectBindSourceAdapter._AddRef: Integer;
begin
  // Nothing, the interfaces support is intended only as LazyLoadable support flag
end;

function TioActiveInterfaceObjectBindSourceAdapter._Release: Integer;
begin
  // Nothing, the interfaces support is intended only as LazyLoadable support flag
end;

end.