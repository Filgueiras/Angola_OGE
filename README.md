# Angola_OGE
Rotina de extração e leitura de valores dos PDF de orçamento anual de Angola por Órgão (experiência com SAS EG).

Ficheiro (arquivo) PDF público e disponível para download em 
https://www.minfin.gov.ao/PortalMinfin/#!/materias-de-realce/orcamento-geral-do-estado/oge-do-ano-corrente

1) Faça download do arquivo (ficheiro) "Dotaçação Orçamental por Órgão".
2) Converta para texto usando o A-PDF Converter (converte de PDF para texto com linhas na mesma sequência da visualização).
  a) Tentei outros conversores (Python e Java) e a conversão ficava initeligível (linhas com sequencia embaralhada);
3) Abrir SAS Enterprise Guide (SAS 9.4);
4) Actualize os locais da máquina (onde está o ficheiro txt e onde ficará a biblioteca SAS local);
5) Só executar os 3 passos do projecto.

Notas: 
1) O formato de PDF esperado é o que tem sido utilizado pelo menos desde 2017 pelo Governo de Angola (e ainda actual em 29/07/2020).
2) Há arquivos PDFs e TXTs gerados a partir deles no repositório, para ficar de exemplo.
3) A instalação para Windows do extrator de PDFs também está disponível no repositório.
