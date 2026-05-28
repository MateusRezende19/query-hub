WITH AF_BASE AS (
    /* Visão do Planejamento e Compras */
    SELECT 
        i.CDFILIAL, 
        i.CDFILDEST, 
        i.CDFILLANC, 
        i.NRAUTOFORN, 
        a.DTAUTOFORN, 
        i.CDPRODUTO, 
        p.NMPRODUTO,
        i.DTPROGENTAF, 
        i.QTPROGENTAF, 
        i.VRPREUNIAF, 
        a.VRTOTALAF, 
        f.NMRAZSOCFORN, 
        f.NRINSJURFORN
    FROM ITEMAUTF i
    JOIN AUTOFORNE a ON a.CDFILDEST = i.CDFILDEST AND a.CDFILLANC = i.CDFILLANC AND a.NRAUTOFORN = i.NRAUTOFORN [cite: 44]
    JOIN FORNECEDOR f ON f.CDFORNECED = a.CDFORNECED [cite: 44]
    JOIN PRODUTO p ON p.CDPRODUTO = i.CDPRODUTO [cite: 44]
    WHERE i.DTPROGENTAF >= TO_DATE(:START_DATE, 'DD/MM/YYYY') [cite: 46]
      AND i.DTPROGENTAF <  TO_DATE(:END_DATE, 'DD/MM/YYYY') + 1 [cite: 46]
      AND NVL(a.IDBAIXAAF, '0') NOT IN ('2','5') [cite: 46]
),
SEFAZ_ERP_BASE AS (
    /* Visão da Realidade: O que o governo tem vs O que o sistema registrou */
    SELECT 
        inf.NRLANCTONF, 
        inf.CDFILIAL, 
        inf.NRNOTAFISC AS XML_NOTA, 
        inf.DTIMPORTACAOXML, 
        inf.DTHRPROTOCOLNFE, 
        inf.VRNOTAFISC AS XML_VR_TOTAL, 
        inf.IDSTATUSNFE, [cite: 48]
        nf.NRNOTAFISC AS ERP_NOTA, 
        nf.DTLANCAMENNF, 
        nf.DTAPROVACAO, [cite: 49]
        nf.IDSTATUS AS STATUS_ERP, 
        nf.VRNOTAFISC AS ERP_VR_TOTAL [cite: 49]
    FROM INTG_NOTAFISCAL inf [cite: 48]
    LEFT JOIN NOTAFISCAL nf ON nf.NRLANCTONF = inf.NRLANCTONF AND nf.CDFILIAL = inf.CDFILIAL [cite: 88]
    WHERE inf.DTINCLUSAO >= TO_DATE(:START_DATE, 'DD/MM/YYYY') [cite: 48]
      AND inf.DTINCLUSAO <  TO_DATE(:END_DATE, 'DD/MM/YYYY') + 1 [cite: 49]
),
RELACIONAMENTO AS (
      SELECT 
        xnf.CDFILIAL, 
        xnf.NRLANCTONF, 
        xnf.CDFILDEST, 
        xnf.NRAUTOFORN, 
        xnf.CDPRODUTO [cite: 1]
    FROM NFRELACAF xnf [cite: 4]
    WHERE NVL(xnf.IDATIVO, 'S') = 'S' [cite: 5]
)
SELECT
    /* =======================================================
       IDENTIFICADORES PRINCIPAIS
       ======================================================= */
    NVL(af.NRAUTOFORN, rel.NRAUTOFORN) AS NUM_AF,
    se.XML_NOTA                        AS NUM_NOTA_SEFAZ,
    se.ERP_NOTA                        AS NUM_NOTA_ERP,
    NVL(af.NMRAZSOCFORN, 'FORNECEDOR SEM AF') AS FORNECEDOR,
    af.NMPRODUTO,

    /* =======================================================
       CICLO DE VIDA / DATAS
       ======================================================= */
    af.DTAUTOFORN                      AS DATA_AUTORIZACAO,
    af.DTPROGENTAF                     AS DATA_PROGRAMADA,
    se.DTHRPROTOCOLNFE                 AS DATA_EMISSAO_SEFAZ,
    se.DTIMPORTACAOXML                 AS DATA_CAPTURA_ROBO, [cite: 63]
    se.DTLANCAMENNF                    AS DATA_ENTRADA_SISTEMA,

    /* =======================================================
       INDICADORES DE RISCO E ALERTAS
       ======================================================= */
    CASE
        WHEN se.XML_NOTA IS NOT NULL AND se.ERP_NOTA IS NULL AND se.IDSTATUSNFE != 'C' [cite: 83]
            THEN '🚨 ALTO RISCO: EMITIDA E NÃO LANÇADA'
        WHEN se.XML_NOTA IS NOT NULL AND af.NRAUTOFORN IS NULL
            THEN '⚠️ ALERTA: NOTA SEM AF (COMPRA NÃO AUTORIZADA)'
        WHEN se.ERP_NOTA IS NOT NULL AND se.XML_NOTA IS NULL
            THEN '⚠️ ALERTA: LANÇADA SEM XML' [cite: 80]
        WHEN se.XML_NOTA IS NULL AND se.ERP_NOTA IS NULL AND af.NRAUTOFORN IS NOT NULL
            THEN '⏳ AGUARDANDO FATURAMENTO'
        ELSE '✅ OK: FLUXO COMPLETO'
    END AS IND_RISCO_FISCAL,

    CASE
        WHEN se.DTHRPROTOCOLNFE IS NULL OR af.DTAUTOFORN IS NULL THEN 'N/A'
        WHEN TRUNC(se.DTHRPROTOCOLNFE) < TRUNC(af.DTAUTOFORN)
            THEN '🚩 EMISSÃO PRECOCE (ANTES DA AF)'
        WHEN TRUNC(se.DTHRPROTOCOLNFE) < TRUNC(af.DTPROGENTAF) [cite: 42]
            THEN 'ANTECIPADA'
        WHEN TRUNC(se.DTHRPROTOCOLNFE) > TRUNC(af.DTPROGENTAF) [cite: 43]
            THEN 'ATRASADA'
        ELSE 'NO PRAZO'
    END AS IND_PRAZO_ENTREGA,

    /* =======================================================
       EXPOSIÇÃO FINANCEIRA
       ======================================================= */
    NVL(af.VRTOTALAF, 0) AS VALOR_AF_PROGRAMADO,
    NVL(se.XML_VR_TOTAL, se.ERP_VR_TOTAL) AS VALOR_NOTA_REAL, [cite: 85]
    
    CASE
        WHEN se.XML_NOTA IS NOT NULL AND se.ERP_NOTA IS NULL AND se.IDSTATUSNFE != 'C' [cite: 83]
            THEN ROUND(NVL(se.XML_VR_TOTAL, 0) * 1.02, 2) /* Valor Exposição Total + 2% custas de protesto mantidos */ [cite: 86]
        ELSE 0
    END AS VALOR_EXPOSICAO_PROTESTO

FROM AF_BASE af
/* FULL OUTER JOIN garante que não perdemos nem AFs pendentes, nem Notas frias */
FULL OUTER JOIN RELACIONAMENTO rel
    ON rel.NRAUTOFORN = af.NRAUTOFORN 
   AND rel.CDPRODUTO = af.CDPRODUTO 
   AND rel.CDFILDEST = af.CDFILDEST
FULL OUTER JOIN SEFAZ_ERP_BASE se
    ON se.NRLANCTONF = rel.NRLANCTONF 
   AND se.CDFILIAL = rel.CDFILIAL