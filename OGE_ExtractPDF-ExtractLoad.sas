/*******************************************************************
*
*	A-PDF Extractor was used to convert PDF to TXT
*	It needs to be done prior this SAS execution.
*
********************************************************************/

libname AGT_FIN 'H:\Dados\MIGRA_FIN-PDF\Rev2-2020\SAS_DB\';
/*A partir de OGE_ExtractPDF-20190828 v03*/

/*Aqui eu pego o texto "limpo" - direto do texto para a memória, um colunão com tudo
	ESPACO: área que o conversor de PDF para TEXTO deixa e praticamente só serve para identificar 
			a página da entrada em PDF original.
*/

/*Este parâmetros são para forçar o SAS a ler a linha como é.
  Buscar um delimitador que não existe força a termos apenas uma coluna.
*/

%let ogeFile2018    = H:\Dados\MIGRA_FIN-PDF\OGE Dotação Orçamental por Órgão - 2018.txt;
%let ogeFile2019    = H:\Dados\MIGRA_FIN-PDF\OGE minfin063984 - 20190809.txt;
%let ogeFile2020    = H:\Dados\MIGRA_FIN-PDF\Rev2-2020\OGE v2 - AO_2020.txt;

%let ogeFile = &ogeFile2020;

data AGT_FIN.ogeRAW;
	infile "&ogeFile" dlm= '#' dsd missover TRUNCOVER;
	input 	@1   ESPACO $9. 
			@10  TEXTO $126. ; 
	numlinha = _N_;
run;

/* Aqui é feita uma espécie de tokenização do texto.
	Ele foi quebrado em 9 partes, para identificar os tipos de linha.
	A depender das partes em branco, a linha possui um tipo específico de dados.
*/

data AGT_FIN.ogeRAW_type;
	infile "&ogeFile" dlm= '#' dsd missover TRUNCOVER;
	input 	@1   A $9. 
			@10  B $2. 
			@12  C $2. 
			@14  D $2. 
			@16  E $2.
			@18	 reading $26.
			@44  trechoMeio $15.
			@59  textoCompl $46. 
			@105 trechoFim $31.; 
	numlinha = _N_;
run;

/*
	Com o texto devidamente particionado, posso avaliar o que é cada linha...
	Primeira parte: identificar as partes do texto.
*/

data AGT_FIN.ogeRAW_type;
	set AGT_FIN.ogeRAW_type;
	length tipo $5.;
	/* Análise do conteúdo dos pontos do texto 
		Por quê compress? Para tirar espaços...
		Por quê -1? Pq o tamanho do vazio é 1. Faço vazio ficar 0.
		O menor pedaço de texto tem 2 caracteres. 
		Assim terei 0 para vazio, 1 para texto em colunas de 2 caracteres
			e maior que 1 onde pode haver mais texto (e há conteúdo)
	*/
	pt01 = length(compress(A))-1; 
	pt02 = length(compress(B))-1;
	pt03 = length(compress(C))-1;
	pt04 = length(compress(D))-1;
	pt05 = length(compress(E))-1;
	pt06 = length(compress(trechoMeio))-1;
	pt07 = length(compress(trechoFim))-1;
run;

data AGT_FIN.ogeRAW_type (drop=teste);
	set AGT_FIN.ogeRAW_type;

	/* Avaliar 
		ptN = 0 significa vazio.
		ptN > 0 significa preenchido.
	*/

	/*Avaliar v04, com ajustes */
	IF pt01 > 0 AND pt06 = 0 AND pt07 = 0  then tipo = 'FOOTR';
	IF pt02 > 0 AND pt07 > 0               then tipo = 'TITLE';
	IF pt01 = 0 AND pt02 > 0 AND pt07 = 0  then tipo = 'ORGAO';
	IF pt02 = 0 AND pt06 = 0 AND pt07 > 0  then tipo = 'HRITE';
	IF pt01 = 0 AND pt02 = 0 AND pt06 = 0 
							 AND pt07 = 0  then tipo = 'EMPTY';
	IF pt02 = 0 AND pt03 > 0               then tipo = 'TAB01';
	IF pt02 = 0 AND pt03 = 0 AND pt04 > 0  then tipo = 'TAB02';
	IF pt02 = 0 AND pt03 = 0 AND pt04 = 0
							 AND pt05 > 0  then tipo = 'TAB03';

	/* pt02> 0, pt03>0, pt04> 0*/
	teste = compress(catx('',catx('',B,C),D));
	IF teste = 'Total' 
				AND tipo = 'TITLE'        then tipo = 'TOTAL';
	IF pt02 = 0 AND pt03 = 0 AND pt04 = 0			
				AND pt05 = 0 AND pt06 > 0 then tipo = 'CATEG';
	IF pt02 = 0 AND pt03 = 0 AND pt04 = 0			
				AND pt05 = 0 AND pt06 = 0  
							 AND pt07 > 1 then tipo = 'HEADR';

run;

proc sql;
	select min(numLinha)
	into :ARQVO
	from agt_fin.ogeRaw_type
	where tipo = 'CATEG'
	and numLinha < 10;

	update agt_fin.ogeRaw_type
	set tipo = 'ARQVO'
	where numLinha = &ARQVO;
quit;


/*************************************************************
* Informações sobre o arquivo
* Exercício                       &anoOGE
* Emissão                         &dataOGE
* Página Inicial				  &pagInicioOGE
* Qual é o arquivo de Orçamento?  &nomeArquivoOGE
**************************************************************/

proc sql;
	select distinct scan(trechoFim,2,' :')
	into :anoOGE
	from agt_fin.ogeraw_type
	where tipo = 'HEADR'
	and trechoFim contains 'Exercício'
	and numLinha < 10;

	select distinct scan(trechoFim,2,' :')
	into :dataOGE
	from agt_fin.ogeraw_type
	where tipo = 'HEADR'
	and trechoFim contains 'Emissão'
	and numLinha < 10;

	select distinct scan(trechoFim,2,' :')
	into :pagInicioOGE
	from agt_fin.ogeraw_type
	where tipo = 'HEADR'
	and trechoFim contains 'gina'
	and numLinha < 10;

	select compbl(texto)
	into :nomeArquivoOGE
	from agt_fin.ogeRaw
	where numLinha = &ARQVO;
quit;

/*teste e verificação dos tipos*/
proc sql;
	select tipo, count(*) as total
	from agt_fin.ogeraw_type
	group by tipo;

quit;

proc sql;
	/*describe table AGT_FIN.ogeraw_type;	*/
	create table AGT_FIN.ogeraw_wrk as
	select t.numLinha, r.texto, t.tipo, t.A, t.B, t.C, t.D, t.E, t.trechoMeio as F, t.trechoFim as G,
	length(compbl(A))-1 as sizeA, length(compbl(B))-1 as sizaB, length(compbl(C))-1 as sizeC, length(compbl(D))-1 as sizeD,
	length(compbl(E))-1 as sizeE, length(compbl(trechoMeio))-1 as sizeF, length(compbl(trechoFim))-1 as sizeG
	from AGT_FIN.ogeRAW r
	inner join AGT_FIN.ogeraw_type t on r.numlinha = t.numLinha;

	drop table agt_fin.ogeraw_type;
	drop table agt_fin.ogeraw;
quit;