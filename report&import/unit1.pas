unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, pqconnection, sqldb, db, FileUtil, LR_Class, LR_DBSet,
  Forms, Controls, Graphics, Dialogs, Menus,

  SynEdit, TADbSource, TAGraph, DbCtrls, ComCtrls, StdCtrls, DBGrids, Types,
  fpstypes, fpspreadsheet, fpsallformats, laz_fpspreadsheet, xlsbiff8, fpsutils
  ;

type

  { TForm1 }

  TForm1 = class(TForm)
    DataSourceAudio: TDataSource;
    DataSourceVisitors: TDataSource;
    DataSourceRent: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    frDBDataSetAudio: TfrDBDataSet;
    frDBDataSetVisitors: TfrDBDataSet;
    frDBDataSetRent: TfrDBDataSet;
    frReportAudio: TfrReport;
    frReportVisitors: TfrReport;
    frReportRent: TfrReport;
    MainMenu1: TMainMenu;
    Export: TMenuItem;
    Import: TMenuItem;
    OpenDialogExcel: TOpenDialog;
    ReportAudio: TMenuItem;
    ReportVisitors: TMenuItem;
    ReportRent: TMenuItem;
    PQConnection1: TPQConnection;
    SaveDialogExcel: TSaveDialog;
    SQLQueryAudio: TSQLQuery;
    SQLQueryVisitors: TSQLQuery;
    SQLQueryRent: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure ReportRentClick(Sender: TObject);
    procedure ReportVisitorsClick(Sender: TObject);
    procedure ReportAudioClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure ExcelExportMenuItemClick(Sender: TObject);
    procedure ExcelImportMenuItemClick(Sender: TObject);
    procedure SQLQueryAudioAfterPost(DataSet: TDataSet);

  private
    procedure RefreshSql();

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ReportAudioClick(Sender: TObject);
begin
  self.frReportAudio.LoadFromFile('report_audio.lrf');
  self.frReportAudio.ShowReport();
end;

procedure TForm1.ReportVisitorsClick(Sender: TObject);
begin
  self.frReportVisitors.LoadFromFile('report_visitors.lrf');
  self.frReportVisitors.ShowReport();
end;

procedure TForm1.ReportRentClick(Sender: TObject);
begin
     self.frReportRent.LoadFromFile('report_rent.lrf');
    self.frReportRent.ShowReport();
end;

procedure TForm1.RefreshSql();
begin
  self.SQLQueryAudio.Close();
  self.SQLQueryAudio.Open();
  self.SQLQueryVisitors.Close();
  self.SQLQueryVisitors.Open();
  self.SQLQueryRent.Close();
  self.SQLQueryRent.Open();
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  self.RefreshSql();
end;

procedure DataSourceToWorksheet(ds: TDataSource; ws: TsWorksheet; header: TStringList);
var
  row, column: Integer;
  ft: TFieldType;
begin
  ds.DataSet.First();
  for column := 0 to header.Count -1 do
  begin
    ws.AddCell(0, column);
    ws.WriteText(0, column, header[column]);
    ws.WriteFontStyle(0, column, [fssBold]);
  end;
  for row := 0 to ds.DataSet.RecordCount - 1 do
  begin
    for column := 0 to ds.DataSet.FieldCount - 1 do
    begin
      ws.AddCell(row + 1, column);
      ft := ds.DataSet.Fields[column].DataType;
      if (ft = ftSmallint) or
         (ft = ftInteger) or
         (ft = ftWord) or
         (ft = ftFloat) or
         (ft = ftCurrency) or
         (ft = ftBCD) or
         (ft = ftLargeint) then
         ws.WriteNumber(row + 1, column,  ds.DataSet.Fields[column].AsFloat)
      else
        ws.WriteText(row + 1, column, ds.DataSet.Fields[column].AsString);
    end;
    ds.DataSet.Next();
  end;
  ds.DataSet.First();
end;

procedure TForm1.ExcelExportMenuItemClick(Sender: TObject);
var
  MyWorkBook: TsWorkbook;
  header: TStringList;
begin
  if(self.SaveDialogExcel.Execute()) then
  begin
    MyWorkBook := TsWorkbook.Create();
    header := TStringList.Create();

    header.Add('ID');
    header.Add('Name');
    header.Add('Author');
    header.Add('Genre');
    DataSourceToWorksheet(self.DataSourceAudio, MyWorkBook.AddWorksheet('Audio'), header);

    MyWorkBook.WriteToFile(self.SaveDialogExcel.FileName, sfExcel8, True);
  end;
end;

procedure TForm1.ExcelImportMenuItemClick(Sender: TObject);
var
  MyWorkBook: TsWorkbook;
  MyWorksheet: TsWorksheet;
  worksheetIndex: Integer;
  row: Cardinal;
  x : String;
begin
  if(OpenDialogExcel.Execute()) then
  begin
    MyWorkBook := TsWorkbook.Create();
    MyWorkBook.ReadFromFile(OpenDialogExcel.FileName, sfExcel8);

    for worksheetIndex := 0 to MyWorkbook.GetWorksheetCount() - 1 do
    begin
      MyWorksheet := MyWorkbook.GetWorksheetByIndex(worksheetIndex);
      if(MyWorksheet.Name = 'Audio') then
      for row := 1 to MyWorksheet.GetLastRowIndex do
      begin
        if (MyWorksheet.ReadAsText(row, 1) = '') or
           (MyWorksheet.ReadAsText(row, 2) = '') or
           (MyWorksheet.ReadAsText(row, 3) = '') then
           continue;
        self.DataSourceAudio.DataSet.Insert();
        self.DataSourceAudio.DataSet.Fields[1].AsString := MyWorksheet.ReadAsText(row, 1); // name
        self.DataSourceAudio.DataSet.Fields[2].AsString := MyWorksheet.ReadAsText(row, 2); // author
        self.DataSourceAudio.DataSet.Fields[3].AsString := MyWorksheet.ReadAsText(row, 3); // genre
      end;

    end;
  end;

  if(self.DataSourceAudio.DataSet.State = dsInsert) then
  self.DataSourceAudio.DataSet.Post();

end;

procedure TForm1.SQLQueryAudioAfterPost(DataSet: TDataSet);
begin
  self.SQLQueryAudio.ApplyUpdates(0);
  self.SQLTransaction1.Commit();
  self.RefreshSql();
end;

end.

