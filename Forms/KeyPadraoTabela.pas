unit KeyPadraoTabela;

interface

uses
  KeyFuncoes,
  KeyResource,
  KeyPadrao,
  KeyRequiredFields,

  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, Menus,
  StdCtrls, cxButtons, ExtCtrls, cxControls, dxSkinsCore,
  dxSkinscxPCPainter, cxContainer, cxEdit, cxTextEdit, cxGroupBox, cxPC,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, DB, cxDBData,
  cxGridLevel, cxClasses, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxMaskEdit, cxDropDownEdit,
  cxImageComboBox, FMTBcd, Provider, DBClient, SqlExpr, dxSkinBlack,
  dxSkinBlue, dxSkinCaramel, dxSkinCoffee, dxSkinDarkSide,
  dxSkinGlassOceans, dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky,
  dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinPumpkin,
  dxSkinSilver, dxSkinStardust, dxSkinSummer2008, dxSkinsDefaultPainters,
  dxSkinValentine, dxSkinXmas2008Blue;

type
  TFrmPadraoTabela = class(TFrmPadrao)
    PnlMain: TPanel;
    btnFechar: TcxButton;
    BvlMain: TBevel;
    PnlTabela: TPanel;
    PgCtrlMain: TcxPageControl;
    TbsPrincipal: TcxTabSheet;
    GrpBxPesquisa: TcxGroupBox;
    EdtPesquisa: TcxTextEdit;
    BtnPesquisar: TcxButton;
    DbgTabela: TcxGrid;
    DbgTabelaDB: TcxGridDBTableView;
    DbgTabelaLvl: TcxGridLevel;
    Pnl: TPanel;
    ShpTitulo: TShape;
    LblDados: TLabel;
    CmbTipoPesquisa: TcxImageComboBox;
    QryMaster: TSQLQuery;
    CdsMaster: TClientDataSet;
    DspMaster: TDataSetProvider;
    DtsMaster: TDataSource;
    BtnSelecionar: TcxButton;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnPesquisarClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CdsMasterBeforeDelete(DataSet: TDataSet);
    procedure CdsMasterBeforePost(DataSet: TDataSet);
    procedure BtnSelecionarClick(Sender: TObject);
    procedure DbgTabelaDBKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CmbTipoPesquisaKeyPress(Sender: TObject; var Key: Char);
    procedure EdtPesquisaKeyPress(Sender: TObject; var Key: Char);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure DtsMasterStateChange(Sender: TObject);
    procedure DbgTabelaDBDblClick(Sender: TObject);
  private
    { Private declarations }
    FAbrirTabela : Boolean;
    FSQL_Master : TStringList;
  public
    { Public declarations }
    property AbrirTabela : Boolean read FAbrirTabela write FAbrirTabela;
    property SQL_Master : TStringList read FSQL_Master write FSQL_Master;
    function ExecutarPesquisa : Boolean; virtual; abstract;
  end;

var
  FrmPadraoTabela: TFrmPadraoTabela;

implementation

{$R *.dfm}

procedure TFrmPadraoTabela.FormShow(Sender: TObject);
begin
  inherited;
  if ( Assigned(ConexaoDB) and (QryMaster.SQLConnection = nil) ) then
    QryMaster.SQLConnection := ConexaoDB;

  BtnSelecionar.Visible := SelecionarRegistro;
    
  if AbrirTabela then
    ExecutarPesquisa;  
end;

procedure TFrmPadraoTabela.FormCreate(Sender: TObject);
begin
  inherited;
  FSQL_Master := TStringList.Create;
  FSQL_Master.AddStrings( QryMaster.SQL );

  PgCtrlMain.ActivePage := TbsPrincipal;

  AbrirTabela := False;
end;

procedure TFrmPadraoTabela.BtnPesquisarClick(Sender: TObject);
begin
  if ExecutarPesquisa() then
    DbgTabela.SetFocus;
end;

procedure TFrmPadraoTabela.btnFecharClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TFrmPadraoTabela.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;

  Case Key of
    // Inserir
    VK_INSERT:
      begin
        if CdsMaster.Active and (not (CdsMaster.State in [dsEdit, dsInsert])) then
          CdsMaster.Append;

        if ( (PgCtrlMain.ActivePage = TbsPrincipal) and DbgTabela.Visible and DbgTabela.Enabled ) then
          DbgTabela.SetFocus;
      end;

    // Editar
    VK_F2:
      begin
        if not CdsMaster.IsEmpty then
          CdsMaster.Edit;

        if ( (PgCtrlMain.ActivePage = TbsPrincipal) and DbgTabela.Visible and DbgTabela.Enabled ) then
          DbgTabela.SetFocus;
      end;

    // Posicionar para pesquisa
    VK_F3:
      if ( (PgCtrlMain.ActivePage = TbsPrincipal) and EdtPesquisa.Visible and EdtPesquisa.Enabled ) then
        EdtPesquisa.SetFocus;

    // Fechar formul�rio
    VK_F4:
      if ( Shift = [ssCtrl] ) then
        btnFechar.Click;

    // Atualizar pesquisa
    VK_F5:
      if CdsMaster.Active then
      begin
        CdsMaster.Close;
        CdsMaster.Open;
      end
      else
      if ( (PgCtrlMain.ActivePage = TbsPrincipal) and BtnPesquisar.Visible and BtnPesquisar.Enabled ) then
        BtnPesquisar.Click;

    // Cancelar edi��o
    VK_ESCAPE:
      begin
        if CdsMaster.State in [dsEdit, dsInsert] then
        begin
          if CdsMaster.Modified then
          begin
            if ShowMessageConfirm('Deseja cancelar a edi��o do registtro?', 'Edi��o') then
              CdsMaster.Cancel;
          end
          else
            CdsMaster.Cancel;    
        end
        else
        if (PgCtrlMain.ActivePage <> TbsPrincipal) then
          PgCtrlMain.ActivePage := TbsPrincipal;
      end;
  end;

end;

procedure TFrmPadraoTabela.CdsMasterBeforeDelete(DataSet: TDataSet);
begin
  if ShowMessageConfirm('Confirma a exclus�o do registro selecionado?', 'Excluir') then
    if ExecutarDeleteTable(DataSet, NomeTabela) then
      Exit
    else
      Abort
  else
    Abort;
end;

procedure TFrmPadraoTabela.CdsMasterBeforePost(DataSet: TDataSet);
begin
  if ExistRequiredFields(Self, CdsMaster, Self.Caption) then
    Abort;
    
  if CdsMaster.State = dsInsert then
    if ExecutarInsertTable(DataSet, NomeTabela) then
      Exit
    else
      Abort;

  if CdsMaster.State = dsEdit then
    if ExecutarUpdateTable(DataSet, NomeTabela) then
      Exit
    else
      Abort;
end;

procedure TFrmPadraoTabela.BtnSelecionarClick(Sender: TObject);
begin
  if CdsMaster.Active then
    if not CdsMaster.IsEmpty then
      ModalResult := mrOk;
end;

procedure TFrmPadraoTabela.DbgTabelaDBKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ( Key = VK_RETURN ) then
    if ( BtnSelecionar.Visible and BtnSelecionar.Enabled ) then
      BtnSelecionar.Click;
end;

procedure TFrmPadraoTabela.CmbTipoPesquisaKeyPress(Sender: TObject;
  var Key: Char);
begin
  if ( Key = #13 ) then
    if ( EdtPesquisa.Visible and EdtPesquisa.Enabled ) then
      EdtPesquisa.SetFocus;
end;

procedure TFrmPadraoTabela.EdtPesquisaKeyPress(Sender: TObject;
  var Key: Char);
begin
  if ( Key = #13 ) then
    if ( BtnPesquisar.Visible and BtnPesquisar.Enabled ) then
      BtnPesquisar.Click;
end;

procedure TFrmPadraoTabela.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if CdsMaster.State in [dsEdit, dsInsert] then
    if CdsMaster.Modified then
      CanClose := ShowMessageConfirm('Deseja cancelar a edi��o do registtro?', 'Edi��o')
    else
      CanClose := True;  
end;

procedure TFrmPadraoTabela.DtsMasterStateChange(Sender: TObject);
begin
  btnFechar.Enabled     := ( not (CdsMaster.State in [dsEdit, dsInsert]) );
  BtnSelecionar.Enabled := ( not (CdsMaster.State in [dsEdit, dsInsert]) and (not CdsMaster.IsEmpty) );

  DbgTabelaDB.OptionsBehavior.FocusCellOnCycle    := not (BtnSelecionar.Visible and BtnSelecionar.Enabled);
  DbgTabelaDB.OptionsBehavior.FocusCellOnTab      := not (BtnSelecionar.Visible and BtnSelecionar.Enabled);
  DbgTabelaDB.OptionsBehavior.GoToNextCellOnEnter := not (BtnSelecionar.Visible and BtnSelecionar.Enabled);
end;

procedure TFrmPadraoTabela.DbgTabelaDBDblClick(Sender: TObject);
begin
  if ( BtnSelecionar.Visible and BtnSelecionar.Enabled ) then
    BtnSelecionar.Click;
end;

end.
