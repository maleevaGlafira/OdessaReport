-- ЭТАП 1: Отбираем только заявки за нужный период
WITH FILTERED_NZ AS (
    SELECT ID, NOMER, DT_IN, ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES, ID_REVS, ID_ALIEN, ID_SOD
    FROM NZAVJAV
    WHERE DELZ = 0 AND (IS_OTL IS NULL OR IS_OTL <> 1)
      AND ID_ATTACH IN (:PRINAD1, :PRINAD2)
      AND DT_IN > :DT_BEGIN AND DT_IN <= :DT_FINISH
),
FILTERED_Z AS (
    SELECT ID, NOMER, DT_IN, ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES, ID_REVS, ID_ALIEN, ID_SOD
    FROM ZAVJAV
    WHERE DELZ = 0 AND (IS_OTL IS NULL OR IS_OTL <> 1)
      AND ID_ATTACH IN (:PRINAD1, :PRINAD2)
      AND DT_IN > :DT_BEGIN AND DT_IN <= :DT_FINISH
),

-- ЭТАП 2: Из отфильтрованных заявок оставляем только те, у которых есть хотя бы один длинный выезд
NZ_WITH_LONG AS (
    SELECT FN.*
    FROM FILTERED_NZ FN
    WHERE EXISTS (
        SELECT 1 FROM OBORS OJ
        JOIN NNARAD NN ON OJ.ID_NAR = NN.ID
        WHERE OJ.ID_ZAV = FN.ID
          AND NN.DT_OUT > NN.DT_IN + 0.0208
    )
),
Z_WITH_LONG AS (
    SELECT FZ.*
    FROM FILTERED_Z FZ
    WHERE EXISTS (
        SELECT 1 FROM OBORS OJ
        JOIN NARAD NN ON OJ.ID_NAR = NN.ID
        WHERE OJ.ID_ZAV = FZ.ID
          AND NN.DT_OUT > NN.DT_IN + 0.0208
    )
),

-- ЭТАП 3: Считаем адреса, где количество таких заявок > :NUMBERS
ADDRESSES_COUNT AS (
    SELECT ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES, COUNT(*) AS COUN
    FROM (
        SELECT ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES FROM NZ_WITH_LONG
        UNION ALL
        SELECT ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES FROM Z_WITH_LONG
    ) ALL_APPS
    GROUP BY ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES
    HAVING COUNT(*) > :NUMBERS
),

-- ЭТАП 3.5: НОВОЕ! Предварительно считаем статистику по выездам для каждой заявки
NZ_STATS AS (
    SELECT 
        FN.ID AS ID_ZAV,
        (SELECT COUNT(DISTINCT OJ.ID_NAR)
         FROM OBORS OJ
         JOIN NNARAD NN ON OJ.ID_NAR = NN.ID
         WHERE OJ.ID_ZAV = FN.ID 
           AND NN.DT_OUT > NN.DT_IN + 0.0208) AS COL_V,
        
        (SELECT LIST(
            CAST((SELECT COUNT(*) 
                  FROM NNARAD NN2
                  WHERE NN2.ID_ZAV = FN.ID
                    AND NN2.DT_OUT > NN2.DT_IN + 0.0208
                    AND EXISTS (SELECT 1 FROM OBORS OJ2 WHERE OJ2.ID_NAR = NN2.ID)
                    AND NN2.ID < NN.ID) + 1 AS integer) ||
            ') выезд : ' || 
            REPLACE(REPLACE(TRIM(NN.DOP_INF), ASCII_CHAR(10), ' '), ASCII_CHAR(13), ' '),
            ' '
         )
         FROM NNARAD NN
         WHERE NN.ID_ZAV = FN.ID
           AND NN.DT_OUT > NN.DT_IN + 0.0208
           AND EXISTS (SELECT 1 FROM OBORS OJ WHERE OJ.ID_NAR = NN.ID)
        ) AS DOP_INF_STR
    FROM NZ_WITH_LONG FN
),

Z_STATS AS (
    SELECT 
        FZ.ID AS ID_ZAV,
        (SELECT COUNT(DISTINCT OJ.ID_NAR)
         FROM OBORS OJ
         JOIN NARAD NN ON OJ.ID_NAR = NN.ID
         WHERE OJ.ID_ZAV = FZ.ID 
           AND NN.DT_OUT > NN.DT_IN + 0.0208) AS COL_V,
        
        (SELECT LIST(
            CAST((SELECT COUNT(*) 
                  FROM NARAD NN2
                  WHERE NN2.ID_ZAV = FZ.ID
                    AND NN2.DT_OUT > NN2.DT_IN + 0.0208
                    AND EXISTS (SELECT 1 FROM OBORS OJ2 WHERE OJ2.ID_NAR = NN2.ID)
                    AND NN2.ID < NN.ID) + 1 AS integer) ||
            ') выезд : ' || 
            REPLACE(REPLACE(TRIM(NN.DOP_INF), ASCII_CHAR(10), ' '), ASCII_CHAR(13), ' '),
            ' '
         )
         FROM NARAD NN
         WHERE NN.ID_ZAV = FZ.ID
           AND NN.DT_OUT > NN.DT_IN + 0.0208
           AND EXISTS (SELECT 1 FROM OBORS OJ WHERE OJ.ID_NAR = NN.ID)
        ) AS DOP_INF_STR
    FROM Z_WITH_LONG FZ
)

-- ЭТАП 4: Финальная выборка - теперь БЕЗ тяжелых подзапросов!
SELECT 
    NZ.NOMER AS NOMER_2, 
    NZ.DT_IN, 
    SR.NAME_R,
    (select adres from GET_ADRES(NZ.ID_UL1, NZ.ID_UL2, NZ.KOD_UL, '', NZ.ID_DOPADRES)) AS F_1,
    trim(SO.NAME_R) AS NAME_R1,
    trim(SS.NAME_R) AS NAME_2,
    COALESCE(NZ_S.COL_V, 0) AS COL_V,
    AC.COUN,
    NZ_S.DOP_INF_STR AS DOP_INF
FROM ADDRESSES_COUNT AC
JOIN NZ_WITH_LONG NZ ON NZ.ID_UL1 = AC.ID_UL1 
                    AND NZ.ID_UL2 = AC.ID_UL2 
                    AND NZ.KOD_UL = AC.KOD_UL 
                    AND NZ.ID_DOPADRES = AC.ID_DOPADRES
LEFT JOIN NZ_STATS NZ_S ON NZ_S.ID_ZAV = NZ.ID
JOIN S_REVS SR ON SR.ID = NZ.ID_REVS
JOIN S_OWNER SO ON SO.ID = NZ.ID_ALIEN
LEFT JOIN S_SOD SS ON SS.ID = NZ.ID_SOD

UNION ALL

SELECT 
    Z.NOMER, 
    Z.DT_IN, 
    SR.NAME_R,
    (select ADRES from
    GET_ADRES(Z.ID_UL1, Z.ID_UL2, Z.KOD_UL, '', Z.ID_DOPADRES)) ,
    SO.NAME_R, 
    SS.NAME_R,
    COALESCE(Z_S.COL_V, 0) AS COL_V,
    AC.COUN,
    Z_S.DOP_INF_STR AS DOP_INF
FROM ADDRESSES_COUNT AC
JOIN Z_WITH_LONG Z ON Z.ID_UL1 = AC.ID_UL1 
                  AND Z.ID_UL2 = AC.ID_UL2 
                  AND Z.KOD_UL = AC.KOD_UL 
                  AND Z.ID_DOPADRES = AC.ID_DOPADRES
LEFT JOIN Z_STATS Z_S ON Z_S.ID_ZAV = Z.ID
JOIN S_REVS SR ON SR.ID = Z.ID_REVS
JOIN S_OWNER SO ON SO.ID = Z.ID_ALIEN
LEFT JOIN S_SOD SS ON SS.ID = Z.ID_SOD

ORDER BY 4;



SELECT 
        FZ.ID AS ID_ZAV,
        (SELECT COUNT(DISTINCT OJ.ID_NAR)
         FROM OBORS OJ
         JOIN NARAD NN ON OJ.ID_NAR = NN.ID
         WHERE OJ.ID_ZAV = FZ.ID 
           AND NN.DT_OUT > NN.DT_IN + 0.0208) AS COL_V,
        
        (SELECT LIST(
            CAST((SELECT COUNT(*) 
                  FROM NARAD NN2
                  WHERE NN2.ID_ZAV = FZ.ID
                    AND NN2.DT_OUT > NN2.DT_IN + 0.0208
                    AND EXISTS (SELECT 1 FROM OBORS OJ2 WHERE OJ2.ID_NAR = NN2.ID)
                    AND NN2.ID < NN.ID) + 1 AS integer) ||
            ') выезд : ' || 
            REPLACE(REPLACE(TRIM(NN.DOP_INF), ASCII_CHAR(10), ' '), ASCII_CHAR(13), ' '),
            ' '
         )
         FROM NARAD NN
         WHERE NN.ID_ZAV = FZ.ID
           AND NN.DT_OUT > NN.DT_IN + 0.0208
           AND EXISTS (SELECT 1 FROM OBORS OJ WHERE OJ.ID_NAR = NN.ID)
        ) AS DOP_INF_STR
 FROM nzavjav nzavjav join
(
 SELECT ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES, COUNT(*) AS COUN
    FROM (
     SELECT ID, NOMER, DT_IN, ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES, ID_REVS, ID_ALIEN, ID_SOD
        FROM NZAVJAV FN
        WHERE DELZ = 0 AND (IS_OTL IS NULL OR IS_OTL <> 1)
          AND ID_ATTACH IN (:PRINAD1, :PRINAD2)
          AND DT_IN > :DT_BEGIN AND DT_IN <= :DT_FINISH
          and EXISTS (
            SELECT 1 FROM OBORS OJ
            JOIN NNARAD NN ON OJ.ID_NAR = NN.ID
            WHERE OJ.ID_ZAV = FN.ID
              AND NN.DT_OUT > NN.DT_IN + 0.0208
          )
    
    union all
    
    SELECT ID, NOMER, DT_IN, ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES, ID_REVS, ID_ALIEN, ID_SOD
        FROM ZAVJAV FZ
        WHERE DELZ = 0 AND (IS_OTL IS NULL OR IS_OTL <> 1)
          AND ID_ATTACH IN (:PRINAD1, :PRINAD2)
          AND DT_IN > :DT_BEGIN AND DT_IN <= :DT_FINISH
          and exists(
            SELECT 1 FROM OBORS OJ
            JOIN NARAD NN ON OJ.ID_NAR = NN.ID
            WHERE OJ.ID_ZAV = FZ.ID
              AND NN.DT_OUT > NN.DT_IN + 0.0208
        )   
    ) ALL_APPS
    GROUP BY ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES
    HAVING COUNT(*) > :NUMBERS
 )
   
    
