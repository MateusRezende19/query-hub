SELECT
    i.CDFILIMOVI              AS cod_filial,
    f.NMFILIAL                AS nome_filial,
    i.NRLANCESTQ              AS nr_lancamento,
    i.NRSEQITEMREQEST         AS seq_item,
    i.DTLANCMOVI              AS dt_movimento,
    i.CDLOCALESTOQ            AS cod_local,
    i.CDPRODMOVI              AS cod_produto,
    p.NMPRODUTO               AS nome_produto,
    i.QTLANCTOEST             AS quantidade,
    i.VRLANCTOEST             AS valor_total,
    CASE WHEN i.QTLANCTOEST <> 0
         THEN i.VRLANCTOEST / i.QTLANCTOEST END AS valor_unitario,
    i.CDTIPOOPER              AS cod_tipo_operacao,
    tp.NMTIPOOPER             AS nome_tipo_operacao,
    i.IDTIPOMOVI              AS tipo_movimento,
    i.NRREQUESTO              AS nr_requisicao
FROM SOLUCOES.ITLANCTOEST i
LEFT JOIN SOLUCOES.PRODUTO p
       ON p.CDPRODUTO = i.CDPRODMOVI
LEFT JOIN SOLUCOES.FILIAL f
       ON f.CDFILIAL = i.CDFILIMOVI
LEFT JOIN SOLUCOES.TIPOOPERAC tp
       ON tp.CDTIPOOPER = i.CDTIPOOPER
WHERE i.IDENTRSAIDOP = 'S'
  AND i.DTLANCMOVI >= TO_DATE(:DT_INICIAL, 'DD/MM/YYYY')
  AND i.DTLANCMOVI <  TO_DATE(:DT_FINAL,   'DD/MM/YYYY') + 1;