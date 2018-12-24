unit Unit4;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, sqldb, pqconnection, FileUtil, //LR_Class, //LR_DBSet,
  Forms, Controls, Graphics, Dialogs, ComCtrls, DbCtrls, DBGrids, StdCtrls,
  ExtCtrls, LazHelpHTML // , Unit2, Unit3
  ;

type

  { TMainForm }

  TMainForm = class(TForm)
    ButtonReport: TButton;
    ButtonRenameUser: TButton;
    ButtonDeleteUser: TButton;
    ButtonChangeUserPassword: TButton;
    ButtonAddUser: TButton;
    DataSourceUsers: TDataSource;
    DataSourceRoles: TDataSource;
    DataSourceBooks: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    ListBoxUsers: TListBox;
    PQConnection1: TPQConnection;
    RadioGroupUsersRoles: TRadioGroup;
    SQLQueryUsers: TSQLQuery;
    SQLQueryRoles: TSQLQuery;
    SQLQueryBooks: TSQLQuery;
    SQLTransaction1: TSQLTransaction;


    procedure FormClose(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ButtonAddUserClick(Sender: TObject);
    procedure ButtonChangeUserPasswordClick(Sender: TObject);
    procedure ButtonDeleteUserClick(Sender: TObject);
    procedure ButtonRenameUserClick(Sender: TObject);
    procedure ButtonReportClick(Sender: TObject);
    procedure ImageBackgroundClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure SQLQueryParentsAfterPost();

    procedure ListBoxUsersClick(Sender: TObject);
    procedure ListBoxUsersSelectionChange(Sender: TObject);
    procedure RadioGroupUsersRolesSelectionChanged(Sender: TObject);

  private
    UserRole: string;
    PreventRadioGroupUsersRolesRefresh: boolean;
    procedure RefreshSql();
    procedure RefreshSettings();

  public

  end;

var
  MainForm: TMainForm;

resourcestring
  MessageAddUserCaption = 'Add user';
  MessageAddUserText = 'Enter user name';
  MessageChangePasswordCaption = 'Change password';
  MessageChangePasswordText = 'Enter new password';
  MessageRenameUserCaption = 'Rename user';
  MessageRenameUserText = 'Enter new user name';
  MessageDeleteUserCaption = 'Delete user';
  MessageDeleteUserText = 'Are you sure?';

  RadioGroupUsersRolesAdmin = 'Admin';
  RadioGroupUsersRolesOperator = 'Operator';
  RadioGroupUsersRolesUser = 'User';

implementation

{$R *.lfm}

procedure TMainForm.RefreshSql();
var
  i: integer;
  prevSelectedUser: integer;
begin
  SQLQueryBooks.Close();
  SQLQueryBooks.Open();

  if (UserRole = 'role_admin') then
  begin
    RadioGroupUsersRoles.ItemIndex := -1;
    RadioGroupUsersRoles.Enabled := False;
    ButtonDeleteUser.Enabled := False;
    ButtonRenameUser.Enabled := False;

    SQLQueryUsers.Close();
    SQLQueryUsers.Open();

    prevSelectedUser := ListBoxUsers.ItemIndex;
    ListBoxUsers.ItemIndex := -1;
    ListBoxUsers.Items.Clear();

    DataSourceUsers.DataSet.First();
    for i := 0 to DataSourceUsers.DataSet.RecordCount - 1 do
    begin
      ListBoxUsers.Items.Add(DataSourceUsers.DataSet.Fields[0].AsString);
      DataSourceUsers.DataSet.Next();
      if (i = prevSelectedUser) then
        ListBoxUsers.ItemIndex := i;
    end;
  end;
end;

procedure TMainForm.RefreshSettings();
begin
  Font := SettingsForm.FontDialogFont.Font;
  Color := SettingsForm.ColorDialogForm.Color;
  if FileExists(SettingsForm.OpenBGDialog.FileName) then
    ImageBackground.Picture.LoadFromFile(SettingsForm.OpenBGDialog.FileName)
  else
    ImageBackground.Picture.Clear();
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  RadioGroupUsersRoles.Items.Clear();
  RadioGroupUsersRoles.Items.Add(RadioGroupUsersRolesAdmin);
  RadioGroupUsersRoles.Items.Add(RadioGroupUsersRolesOperator);
  RadioGroupUsersRoles.Items.Add(RadioGroupUsersRolesUser);

  RefreshSettings();

  DBGrid1.AllowOutboundEvents := True;

  PQConnection1.Connected := True;
  SQLQueryBooks.Active := True;

  SQLQueryRoles.ParamByName('username').AsString := PQConnection1.UserName;
  SQLQueryRoles.Active := True;

  DataSourceRoles.DataSet.First();
  UserRole := DataSourceRoles.DataSet.Fields[0].AsString;
  Caption := Caption + ' [' + UserRole.Substring(5) + ']';

  if (UserRole = 'role_user') then
  begin
    DBGrid1.ReadOnly := True;
    DBNavigator1.VisibleButtons := [nbFirst, nbLast, nbNext, nbPrior];
  end;

  if (UserRole = 'role_admin') then
  begin
    SQLQueryUsers.Active := True;
  end
  else
  begin
    TabSheet2.TabVisible := False;
  end;

  RefreshSql();
end;

procedure TMainForm.FormClose(Sender: TObject);
begin
  Application.Terminate();
end;

procedure TMainForm.ButtonAddUserClick(Sender: TObject);
var
  userName: string;
begin
  userName := InputBox(MessageAddUserCaption, MessageAddUserText, '');
  if pgroles_add(PQConnection1, userName) then
    RefreshSql();
end;

procedure TMainForm.ButtonChangeUserPasswordClick(Sender: TObject);
var
  password: string;
begin
  password := PasswordBox(MessageChangePasswordCaption, MessageChangePasswordText);
  pgroles_password(PQConnection1, ListBoxUsers.Items[ListBoxUsers.ItemIndex],
    password);
end;

procedure TMainForm.ButtonDeleteUserClick(Sender: TObject);
begin
  if MessageDlg(MessageDeleteUserCaption, MessageDeleteUserText,
    mtConfirmation, [mbNo, mbYes], 0) = mrYes then
  begin
    if pgroles_delete(PQConnection1, ListBoxUsers.Items[ListBoxUsers.ItemIndex]) then
      RefreshSql();
  end;
end;

procedure TMainForm.ButtonRenameUserClick(Sender: TObject);
var
  userName: string;
begin
  userName := InputBox(MessageRenameUserCaption, MessageRenameUserText, '');
  if pgroles_rename(PQConnection1, ListBoxUsers.Items[ListBoxUsers.ItemIndex],
    userName) then
    RefreshSql();
end;

procedure TMainForm.ButtonReportClick(Sender: TObject);
begin
  frReportBooks.LoadFromFile('report_books.lrf');
  self.frReportBooks.ShowReport();
end;

procedure TMainForm.ImageBackgroundClick(Sender: TObject);
begin

end;

procedure TMainForm.PageControl1Change(Sender: TObject);
begin

end;

procedure TMainForm.SQLQueryParentsAfterPost();
begin

end;

procedure TMainForm.SQLQueryBooksAfterPost();
begin
  SQLQueryBooks.ApplyUpdates(0);
  SQLTransaction1.Commit();
  RefreshSql();
end;

procedure TMainForm.ListBoxUsersClick(Sender: TObject);
begin
  PreventRadioGroupUsersRolesRefresh := True;
  RadioGroupUsersRoles.Enabled := True;
  ButtonChangeUserPassword.Enabled := True;
  ButtonDeleteUser.Enabled := True;
  ButtonRenameUser.Enabled := True;
  RadioGroupUsersRoles.ItemIndex := -1;

  if (ListBoxUsers.ItemIndex = -1) then
  begin
    RadioGroupUsersRoles.ItemIndex := -1;
    RadioGroupUsersRoles.Enabled := False;
    ButtonChangeUserPassword.Enabled := False;
    ButtonDeleteUser.Enabled := False;
    ButtonRenameUser.Enabled := False;
  end
  else
  begin
    SQLQueryRoles.ParamByName('username').AsString :=
      ListBoxUsers.Items[ListBoxUsers.ItemIndex];
    SQLQueryRoles.Close();
    SQLQueryRoles.Open();

    if (DataSourceRoles.DataSet.Fields[0].AsString = 'role_admin') then
      RadioGroupUsersRoles.ItemIndex := 0;
    if (DataSourceRoles.DataSet.Fields[0].AsString = 'role_operator') then
      RadioGroupUsersRoles.ItemIndex := 1;
    if (DataSourceRoles.DataSet.Fields[0].AsString = 'role_user') then
      RadioGroupUsersRoles.ItemIndex := 2;

    if (ListBoxUsers.Items[ListBoxUsers.ItemIndex] = PQConnection1.UserName) then
    begin
      RadioGroupUsersRoles.Enabled := False;
      ButtonDeleteUser.Enabled := False;
      ButtonRenameUser.Enabled := False;
    end;
  end;

  PreventRadioGroupUsersRolesRefresh := False;
end;

procedure TMainForm.ListBoxUsersSelectionChange(Sender: TObject);
begin
  ListBoxUsers.Click();
end;

procedure TMainForm.RadioGroupUsersRolesSelectionChanged(Sender: TObject);
begin
  if not ((PreventRadioGroupUsersRolesRefresh) or
      (RadioGroupUsersRoles.ItemIndex = -1)) then
    begin
      PQConnection1.ExecuteDirect('ALTER ROLE "' +
        ListBoxUsers.Items[ListBoxUsers.ItemIndex] + '" NOCREATEROLE;');
      PQConnection1.ExecuteDirect('REVOKE role_admin FROM "' +
        ListBoxUsers.Items[ListBoxUsers.ItemIndex] + '";');
      PQConnection1.ExecuteDirect('REVOKE role_operator FROM "' +
        ListBoxUsers.Items[ListBoxUsers.ItemIndex] + '";');
      PQConnection1.ExecuteDirect('REVOKE role_user FROM "' +
        ListBoxUsers.Items[ListBoxUsers.ItemIndex] + '";');

      if (RadioGroupUsersRoles.ItemIndex = 0) then
      begin
        PQConnection1.ExecuteDirect('ALTER ROLE "' +
          ListBoxUsers.Items[ListBoxUsers.ItemIndex] + '" CREATEROLE;');
        PQConnection1.ExecuteDirect('GRANT role_admin TO "' +
          ListBoxUsers.Items[ListBoxUsers.ItemIndex] + '";');
      end;

      if (RadioGroupUsersRoles.ItemIndex = 1) then
        PQConnection1.ExecuteDirect('GRANT role_operator TO "' +
          ListBoxUsers.Items[ListBoxUsers.ItemIndex] + '";');

      if (RadioGroupUsersRoles.ItemIndex = 2) then
        PQConnection1.ExecuteDirect('GRANT role_user TO "' +
          ListBoxUsers.Items[ListBoxUsers.ItemIndex] + '";');

      SQLTransaction1.Commit();
      RefreshSql();
    end;
end;

end.

