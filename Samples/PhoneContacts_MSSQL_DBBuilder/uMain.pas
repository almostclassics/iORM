unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Clipbrd,
  iORM, FireDAC.Phys.MSSQLDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  FireDAC.Comp.UI, FireDAC.Stan.Intf, FireDAC.Phys, FireDAC.Phys.ODBCBase,
  FireDAC.Phys.MSSQL, iORM.AbstractionLayer.Framework.VCL, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Comp.Client,
  iORM.DB.Components.ConnectionDef, iORM.DB.Components.ConnectionDef.MSSQLServer;

type
  TBuilderForm = class(TForm)
    CreateDBButton: TButton;
    Memo1: TMemo;
    ioVCL1: TioVCL;
    GenerateScriptButton: TButton;
    ServerEdit: TEdit;
    DatabaseEdit: TEdit;
    UserNameEdit: TEdit;
    PasswordEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    MessageLabel: TLabel;
    CopyScriptButton: TButton;
    procedure CreateDBButtonClick(Sender: TObject);
    procedure GenerateScriptButtonClick(Sender: TObject);
    procedure CopyScriptButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BuilderForm: TBuilderForm;

implementation

{$R *.dfm}

procedure TBuilderForm.CopyScriptButtonClick(Sender: TObject);
begin
  Clipboard.AsText := Memo1.Lines.Text;
end;

procedure TBuilderForm.CreateDBButtonClick(Sender: TObject);
var
  LOutputScript: string;
  LErrorMessage: string;
  LButtonSelected: Integer;
begin
  LButtonSelected := MessageDlg('Confirm DB Update', mtConfirmation, mbOKCancel, 0);

  if LButtonSelected = mrOK then
  begin

    // Default Connection
    io.Connections.NewSQLServerConnectionDef(ServerEdit.Text,DatabaseEdit.Text,UserNameEdit.Text,PasswordEdit.Text);

    Memo1.Lines.Clear;

    // CREAZIONE AUTOMATICA DEL DB
    if io.GlobalFactory.DBBuilderFactory.NewBuilder.GenerateDB(False, LOutputScript, LErrorMessage) then
    begin
      MessageLabel.Caption := 'Update DB Successful';
      Memo1.Lines.Add(LOutputScript)
    end
    else
    begin
      MessageLabel.Caption := 'Update DB terminated with errors';
      Memo1.Lines.Add(LErrorMessage);
    end;
  end;
end;

procedure TBuilderForm.GenerateScriptButtonClick(Sender: TObject);
var
  LOutputScript: string;
  LErrorMessage: string;
begin
  // Default Connection
  io.Connections.NewSQLServerConnectionDef(ServerEdit.Text,DatabaseEdit.Text,UserNameEdit.Text,PasswordEdit.Text);

  Memo1.Lines.Clear;

  // SOLO GENERAZIONE SCRIPT DI CREATE PER TUTTI GLI ELEMENTI DEL DB DA UTILIZZARE PER LA GENERAZIONE INIZIALE
  if io.GlobalFactory.DBBuilderFactory.NewBuilder.GenerateDB(True, LOutputScript, LErrorMessage) then
  begin
    MessageLabel.Caption := 'Script Creation Successful';
    Memo1.Lines.Add(LOutputScript);
  end
  else
  begin
    MessageLabel.Caption := 'Script Creation terminated with errors';
    Memo1.Lines.Add(LErrorMessage);
  end;
end;

end.
