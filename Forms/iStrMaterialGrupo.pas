unit iStrMaterialGrupo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, KeyPadraoTabelaFormularioCadastro, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, Menus, cxControls, dxSkinsCore,
  dxSkinscxPCPainter, cxContainer, cxEdit, cxStyles, cxCustomData,
  cxFilter, cxData, cxDataStorage, DB, cxDBData, FMTBcd, Provider,
  DBClient, SqlExpr, StdCtrls, ExtCtrls, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxMaskEdit, cxDropDownEdit, cxImageComboBox,
  cxTextEdit, cxGroupBox, cxPC, cxButtons, cxDBEdit, cxLabel;

type
  TFrmMaterialGrupo = class(TFrmPadraoTabelaFormularioCadastro)
    lblCodigo: TcxLabel;
    dbCodigo: TcxDBTextEdit;
    lblDescricao: TcxLabel;
    dbDescricao: TcxDBTextEdit;
    DbgTabelaDBgrp_codigo: TcxGridDBColumn;
    DbgTabelaDBgrp_descricao: TcxGridDBColumn;
    QryDetail: TSQLQuery;
    DspDetail: TDataSetProvider;
    CdsDetail: TClientDataSet;
    DtsDetail: TDataSource;
    CdsDetailsgp_codigo: TIntegerField;
    CdsDetailsgp_descricao: TStringField;
    CdsDetailsgp_grupo: TSmallintField;
    Shape1: TShape;
    Label1: TLabel;
    DbgDetail: TcxGrid;
    DbgDetailTbl: TcxGridDBTableView;
    DbgDetailLvl: TcxGridLevel;
    DbgDetailTblsgp_codigo: TcxGridDBColumn;
    DbgDetailTblsgp_descricao: TcxGridDBColumn;
    CdsMastergrp_codigo: TSmallintField;
    CdsMastergrp_descricao: TStringField;
    procedure FormCreate(Sender: TObject);
    procedure CdsMasterNewRecord(DataSet: TDataSet);
    procedure DtsMasterStateChange(Sender: TObject);
    procedure CdsDetailNewRecord(DataSet: TDataSet);
    procedure CdsMasterAfterPost(DataSet: TDataSet);
    procedure CdsDetailBeforeDelete(DataSet: TDataSet);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
    procedure CarregarSubgrupos;
    procedure GravarSubgrupos;
  public
    { Public declarations }
    function ExecutarPesquisa : Boolean; override;
  end;

var
  FrmMaterialGrupo: TFrmMaterialGrupo;

implementation

uses
  KeyFuncoes
  {$IFDEF IMONEY}
  , KeyMain
  , KeyLogin
  {$ENDIF}
  {$IFDEF ISTORE}
  , iStrMain
  , iStrLogin
  {$ENDIF}
  , KeyResource
  , KeyPadrao
  , KeyPadraoTabela;

{$R *.dfm}

function TFrmMaterialGrupo.ExecutarPesquisa: Boolean;
begin
  RefreshDB;

  CdsMaster.Close;
  QryMaster.SQL.Clear;
  QryMaster.SQL.AddStrings( SQL_Master );
  QryMaster.SQL.Add('where (1 = 1)');

  if Trim(EdtPesquisa.Text) <> EmptyStr then
    if StrIsInteger( Trim(EdtPesquisa.Text) ) then
      QryMaster.SQL.Add('  and g.grp_codigo = ' + Trim(EdtPesquisa.Text))
    else
      QryMaster.SQL.Add('  and upper(g.grp_descricao) like ' + QuotedStr(Trim(EdtPesquisa.Text) + '%'));

  QryMaster.SQL.Add('order by g.grp_descricao');
  CdsMaster.Open;

  Result := not CdsMaster.IsEmpty;
end;

procedure TFrmMaterialGrupo.FormCreate(Sender: TObject);
begin
  inherited;
  ComponenteLogin := FrmLogin;
  ConexaoDB       := FrmLogin.conWebMaster;

  NomeTabela     := 'str_material_grupo';
  CampoChave     := 'grp_codigo';
  CampoDescricao := 'grp_descricao';
  CampoOrdenacao := 'grp_descricao';

  AbrirTabela := True;
end;

procedure TFrmMaterialGrupo.CdsMasterNewRecord(DataSet: TDataSet);
begin
  CdsMastergrp_codigo.AsInteger := MaxCod(NomeTabela, CampoChave, EmptyStr);
end;

procedure TFrmMaterialGrupo.DtsMasterStateChange(Sender: TObject);
begin
  inherited;
  if ( CdsMaster.State in [dsEdit, dsInsert] ) then
  begin
    dbDescricao.SetFocus;
    CarregarSubgrupos;  
  end;
end;

procedure TFrmMaterialGrupo.CdsDetailNewRecord(DataSet: TDataSet);
begin
  CdsDetailsgp_grupo.Assign( CdsMastergrp_codigo );
  CdsDetailsgp_codigo.AsInteger := StrToInt(CdsMastergrp_codigo.AsString + FormatFloat('000', MaxCodDetail(CdsDetail, 'sgp_codigo')));
end;

procedure TFrmMaterialGrupo.CarregarSubgrupos;
begin
  with CdsDetail, Params do
  begin
    Close;
    ParamByName('sgp_grupo').AsInteger := CdsMastergrp_codigo.AsInteger;
    Open;
  end;
end;

procedure TFrmMaterialGrupo.GravarSubgrupos;
begin
  if CdsDetail.IsEmpty then
    Exit
  else
  begin
    CdsDetail.First;
    while not CdsDetail.Eof do
    begin
      ExecutarInsertUpdateTable(CdsDetail, 'str_material_subgrupo');
      CdsDetail.Next;
    end;
  end;
end;

procedure TFrmMaterialGrupo.CdsMasterAfterPost(DataSet: TDataSet);
begin
  GravarSubgrupos;
end;

procedure TFrmMaterialGrupo.CdsDetailBeforeDelete(DataSet: TDataSet);
begin
  if ShowMessageConfirm('Confirma a exclus�o do subgrupo selecionado?', 'Excluir') then
    ExecutarDeleteTable(DataSet, 'str_material_subgrupo')
  else
    Abort;
end;

procedure TFrmMaterialGrupo.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  
  Case Key of
    VK_INSERT:
      begin
        if (CdsMaster.State = dsInsert) then
          Exit;

        if CdsDetail.Active and (not (CdsDetail.State in [dsEdit, dsInsert])) then
          CdsDetail.Append;

        if ( (PgCtrlMain.ActivePage = TbsFormulario) and DbgDetail.Visible and DbgDetail.Enabled ) then
          DbgDetail.SetFocus;
      end;
  end;
end;

end.
