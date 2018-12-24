unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  Unit3,
  LCLProc, LazHelpHTML, Buttons, StdCtrls, ExtCtrls, UTF8Process
  ;

type

  { TLoginForm }

  TLoginForm = class(TForm)
    BitBtnF1: TBitBtn;
    BitBtnCancel: TBitBtn;
    BitBtnOK: TBitBtn;
    BitBtnSettings: TBitBtn;
    EditLogin: TEdit;
    EditPassword: TEdit;
    ImageBG: TImage;
    Login: TStaticText;
    Password: TStaticText;
    procedure BitBtnCancelClick(Sender: TObject);
    procedure BitBtnOKClick(Sender: TObject);
    procedure BitBtnSettingsClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure RefreshSettings();

  public

  end;

var
  LoginForm: TLoginForm;

implementation

{$R *.lfm}

{ TLoginForm }
 procedure TLoginForm.FormShow(Sender: TObject);
begin
  RefreshSettings();
end;

procedure TLoginForm.RefreshSettings();
begin
  Font := SettingsForm.FontDialogFont.Font;
  Color := SettingsForm.ColorDialogForm.Color;
  if FileExists(SettingsForm.OpenBGDialog.FileName) then
    ImageBG.Picture.LoadFromFile(SettingsForm.OpenBGDialog.FileName)
  else
    ImageBG.Picture.Clear();
end;

procedure TLoginForm.BitBtnOKClick(Sender: TObject);
begin
      //MainForm.PQConnection1.UserName := EditLogin.Text;
      //MainForm.PQConnection1.Password := EditPassword.Text;
      //MainForm.Show();
      Hide();
end;

procedure TLoginForm.BitBtnSettingsClick(Sender: TObject);
begin
      SettingsForm.ShowModal();
      RefreshSettings();
end;

procedure TLoginForm.Button1Click(Sender: TObject);
begin
//OpenURL('file:///home/jull/Загрузки/SUSU/roles/web_help/help1.html');
  //  OpenURL('http://google.com');
end;

procedure TLoginForm.BitBtnCancelClick(Sender: TObject);
begin
      Application.Terminate();
end;


end.

