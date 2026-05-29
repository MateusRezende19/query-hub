SELECT
    -- IDENTIFICACAO BASICA
    i.CDFILIMOVI                                              AS cod_filial_origem,
    f.NMFILIAL                                                AS nome_filial_origem,
    i.NRLANCESTQ                                              AS nr_lancamento,
    i.NRSEQITEMREQEST                                         AS seq_item,

    -- DATAS E HORARIOS
    i.DTLANCMOVI                                              AS dt_movimento,
    TO_CHAR(l.DTINCLUSAO, 'DD/MM/YYYY HH24:MI:SS')            AS dt_hora_lancamento,
    TO_CHAR(l.DTINCLUSAO, 'HH24:MI')                          AS hora_lancamento,
    TO_CHAR(l.DTINCLUSAO, 'HH24')                             AS hora_cheia,
    CASE
        WHEN TO_NUMBER(TO_CHAR(l.DTINCLUSAO, 'HH24')) BETWEEN 6  AND 11 THEN 'MANHA'
        WHEN TO_NUMBER(TO_CHAR(l.DTINCLUSAO, 'HH24')) BETWEEN 12 AND 17 THEN 'TARDE'
        WHEN TO_NUMBER(TO_CHAR(l.DTINCLUSAO, 'HH24')) BETWEEN 18 AND 22 THEN 'NOITE'
        ELSE 'MADRUGADA'
    END                                                       AS turno,
    TRUNC(l.DTINCLUSAO) - TRUNC(i.DTLANCMOVI)                 AS dias_diferenca_lancamento,
    CASE
        WHEN TRUNC(l.DTINCLUSAO) - TRUNC(i.DTLANCMOVI) = 0 THEN 'MESMO DIA'
        WHEN TRUNC(l.DTINCLUSAO) - TRUNC(i.DTLANCMOVI) > 0 THEN 'RETROATIVO (' || (TRUNC(l.DTINCLUSAO) - TRUNC(i.DTLANCMOVI)) || ' dia(s))'
        WHEN TRUNC(l.DTINCLUSAO) - TRUNC(i.DTLANCMOVI) < 0 THEN 'PROGRAMADO (' || ABS(TRUNC(l.DTINCLUSAO) - TRUNC(i.DTLANCMOVI)) || ' dia(s) a frente)'
    END                                                       AS tipo_defasagem,
    l.DSLANCESTQ                                              AS descricao_lancamento,

    -- PRODUTO
    i.CDPRODMOVI                                              AS cod_produto,
    p.NMPRODUTO                                               AS nome_produto,
    i.QTLANCTOEST                                             AS quantidade,
    i.VRLANCTOEST                                             AS valor_total,
    CASE WHEN i.QTLANCTOEST <> 0
         THEN i.VRLANCTOEST / i.QTLANCTOEST END               AS valor_unitario,

    -- LOCAL DE ORIGEM
    i.CDLOCALESTOQ                                            AS cod_local_origem,
    lo.DSLOCALESTOQ                                           AS nome_local_origem,

    -- TIPO DE OPERACAO
    i.CDTIPOOPER                                              AS cod_tipo_operacao,
    tp.NMTIPOOPER                                             AS nome_tipo_operacao,
    CASE
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%REQUISI%'
             THEN 'CONSUMO INTERNO - Saiu do almoxarifado para uso na operacao.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%CONSUMO%'
             THEN 'CONSUMO DIRETO - Utilizado internamente sem requisicao formal.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%TRANSFER%'
             THEN 'TRANSFERENCIA ENTRE FILIAIS - Nao consumido, apenas mudou de filial.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%VENDA%' OR UPPER(tp.NMTIPOOPER) LIKE '%FATURA%'
             THEN 'VENDA - Saiu por faturamento ao cliente.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%PERDA%' OR UPPER(tp.NMTIPOOPER) LIKE '%QUEBRA%'
          OR UPPER(tp.NMTIPOOPER) LIKE '%AVARIA%' OR UPPER(tp.NMTIPOOPER) LIKE '%DESCARTE%'
          OR UPPER(tp.NMTIPOOPER) LIKE '%VENCID%'
             THEN 'PERDA / PREJUIZO - Produto descartado.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%AJUSTE%' OR UPPER(tp.NMTIPOOPER) LIKE '%INVENT%'
             THEN 'AJUSTE DE INVENTARIO - Correcao apos contagem fisica.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%DEVOLU%' AND UPPER(tp.NMTIPOOPER) LIKE '%FORNEC%'
             THEN 'DEVOLUCAO AO FORNECEDOR.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%DEVOLU%'
             THEN 'DEVOLUCAO - Verificar destinatario.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%REMESSA%' AND UPPER(tp.NMTIPOOPER) LIKE '%CONSERTO%'
             THEN 'REMESSA P/ CONSERTO - Saiu temporariamente.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%REMESSA%' AND UPPER(tp.NMTIPOOPER) LIKE '%INDUSTRI%'
             THEN 'REMESSA P/ INDUSTRIALIZACAO.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%COMODATO%' OR UPPER(tp.NMTIPOOPER) LIKE '%EMPRESTIMO%'
             THEN 'COMODATO / EMPRESTIMO - Saiu temporariamente.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%DEMONST%' OR UPPER(tp.NMTIPOOPER) LIKE '%AMOSTRA%'
             THEN 'DEMONSTRACAO / AMOSTRA.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%DOACAO%' OR UPPER(tp.NMTIPOOPER) LIKE '%BRINDE%'
          OR UPPER(tp.NMTIPOOPER) LIKE '%CORTESIA%' OR UPPER(tp.NMTIPOOPER) LIKE '%BONIFIC%'
             THEN 'DOACAO / BRINDE / BONIFICACAO - Entregue sem cobranca.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%SIMPLES REMESSA%' OR UPPER(tp.NMTIPOOPER) LIKE '%REMESSA%'
             THEN 'SIMPLES REMESSA - Saida sem caracter comercial.'
        WHEN UPPER(tp.NMTIPOOPER) LIKE '%PRODUC%'
             THEN 'CONSUMO POR PRODUCAO - Materia-prima utilizada na fabricacao.'
        WHEN tp.NMTIPOOPER IS NULL
             THEN 'TIPO DE OPERACAO NAO IDENTIFICADO.'
        ELSE 'OUTRA OPERACAO - ' || tp.NMTIPOOPER
    END                                                       AS explica_tipo_operacao,

    -- TIPO TECNICO DE MOVIMENTO
    i.IDTIPOMOVI                                              AS tipo_movimento,
    CASE i.IDTIPOMOVI
        WHEN '4' THEN 'MOVIMENTO NORMAL DE SAIDA.'
        WHEN '5' THEN 'MOVIMENTO DE AJUSTE/TRANSFERENCIA.'
        WHEN '2' THEN 'MOVIMENTO NORMAL DE ENTRADA (investigar se em saida).'
        WHEN '0' THEN 'MOVIMENTO SEM CLASSIFICACAO.'
        ELSE 'TIPO TECNICO ' || i.IDTIPOMOVI
    END                                                       AS explica_tipo_movimento,

    -- DESTINO: TRANSFERENCIA OL
    l.CDFILIALOL                                              AS cod_filial_destino_ol,
    fd.NMFILIAL                                               AS nome_filial_destino_ol,

    -- DESTINO: REQUISICAO
    i.NRREQUESTO                                              AS nr_requisicao,
    r.DSREQUESTO                                              AS descricao_requisicao,
    r.CDCENTCUST                                              AS cod_centro_custo,
    cc.NMCENTCUST                                             AS nome_centro_custo,
    r.CDSETOR                                                 AS cod_setor,
    s.NMSETOR                                                 AS nome_setor,
    r.CDLCESTENTR                                             AS cod_local_destino_req,
    lde.DSLOCALESTOQ                                          AS nome_local_destino_req,

    -- DESTINO UNIFICADO
    CASE
        WHEN l.CDFILIALOL IS NOT NULL
             THEN 'TRANSFERENCIA -> Filial: ' || COALESCE(fd.NMFILIAL, l.CDFILIALOL)
        WHEN r.NRREQUESTO IS NOT NULL
             THEN 'REQUISICAO -> Setor: ' || COALESCE(s.NMSETOR, r.CDSETOR, '?')
                  || ' / CC: ' || COALESCE(cc.NMCENTCUST, r.CDCENTCUST, '?')
        WHEN l.NRLANCTONF IS NOT NULL
             THEN 'NOTA FISCAL nr ' || l.NRLANCTONF
        WHEN l.NRPROCPROD IS NOT NULL
             THEN 'PRODUCAO nr ' || l.NRPROCPROD
        WHEN l.DSLANCESTQ IS NOT NULL
             THEN 'OBS: ' || l.DSLANCESTQ
        ELSE 'DESTINO NAO IDENTIFICADO'
    END                                                       AS destino_descricao,

    -- AUDITORIA
    l.NRLANCTONF                                              AS nr_lanc_nota_fiscal,
    l.NRPROCPROD                                              AS nr_processo_producao,
    l.CDALMOXARIFE                                            AS cod_almoxarife,
    l.CDOPERADOR                                              AS operador_lancamento

FROM SOLUCOES.ITLANCTOEST i
INNER JOIN SOLUCOES.LANCTOESTOQ l
        ON l.CDFILIAL   = i.CDFILIAL
       AND l.NRLANCESTQ = i.NRLANCESTQ
LEFT JOIN SOLUCOES.PRODUTO p
       ON p.CDPRODUTO = i.CDPRODMOVI
LEFT JOIN SOLUCOES.FILIAL f
       ON f.CDFILIAL = i.CDFILIMOVI
LEFT JOIN SOLUCOES.FILIAL fd
       ON fd.CDFILIAL = l.CDFILIALOL
LEFT JOIN SOLUCOES.TIPOOPERAC tp
       ON tp.CDTIPOOPER   = i.CDTIPOOPER
      AND tp.IDENTRSAIDOP = i.IDENTRSAIDOP
LEFT JOIN SOLUCOES.LOCALESTOQUE lo
       ON lo.CDFILIAL     = i.CDFILIMOVI
      AND lo.CDLOCALESTOQ = i.CDLOCALESTOQ
LEFT JOIN SOLUCOES.REQUESTO r
       ON r.NRREQUESTO = i.NRREQUESTO
      AND r.CDFILIAL   = i.CDFILIMOVI
LEFT JOIN SOLUCOES.CENTCUST cc
       ON cc.CDCENTCUST = r.CDCENTCUST
LEFT JOIN SOLUCOES.SETOR s
       ON s.CDSETOR = r.CDSETOR
LEFT JOIN SOLUCOES.LOCALESTOQUE lde
       ON lde.CDFILIAL     = r.CDFILIAL
      AND lde.CDLOCALESTOQ = r.CDLCESTENTR
WHERE i.IDENTRSAIDOP = 'S'
  AND (TO_DATE(TO_CHAR(i.DTLANCMOVI,'DD/MM/YYYY')) BETWEEN TO_DATE(:START_DATE, 'DD/MM/YYYY') AND TO_DATE(:END_DATE, 'DD/MM/YYYY'))