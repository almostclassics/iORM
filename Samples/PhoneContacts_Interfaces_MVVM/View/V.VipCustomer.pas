unit V.VipCustomer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  V.Customer, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, Data.Bind.Controls, Data.Bind.GenData,
  Fmx.Bind.GenData, Data.Bind.EngExt, Fmx.Bind.DBEngExt, System.Rtti,
  System.Bindings.Outputs, Fmx.Bind.Editors, System.Actions, FMX.ActnList,
  Data.Bind.Components, Data.Bind.ObjectScope, M.Model,
  iORM.LiveBindings.PrototypeBindSource, FMX.Layouts, Fmx.Bind.Navigator,
  FMX.ListView, FMX.Edit, FMX.Controls.Presentation, iORM.Attributes,
  iORM.MVVM.Components.ViewModelBridge, iORM.LiveBindings.ModelBindSource;

type
  [diViewFor(TVipCustomer)]
  TViewVipCustomer = class(TViewCustomer)
    Label8: TLabel;
    EditVipCardCode: TEdit;
    LinkControlToField8: TLinkControlToField;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
