SELECT 
    NZ.NOMER AS NOMER_2, 
    NZ.DT_IN, 
    SR.NAME_R,
   (select trim(ADRES) from
    GET_ADRES(NZ.ID_UL1, NZ.ID_UL2, NZ.KOD_UL, '', NZ.ID_DOPADRES))  as F_1,
    SO.NAME_R AS NAME_R1, 
    SS.NAME_R AS NAME_2,
    COALESCE(NZ_S.COL_V, 0) AS COL_V,
    AC.COUN,
    NZ_S.DOP_INF_STR AS DOP_INF
FROM (
    -- ADDRESSES_COUNT: считаем адреса с количеством заявок > :NUMBERS
    SELECT ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES, COUNT(*) AS COUN
    FROM (
        -- UNION всех заявок с длинными выездами
        SELECT ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES
        FROM NZAVJAV FN
        WHERE FN.DELZ = 0 AND (FN.IS_OTL IS NULL OR FN.IS_OTL <> 1)
          AND FN.ID_ATTACH IN (:PRINAD1, :PRINAD2)
          AND FN.DT_IN > :DT_BEGIN AND FN.DT_IN <= :DT_FINISH
          AND EXISTS (
              SELECT 1 FROM OBORS OJ
              JOIN NNARAD NN ON OJ.ID_NAR = NN.ID
              WHERE NN.ID_ZAV = FN.ID
                AND NN.DT_OUT > NN.DT_IN + 0.0208
          )
        
        UNION ALL
        
        SELECT ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES
        FROM ZAVJAV FZ
        WHERE FZ.DELZ = 0 AND (FZ.IS_OTL IS NULL OR FZ.IS_OTL <> 1)
          AND FZ.ID_ATTACH IN (:PRINAD1, :PRINAD2)
          AND FZ.DT_IN > :DT_BEGIN AND FZ.DT_IN <= :DT_FINISH
          AND EXISTS (
              SELECT 1 FROM OBORS OJ
              JOIN NARAD NN ON OJ.ID_NAR = NN.ID
              WHERE NN.ID_ZAV = FZ.ID
                AND NN.DT_OUT > NN.DT_IN + 0.0208
          )
    ) ALL_APPS
    GROUP BY ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES
    HAVING COUNT(*) > :NUMBERS
) AC

-- JOIN к заявкам NZAVJAV
JOIN NZAVJAV NZ ON NZ.ID_UL1 = AC.ID_UL1 
               AND NZ.ID_UL2 = AC.ID_UL2 
               AND NZ.KOD_UL = AC.KOD_UL 
               AND NZ.ID_DOPADRES = AC.ID_DOPADRES
               AND NZ.DELZ = 0 AND (NZ.IS_OTL IS NULL OR NZ.IS_OTL <> 1)
               AND NZ.ID_ATTACH IN (:PRINAD1, :PRINAD2)
               AND NZ.DT_IN > :DT_BEGIN AND NZ.DT_IN <= :DT_FINISH
               AND EXISTS (
                   SELECT 1 FROM OBORS OJ
                   JOIN NNARAD NN ON OJ.ID_NAR = NN.ID
                   WHERE NN.ID_ZAV = NZ.ID
                     AND NN.DT_OUT > NN.DT_IN + 0.0208
               )

-- LEFT JOIN к статистике выездов
LEFT JOIN (
    SELECT 
        FN.ID AS ID_ZAV,
        (SELECT COUNT(DISTINCT OJ.ID_NAR)
         FROM OBORS OJ
         JOIN NNARAD NN ON OJ.ID_NAR = NN.ID
         WHERE OJ.ID_ZAV = FN.ID 
           AND NN.DT_OUT > NN.DT_IN + 0.0208) AS COL_V,
        replace(replace(replace(REPLACE(
        (SELECT 
          LIST(
            CAST(
                 (SELECT COUNT(*)
                 
                    FROM NARAD NN2
                    WHERE NN2.ID_ZAV = FN.ID
                    AND NN2.DT_OUT > NN2.DT_IN + 0.0208
                    AND EXISTS (SELECT 1 FROM OBORS OJ2 WHERE OJ2.ID_NAR = NN2.ID)
                    AND NN2.ID < NN.ID
                    ) + 1  AS integer
                 ) ||
                  ') выезд : ' ||
                  TRIM(NN.DOP_INF)
                  ,' '
              )
              

         
         FROM NNARAD NN
         WHERE NN.ID_ZAV = FN.ID
           AND NN.DT_OUT > NN.DT_IN + 0.0208
           AND EXISTS (SELECT 1 FROM OBORS OJ WHERE OJ.ID_NAR = NN.ID)
         
        )
        , ASCII_CHAR(10), ' '), ASCII_CHAR(13), ' '), ASCII_CHAR(9),' '),';',' ')
      
         AS DOP_INF_STR
      FROM NZAVJAV FN
    WHERE FN.DELZ = 0 AND (FN.IS_OTL IS NULL OR FN.IS_OTL <> 1)
      AND FN.ID_ATTACH IN (:PRINAD1, :PRINAD2)
      AND FN.DT_IN > :DT_BEGIN AND FN.DT_IN <= :DT_FINISH
      AND EXISTS (
          SELECT 1 FROM OBORS OJ
          JOIN NNARAD NN ON OJ.ID_NAR = NN.ID
          WHERE OJ.ID_ZAV = FN.ID
            AND NN.DT_OUT > NN.DT_IN + 0.0208
      )
) NZ_S ON NZ_S.ID_ZAV = NZ.ID

JOIN S_REVS SR ON SR.ID = NZ.ID_REVS
JOIN S_OWNER SO ON SO.ID = NZ.ID_ALIEN
LEFT JOIN S_SOD SS ON SS.ID = NZ.ID_SOD

UNION ALL

SELECT 
    Z.NOMER, 
    Z.DT_IN, 
    SR.NAME_R,
    (select trim(ADRES) from GET_ADRES(Z.ID_UL1, Z.ID_UL2, Z.KOD_UL, '', Z.ID_DOPADRES)),
    SO.NAME_R, 
    SS.NAME_R,
    COALESCE(Z_S.COL_V, 0) AS COL_V,
    AC.COUN,
    Z_S.DOP_INF_STR AS DOP_INF
FROM (
    -- ADDRESSES_COUNT для ZAVJAV (дублируем для UNION)
    SELECT ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES, COUNT(*) AS COUN
    FROM (
        SELECT ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES
        FROM NZAVJAV FN
        WHERE FN.DELZ = 0 AND (FN.IS_OTL IS NULL OR FN.IS_OTL <> 1)
          AND FN.ID_ATTACH IN (:PRINAD1, :PRINAD2)
          AND FN.DT_IN > :DT_BEGIN AND FN.DT_IN <= :DT_FINISH
          AND EXISTS (
              SELECT 1 FROM OBORS OJ
              JOIN NNARAD NN ON OJ.ID_NAR = NN.ID
              WHERE OJ.ID_ZAV = FN.ID
                AND NN.DT_OUT > NN.DT_IN + 0.0208
          )
        
        UNION ALL
        
        SELECT ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES
        FROM ZAVJAV FZ
        WHERE FZ.DELZ = 0 AND (FZ.IS_OTL IS NULL OR FZ.IS_OTL <> 1)
          AND FZ.ID_ATTACH IN (:PRINAD1, :PRINAD2)
          AND FZ.DT_IN > :DT_BEGIN AND FZ.DT_IN <= :DT_FINISH
          AND EXISTS (
              SELECT 1 FROM OBORS OJ
              JOIN NARAD NN ON OJ.ID_NAR = NN.ID
              WHERE OJ.ID_ZAV = FZ.ID
                AND NN.DT_OUT > NN.DT_IN + 0.0208
          )
    ) ALL_APPS
    GROUP BY ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES
    HAVING COUNT(*) > :NUMBERS
) AC

JOIN ZAVJAV Z ON Z.ID_UL1 = AC.ID_UL1 
             AND Z.ID_UL2 = AC.ID_UL2 
             AND Z.KOD_UL = AC.KOD_UL 
             AND Z.ID_DOPADRES = AC.ID_DOPADRES
             AND Z.DELZ = 0 AND (Z.IS_OTL IS NULL OR Z.IS_OTL <> 1)
             AND Z.ID_ATTACH IN (:PRINAD1, :PRINAD2)
             AND Z.DT_IN > :DT_BEGIN AND Z.DT_IN <= :DT_FINISH
             AND EXISTS (
                 SELECT 1 FROM OBORS OJ
                 JOIN NARAD NN ON OJ.ID_NAR = NN.ID
                 WHERE OJ.ID_ZAV = Z.ID
                   AND NN.DT_OUT > NN.DT_IN + 0.0208
             )

LEFT JOIN (
    SELECT 
        FZ.ID AS ID_ZAV,
        (SELECT COUNT(DISTINCT OJ.ID_NAR)
         FROM OBORS OJ
         JOIN NARAD NN ON OJ.ID_NAR = NN.ID
         WHERE OJ.ID_ZAV = FZ.ID 
           AND NN.DT_OUT > NN.DT_IN + 0.0208) AS COL_V ,
        
        (SELECT LIST(
            CAST((SELECT COUNT(*) 
                  FROM NARAD NN2
                  WHERE NN2.ID_ZAV = FZ.ID
                    AND NN2.DT_OUT > NN2.DT_IN + 0.0208
                    AND EXISTS (SELECT 1 FROM OBORS OJ2 WHERE OJ2.ID_NAR = NN2.ID)
                    AND NN2.ID < NN.ID) + 1 AS integer) ||
            ') выезд : ' || 
            replace(REPLACE(REPLACE(REPLACE(TRIM(NN.DOP_INF), ASCII_CHAR(10), ' '), ASCII_CHAR(13), ' '), ASCII_CHAR(9),' '),';',' '),' '
            
         )
         FROM NARAD NN
         WHERE NN.ID_ZAV = FZ.ID
           AND NN.DT_OUT > NN.DT_IN + 0.0208
           AND EXISTS (SELECT 1 FROM OBORS OJ WHERE OJ.ID_NAR = NN.ID)
          
        ) AS DOP_INF_STR
    FROM ZAVJAV FZ
    WHERE FZ.DELZ = 0 AND (FZ.IS_OTL IS NULL OR FZ.IS_OTL <> 1)
      AND FZ.ID_ATTACH IN (:PRINAD1, :PRINAD2)
      AND FZ.DT_IN > :DT_BEGIN AND FZ.DT_IN <= :DT_FINISH
      AND EXISTS (
          SELECT 1 FROM OBORS OJ
          JOIN NARAD NN ON OJ.ID_NAR = NN.ID
          WHERE OJ.ID_ZAV = FZ.ID
            AND NN.DT_OUT > NN.DT_IN + 0.0208
      )
) Z_S ON Z_S.ID_ZAV = Z.ID

JOIN S_REVS SR ON SR.ID = Z.ID_REVS
JOIN S_OWNER SO ON SO.ID = Z.ID_ALIEN
LEFT JOIN S_SOD SS ON SS.ID = Z.ID_SOD

ORDER BY 4;
