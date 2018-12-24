unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, pqconnection, sqldb, db, FileUtil, TADbSource, TAGraph,
  TASeries, TAMultiSeries, TARadialSeries, TAFuncSeries, Forms, Controls,
  Graphics, Dialogs;

type

  { TForm1 }

  TForm1 = class(TForm)
    Chart1: TChart;
    Chart1BarSeries1: TBarSeries;
    Chart2: TChart;
    Chart2PieSeries1: TPieSeries;
    Chart3: TChart;
    Chart3LineSeries1: TLineSeries;
    DataSource2: TDataSource;
    DbChartSource2: TDbChartSource;
    PQConnection1: TPQConnection;
    SQLQuery2: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

end.

