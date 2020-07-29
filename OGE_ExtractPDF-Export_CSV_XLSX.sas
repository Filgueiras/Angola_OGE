/*************************************************
  Next step is reading the dictionary tables and 
  identify how many oge_angola tables exist
*************************************************/

proc sql;
	create table agt_fin.oge_angola as
	select *
	from agt_fin.oge_angola2018
	union all
	select *
	from agt_fin.oge_angola2019
	union all
	select *
	from agt_fin.oge_angola2020
	;
quit;

proc export
	data=agt_fin.oge_angola
	outfile="H:\Dados\MIGRA_FIN-PDF\Rev2-2020\EXPORT\oge_angola_2018-2020.csv"
	dbms=dlm replace;
	delimiter=";";
run;

proc export
	data=agt_fin.oge_angola
	outfile="H:\Dados\MIGRA_FIN-PDF\Rev2-2020\EXPORT\oge_angola_2018-2020.xlsx"
	dbms=xlsx replace;
run;
