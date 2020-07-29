/**********************************************
*
*  Trabalhando os tipos de dados para extração  
*
***********************************************/

/*UPDATING false ORGAO lines... actually, they are Title lines (second title line)*/
proc sql;
	create table work.numLinhaTemp as
	select numlinha,texto, tipo
	from AGT_FIN.ogeraw_wrk
	where tipo = 'ORGAO'
	and texto not contains ':';

/*Marcar linhas TITL2 porque elas complementam o texto de SUBTT, uma bifurcação de TITLE*/

	update AGT_FIN.ogeraw_wrk
	set tipo = 'TITL2'
	where numlinha in (
		select numLinha
		from work.numLinhaTemp
	);

	drop table work.numLinhaTemp;
quit;

/*Criando SUBTT, as linhas com formatação aparente de título, mas que não são...*/
proc sql;
	/*Isso aqui realmente é título*/
	create table numLinhaTituloTemp as
   	select numlinha
   	from agt_fin.ogeraw_wrk
  	where tipo in ('TITLE')
	and scan(compbl(texto), -1,' ') = '%';

/*Update para o que não é TITLE real virar SUBTT*/

	update agt_fin.ogeraw_wrk
	set tipo = 'SUBTT'
	where tipo = 'TITLE'
	and numLinha not in(
		select numLinha
		from numLinhaTituloTemp
	);

	drop table numLinhaTituloTemp;
quit;

/* 
   Ajuste de títulos e cabeçalhos. 
   Fazer as categorias iguais a ARQVO ficarem todas ARQV%

*/

proc sql;
	create table work.numLinhaTemp as
	select numlinha
	from agt_fin.ogeraw_wrk
	where tipo in ('CATEG')
	and texto = (
		select texto
		from agt_fin.ogeraw_wrk
		where tipo in ('ARQVO')
		group by texto
	);

	update agt_fin.ogeraw_wrk
	set tipo = 'ARQVS' /*para diferenciar o nome no cabeçalho do primeiro de todos...*/
	where numLinha in (
		select numLinha
		from work.numLinhaTemp
	); 

	drop table work.numLinhaTemp;
quit;

/*Verificação de tipos*/
proc sql;
	select tipo, count(*) as Ocorr/*, min(numLinha) as First*/
	from AGT_FIN.ogeraw_wrk
	group by tipo;
quit;

/********************************************************************************************
*
*  Agora tabela de Subtitulos, muito importante para mostrar o detalhe corretamente
*  A tabela de Subtitulo, na verdade, não existe... Seria um TAB0A e TAB0B...
*
*********************************************************************************************/

/* (início) Novo código de análise*/
data work.ogeraw_subtt;
	set agt_fin.ogeraw_wrk (keep=texto numlinha tipo);

	valorDetalheStr = scan(compbl(texto), -2,' ');

	if anydigit(valorDetalheStr) > 0 then
		do;
			achar = (find(texto, scan(texto, -2,' '))-1);
			nmDetalhe = substr(texto, 1,achar-1);
			valorDetalhe = input(valorDetalheStr,COMMAX20.2); /*para entender decimal com , e milhar com .*/
			tipo = 'TAB0A';
		end;
	else 
		do;
			nmDetalhe = compbl(substr(texto, 1,find(texto,scan(texto, -1,' '),1)-1));
			valorDetalhe = input(scan(texto, -1,' '),COMMAX20.2);
			tipo = 'TAB0B';
		end;

	if (tipo = 'TAB0B' and valorDetalhe = . ) 
		then tipo = 'TAB0C';

	where tipo = 'SUBTT';
	drop achar texto valorDetalheStr;
run;


/************************************** 
*	Ajuste de nmDetalhe com TITL2... 
***************************************/

proc sql;
	create table work.nomeTemp as
	select s.numLinha, catx(' ', s.nmDetalhe, w.texto) as nmDetalheNovo, 
			w.numLinha as numLinhaTitl2, w.texto
	from work.ogeraw_subtt s
	inner join agt_fin.ogeraw_wrk w on w.numlinha = (s.numlinha +1)
		and w.tipo = 'TITL2'
	where s.tipo in ('TAB0A','TAB0B')
	order by s.numLinha;
quit;

data work.ogeraw_subtt;
	merge work.nomeTemp (in=t) work.ogeraw_subtt (in=w);
	by numLinha;

	if t and w then nmDetalhe = nmDetalheNovo;
	else nmDetalhe = nmDetalhe;

	drop texto nmDetalheNovo;
run;

proc sql;
	drop table work.nomeTemp;
quit;


/*************************************************** 
*	Agora vou criar outra work (temporária)
*	para trablhar com os TAB01s
****************************************************/

data work.ogeraw_tab;
	set agt_fin.ogeraw_wrk (keep=texto numlinha tipo);

	valorDetalheStr = scan(compbl(texto), -2,' ');
	achaValorA = find(valorDetalheStr,',');
	achaValorB = find(valorDetalheStr,'.');

	if (anydigit(valorDetalheStr) > 0 AND achaValorA > 0 AND achaValorB > 0) then
		do;
			achar = (find(texto, scan(texto, -2,' '))-1);
			nmDetalhe = substr(texto, 1,achar-1);
			valorDetalhe = input(valorDetalheStr,COMMAX20.2); /*para entender decimal com , e milhar com .*/
		end;
	else 
		do;
			nmDetalhe = compbl(substr(texto, 1,find(texto,scan(texto, -1,' '),1)-1));
			valorDetalhe = input(scan(texto, -1,' '),COMMAX20.2);
			tipo = compress(substr(tipo,1,1) || substr(tipo,3,1) || substr(tipo,5,1) ||'NO');
		end;

	if (substr(tipo,1,2) = 'TB' and valorDetalhe = . ) 
		then tipo = 'TABNO';

	where tipo in ('TAB01', 'TAB02','TAB03');
	drop achar achaValorA achaValorB ok valorDetalheStr texto;
run;
/* (fim) Novo código de análise*/
