unit Unit3;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
    ExtCtrls, ButtonPanel, ExtDlgs,
    fpspreadsheet, fpsTypes, xlsbiff8, fpsutils,
    typinfo
    ;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    FontButton: TButton;
    ColorButton: TButton;
    DefaultColorButton: TButton;
    OpenBGDialog: TOpenPictureDialog;
    SetBGImageButton: TButton;
    ResetBGImageButton: TButton;
    ButtonPanel1: TButtonPanel;
    ColorDialogFont: TColorDialog;
    ColorDialogForm: TColorDialog;
    FontDialogFont: TFontDialog;
    ImageBG: TImage;
    Language: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure ColorButtonClick(Sender: TObject);
    procedure DefaultColorButtonClick(Sender: TObject);
    procedure FontButtonClick(Sender: TObject);
    procedure LanguageClick(Sender: TObject);
    procedure ResetBGImageButtonClick(Sender: TObject);
    procedure SetBGImageButtonClick(Sender: TObject);
  private
    PreventRadioGroupLanguageSelectionChanged: boolean;
    procedure SaveToFile();
    procedure LoadFromFile();
    procedure RefreshSettings();
  public

  end;

var
  SettingsForm: TSettingsForm;
resourcestring
  MessageRestartProgramAfterChangeLanguage = 'The application must be restarted to change the interface language!';
  RadioGroupLanguageEnglish = 'English';
  RadioGroupLanguageRussian = 'Russian';

implementation

{$R *.lfm}
procedure TSettingsForm.SaveToFile();
var
  MyWorkBook: TsWorkbook;
  MyWorkSheet: TsWorksheet;
begin
  MyWorkBook := TsWorkbook.Create();
  MyWorkSheet := MyWorkBook.AddWorksheet('Font');
  MyWorkSheet.WriteText(0, 0, 'Name');
  MyWorkSheet.WriteText(0, 1, FontDialogFont.Font.Name);
  MyWorkSheet.WriteText(1, 0, 'Size');
  MyWorkSheet.WriteNumber(1, 1, FontDialogFont.Font.Size);
  MyWorkSheet.WriteText(2, 0, 'Style');
  MyWorkSheet.WriteText(2, 1, SetToString(GetPropInfo(FontDialogFont.Font, 'Style'),
    integer(FontDialogFont.Font.Style), False));
  MyWorkSheet.WriteText(3, 0, 'Color');
  MyWorkSheet.WriteNumber(3, 1, FontDialogFont.Font.Color);

  MyWorkSheet := MyWorkBook.AddWorksheet('Form');
  MyWorkSheet.WriteText(0, 0, 'Color');
  MyWorkSheet.WriteNumber(0, 1, ColorDialogForm.Color);
  MyWorkSheet.WriteText(1, 0, 'Image');
  MyWorkSheet.WriteText(1, 1, OpenBGDialog.FileName);
  MyWorkSheet.WriteText(2, 0, 'Language');
  if (Language.ItemIndex = 0) then
    MyWorkSheet.WriteText(2, 1, 'en');
  if (Language.ItemIndex = 1) then
    MyWorkSheet.WriteText(2, 1, 'ru');

  MyWorkBook.WriteToFile('settings.xls', sfExcel8, True);
end;

procedure TSettingsForm.LoadFromFile();
var
  MyWorkBook: TsWorkbook;
  MyWorkSheet: TsWorksheet;
begin
  MyWorkBook := TsWorkbook.Create();

  if (not FileExists('settings.xls')) then
  begin
    PreventRadioGroupLanguageSelectionChanged := True;
    Language.ItemIndex := 1;
    PreventRadioGroupLanguageSelectionChanged := False;
    exit();
  end;

  MyWorkBook.ReadFromFile('settings.xls', sfExcel8);

  MyWorkSheet := MyWorkBook.GetWorksheetByName('Font');
  FontDialogFont.Font := Font.Create();
  FontDialogFont.Font.Name := MyWorkSheet.ReadAsText(0, 1);
  FontDialogFont.Font.Size := trunc(MyWorkSheet.ReadAsNumber(1, 1));
  FontDialogFont.Font.Style :=
    TFontStyles(StringToSet(GetPropInfo(FontDialogFont.Font, 'Style'),
    MyWorkSheet.ReadAsText(2, 1)));
  FontDialogFont.Font.Color := trunc(MyWorkSheet.ReadAsNumber(3, 1));
  ColorDialogFont.Color := FontDialogFont.Font.Color;

  MyWorkSheet := MyWorkBook.GetWorksheetByName('Form');
  ColorDialogForm.Color := trunc(MyWorkSheet.ReadAsNumber(0, 1));
  OpenBGDialog.FileName := MyWorkSheet.ReadAsText(1, 1);
  PreventRadioGroupLanguageSelectionChanged := True;
  if (MyWorkSheet.ReadAsText(2, 1) = 'en') then
    Language.ItemIndex := 0
  else
    Language.ItemIndex := 1;
  PreventRadioGroupLanguageSelectionChanged := False;
end;

procedure TSettingsForm.RefreshSettings();
begin
  Font := FontDialogFont.Font;
  Color := ColorDialogForm.Color;
  if FileExists(OpenBGDialog.FileName) then
    ImageBG.Picture.LoadFromFile(OpenBGDialog.FileName)
  else
    ImageBG.Picture.Clear();
end;

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  Language.Items.Clear();
  Language.Items.Add(RadioGroupLanguageEnglish);
  Language.Items.Add(RadioGroupLanguageRussian);
  PreventRadioGroupLanguageSelectionChanged := False;
  LoadFromFile();
  RefreshSettings();
end;

procedure TSettingsForm.FontButtonClick(Sender: TObject);
begin
  FontDialogFont.Execute();
  ColorDialogFont.Execute();
  FontDialogFont.Font.Color := ColorDialogFont.Color;
  SaveToFile();
  RefreshSettings();
end;

procedure TSettingsForm.LanguageClick(Sender: TObject);
begin
  if (PreventRadioGroupLanguageSelectionChanged) then
    exit();
  SaveToFile();
  RefreshSettings();
  ShowMessage(MessageRestartProgramAfterChangeLanguage);
end;

procedure TSettingsForm.ResetBGImageButtonClick(Sender: TObject);
begin
  OpenBGDialog.FileName := '';
  SaveToFile();
  RefreshSettings();
end;

procedure TSettingsForm.SetBGImageButtonClick(Sender: TObject);
begin
  if (OpenBGDialog.Execute()) then
  begin
    SaveToFile();
    RefreshSettings();
  end;
end;

procedure TSettingsForm.ColorButtonClick(Sender: TObject);
begin
  ColorDialogForm.Execute();
  SaveToFile();
  RefreshSettings();
end;

procedure TSettingsForm.DefaultColorButtonClick(Sender: TObject);
begin
  ColorDialogForm.Color := clDefault;
  SaveToFile();
  RefreshSettings();
end;

end.

