unit zdMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Spin, Buttons, Types,
  fpstypes, fpspreadsheet, fpspreadsheetgrid, {%H-}fpsAllFormats;

type

  { TMainForm }

  TMainForm = class(TForm)
    BtnOpen: TButton;
    BtnSave: TButton;
    CbOverrideZoomFactor: TCheckBox;
    CbWriteZoomFactor: TCheckBox;
    edZoom: TSpinEdit;
    Grid: TsWorksheetGrid;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    BtnPrevSheet: TSpeedButton;
    BtnNextSheet: TSpeedButton;
    procedure BtnOpenClick(Sender: TObject);
    procedure BtnPrevSheetClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure edZoomEditingDone(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GridMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure BtnNextSheetClick(Sender: TObject);
  private
    FWorkbook: TsWorkbook;
    FOpenFormats: TsSpreadFormatIDArray;
    FSaveFormats: TsSpreadFormatIDArray;
    procedure LoadFile(const AFileName: String; AFormatID: TsSpreadFormatID);
    procedure SaveFile(const AFileName: String; AFormatID: TsSpreadFormatID);
    procedure UpdateCaption;

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  fpsReaderWriter;

const
  MOUSEWHEEL_FACTOR = 1.05;


{ TMainForm }

procedure TMainForm.BtnOpenClick(Sender: TObject);
var
  fmt: TsSpreadFormatID;
begin
  if FWorkbook <> nil then
    OpenDialog.InitialDir := ExtractFileDir(FWorkbook.FileName);
  if OpenDialog.Execute then begin
    // 3 because FilterIndex is 1-based and there are 2 add'l items at the top.
    if OpenDialog.FilterIndex < 3 then
      fmt := sfidUnknown
    else
      fmt := FOpenFormats[OpenDialog.FilterIndex - 3];
    LoadFile(OpenDialog.FileName, fmt);
  end;
end;

procedure TMainForm.BtnNextSheetClick(Sender: TObject);
var
  i, n: Integer;
begin
  n := Grid.Workbook.GetWorksheetCount;
  i := 0;
  while (i < n-1) do begin
    if (Grid.Workbook.GetWorksheetByIndex(i) = Grid.Worksheet) then
    begin
      Grid.LoadFromWorkbook(Grid.Workbook, i+1);
      exit;
    end;
    inc(i);
  end;
end;

procedure TMainForm.BtnPrevSheetClick(Sender: TObject);
var
  i, n: Integer;
begin
  n := Grid.Workbook.GetWorksheetCount;
  i := 1;
  while (i < n) do begin
    if (Grid.Workbook.GetWorksheetByIndex(i) = Grid.Worksheet) then
    begin
      Grid.LoadFromWorkbook(Grid.Workbook, i-1);
      exit;
    end;
    inc(i);
  end;
end;

procedure TMainForm.BtnSaveClick(Sender: TObject);
var
  fmt: TsSpreadFormatID;
  fmts: TsSpreadFormatIDArray;
  i: Integer;
begin
  { Set up the save dialog such that it shows the loaded file name and type }
  SaveDialog.InitialDir := ExtractFileDir(OpenDialog.FileName);
  SaveDialog.FileName := ExtractFileName(OpenDialog.FileName);
  fmts := GetSpreadFormatsFromFileName(faWrite, SaveDialog.FileName);
  for i:=0 to High(FSaveFormats) do
    if FSaveFormats[i] = fmts[0] then begin
      SaveDialog.FilterIndex := i + 1;
      break;
    end;
  if SaveDialog.Execute then begin
    fmt := FSaveFormats[SaveDialog.FilterIndex - 1];
    SaveFile(SaveDialog.FileName, fmt);
  end;
end;

{ Set the zoom factor to the value in the edit control. Is called after
  pressing ENTER. }
procedure TMainForm.edZoomEditingDone(Sender: TObject);
begin
  Grid.ZoomFactor := edZoom.Value / 100;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  priorityFormats: Array[0..7] of TsSpreadFormatID;
begin
  priorityFormats[0] := ord(sfOOXML);
  priorityFormats[1] := ord(sfExcel8);
  priorityFormats[2] := ord(sfExcel5);
  priorityFormats[3] := ord(sfExcel2);
  priorityFormats[4] := ord(sfExcelXML);
  priorityFormats[5] := ord(sfOpenDocument);
  priorityFormats[6] := ord(sfCSV);
  priorityFormats[7] := ord(sfHTML);

  OpenDialog.Filter := GetFileFormatFilter('|', ';', faRead, priorityFormats, true, true);
    // true, true --> add "All spreadsheet formats" and "All Excel formats" at top
  SaveDialog.Filter := GetFileFormatFilter('|', ';', faWrite, priorityFormats);

  FOpenFormats := GetSpreadFormats(faRead, priorityFormats);
  FSaveFormats := GetSpreadFormats(faWrite, priorityFormats);
end;

{ Mouse wheel event handler for setting the zoom factor using the mouse wheel
  (together with pressing the SHFT + CTRL keys) }
procedure TMainForm.GridMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if ([ssCtrl, ssShift] * Shift = [ssCtrl, ssShift]) then begin
    //Grid.BeginUpdate;
    if WheelDelta > 0 then
      Grid.ZoomFactor := Grid.ZoomFactor * MOUSEWHEEL_FACTOR
    else
      Grid.ZoomFactor := Grid.ZoomFactor / MOUSEWHEEL_FACTOR;
    //Grid.EndUpdate;
    edZoom.Value := round(Grid.ZoomFactor * 100);
    Handled := true;
  end;
end;

procedure TMainForm.LoadFile(const AFileName: String; AFormatID: TsSpreadFormatID);
var
  crs: TCursor;
  book: TsWorkbook;
  i: Integer;
  sheet: TsWorksheet;
begin
  crs := Screen.Cursor;
  try
    if CbOverrideZoomFactor.Checked then begin
      book := TsWorkbook.Create;
      try
        Screen.Cursor := crHourglass;
        // Read the file
        book.ReadFromFile(AFilename, AFormatID);
        // If you want to override the zoom factor of the file set it before
        // assigning the worksheet to the grid.
        for i:=0 to book.GetWorksheetCount-1 do
        begin
          sheet := book.GetWorksheetByIndex(i);
          sheet.ZoomFactor := edZoom.Value / 100;
        end;
//        book.GetFirstWorksheet.ZoomFactor := edZoom.Value / 100;
        // Load the worksheet into the grid.
        Grid.LoadFromWorkbook(book, 0);
      except
        on E:Exception do begin
          MessageDlg(Format('File "%s" cannot be loaded.'#13 + E.Message, [AFilename]),
            mtError, [mbOK], 0);
          book.Free;
        end;
      end;
    end else begin
      Grid.LoadSheetFromSpreadsheetFile(AFilename, 0);
      edZoom.Value := Grid.ZoomFactor * 100;
    end;
    UpdateCaption;
  finally
    Screen.Cursor := crs;
  end;
end;

{ Saves the spreadsheet to the file selected by the SaveDialog action }
procedure TMainForm.SaveFile(const AFileName: String; AFormatID: TsSpreadFormatID);
begin
  Screen.Cursor := crHourglass;
  try
    Grid.SaveToSpreadsheetFile(AFileName, AFormatID);
    UpdateCaption;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.UpdateCaption;
begin
  if FWorkbook = nil then
    Caption := 'Zoom demo'
  else
    Caption := 'Zoom demo - "' + FWorkbook.Filename + '"';
end;

end.

