
/*************************************************************************************
*                                                                                    *
*                       TABELAS DE SAÍDA: primeiro nível                             *
*   idOrgao será completado com SQL após criação da tabela                           *
*                                                                                    *
**************************************************************************************/


/*Criar tabela de Orgaos*/
data AGT_FIN.ogeOrgao;
	set AGT_FIN.ogeraw_wrk;
	idOrgao=_N_; 
	nmOrgao=scan(texto, 2,':');
	keep idOrgao nmOrgao numLinha;
	where tipo = 'ORGAO'; 
run;

proc sql;
	create table agt_fin.ogebloco_categoria as
	select monotonic() 		as idCategoria,
		   compbl(texto) 	as nmCategoria,
		   numLinha,
	(
	select max(o.idOrgao)
	from agt_fin.ogeorgao o
	where o.numLinha < c.numLinha
	) as idOrgao
	from agt_fin.ogeraw_wrk c
	where tipo in ('CATEG');
quit;

/*Agora posso fazer a tabela de Titulo*/
proc sql;
	create table work.ogeBloco_Titulo as
	select /*0 as idTitulo,*/
		   scan(substr(texto, 1,length(texto)-find(texto,scan(compbl(texto), -2,' '),1)),1,' ')	as nmTitulo,
		   numLinha,
	(
	select max(o.idOrgao)
	from agt_fin.ogeorgao o
	where o.numLinha < t.numLinha
	) as idOrgao,
	(
	select max(c.idCategoria)
	from agt_fin.ogebloco_categoria c
	where c.numLinha < t.numLinha
	) as idCategoria
	from agt_fin.ogeraw_wrk t
	where tipo in ('TITLE')

	UNION ALL

	select 
	compbl(substr(texto, 1,find(texto,scan(texto, -1,' '),1)-1)) /*as nmTitulo*/,
	numLinha,
	(
	select max(o.idOrgao)
	from agt_fin.ogeorgao o
	where o.numLinha < w.numLinha
	) /*as idOrgao*/,
	(
	select max(c.idCategoria)
	from agt_fin.ogebloco_categoria c
	where c.numLinha < w.numLinha
	) /*as idCategoria*/
	from agt_fin.ogeraw_wrk w
	where numlinha in (select numlinha from work.ogeraw_subtt where tipo = 'TAB0C')
	and g contains 'Total'
	order by numLinha;

	create table agt_fin.ogeBloco_Titulo as
	select monotonic() as idTitulo,*
	from work.ogeBloco_Titulo
	order by numlinha;

	drop table work.ogeBloco_Titulo;
quit;


/************************************************************************
* 
*  Saída final para OGE_ANGOLA
* 
************************************************************************/

/*Construindo as referências: início e fim das páginas*/
data AGT_FIN.ogepageInit;
	set AGT_FIN.ogeraw_wrk;
	IF scan(texto,1,':')='Página' AND tipo = 'HEADR' THEN
		DO
			numPageIni = input(compbl(scan(texto,2,':')),4.);
		END;
	ELSE IF tipo = 'FOOTR' THEN
		do
			numPageFim = input(compbl(scan(texto,1,'=')),3.);
		end;
	ELSE delete;
	where tipo in ('HEADR','FOOTR');
	keep numPageIni numPageFim numLinha;
run;


/**********************************************************************



************************************************************************/

proc sql;
	create table work.ogebloco_detalhe as
	select numLinha,nmDetalhe,valorDetalhe
	from work.ogeraw_subtt
	where tipo in ('TAB0A','TAB0B')
	union all
	select numLinha,nmDetalhe,valorDetalhe
	from work.ogeraw_TAB
	where tipo not in ('TABNO')
	order by numlinha;

	drop table work.ogeraw_subtt;
	drop table work.ogeraw_tab;
quit;

proc sql;
	create table agt_fin.ogebloco_detalhe as
	select 
	monotonic() as idDetalhe,
	(
		select max(t.idTitulo)
		from agt_fin.ogebloco_titulo t
		where t.numLinha < d.numLinha
	) as idTitulo, d.*
	from work.ogebloco_detalhe d
	order by numLinha;
quit;

proc sql ;
	create table agt_fin.OGE_Angola&anoOGE as
    select d.numlinha, d.nmDetalhe as Detalhe, d.valorDetalhe as Valor_Akz, 
		o.nmOrgao as Orgao, c.nmCategoria as Categoria, t.nmTitulo as Titulo, 
		(
		select sum(max(p.numPageFim),1)
		from AGT_FIN.ogePageInit p 
		where p.numPageIni is missing 
		and p.numLinha < d.numLinha 
		) 
		as PaginaSeq,
		(
		select sum(max(pi.numPageIni),1)
		from AGT_FIN.ogePageInit pi 
		where pi.numPageFim is missing 
		and pi.numLinha < d.numLinha 
		) - 1
		as PaginaDoc,
		"&anoOGE" as Ano_OGE,
		"&dataOGE" as Data_OGE,
		"&nomeArquivoOGE" as Ficheiro
	from agt_fin.ogebloco_detalhe d
	inner join agt_fin.ogebloco_titulo t    on t.idTitulo = d.idTitulo
	inner join agt_fin.ogeOrgao o           on o.idOrgao = t.idOrgao
	inner join agt_fin.ogebloco_categoria c on c.idCategoria = t.idCategoria;
quit;
