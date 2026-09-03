with DEPARTURES
as (select ID, NOMER, DT_IN, ID_RAYON, ID_UL1, ID_UL2, KOD_UL, ID_PLACE, ID_DIAM, DOP_ADR, ID_REVS, ID_DOPADRES,
           0 IS_CLOSED
    from NZAVJAV NZ1
    where (DELZ = 0 and
          (IS_OTL is null or IS_OTL <> 1)) and
          ID_ATTACH in (?, ?) and
          (DT_IN > ?) and
          (DT_IN <= ?) and
          exists(select 1
                 from OBORS OJ
                 join NNARAD N3 on OJ.ID_ZAV = NZ1.ID and N3.ID = OJ.ID_NAR and (N3.DT_OUT > N3.DT_IN + 0.0208))
    union all
    select ID, NOMER, DT_IN, ID_RAYON, ID_UL1, ID_UL2, KOD_UL, ID_PLACE, ID_DIAM, DOP_ADR, ID_REVS, ID_DOPADRES,
           1 IS_CLOSED
    from ZAVJAV Z1
    where (DELZ = 0 and
          (IS_OTL is null or IS_OTL <> 1)) and
          ID_ATTACH in (?, ?) and
          (DT_IN > ?) and
          (DT_IN <= ?) and
          exists(select 1
                 from OBORS OJ
                 join NARAD N4 on OJ.ID_ZAV = Z1.ID and N4.ID = OJ.ID_NAR and (N4.DT_OUT > N4.DT_IN + 0.0208))),
ADDRESSES_COUNT
as (select ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES, count(*) as COUN
    from DEPARTURES
    group by ID_UL1, ID_UL2, KOD_UL, ID_DOPADRES
    having count(*) > ?)
select NZ.NOMER NOMER_2, NZ.DT_IN DT_IN, SR.NAME_R NAME_R,
       (select ADRES
        from GET_ADRES(NZ.ID_UL1, NZ.ID_UL2, NZ.KOD_UL, '', NZ.ID_DOPADRES)) F_1, SO.NAME_R NAME_R1, SS.NAME_R NAME_2,

       (select count(distinct OJ.ID_NAR)
        from OBORS OJ
        join NNARAD NNN on OJ.ID_ZAV = NZ.ID and NNN.ID = OJ.ID_NAR and (NNN.DT_OUT > NNN.DT_IN + 0.0208)) COL_V,
        
        ADDRESSES_COUNT.COUN,
        
         (select list(  REPLACE(REPLACE( trim(NN.DOP_INF),ASCII_CHAR(10), ' '),ASCII_CHAR(13),' '), ' @@ ') 
        from OBORS OJ
        join NNARAD NN on NN.ID = OJ.ID_NAR
        where OJ.ID_ZAV = NZ.ID and
              NN.DT_OUT > NN.DT_IN + 0.0208)   as DOP_INF
from ADDRESSES_COUNT
join NZAVJAV NZ on NZ.ID_UL1 = ADDRESSES_COUNT.ID_UL1 and NZ.ID_UL2 = ADDRESSES_COUNT.ID_UL2 and NZ.KOD_UL = ADDRESSES_COUNT.KOD_UL and NZ.ID_DOPADRES = ADDRESSES_COUNT.ID_DOPADRES and NZ.ID_ATTACH in (?, ?)
join S_REVS SR on SR.ID = NZ.ID_REVS
join S_OWNER SO on SO.ID = NZ.ID_ALIEN
left join S_SOD SS on SS.ID = NZ.ID_SOD
where NZ.DT_IN > ? and
      NZ.DT_IN <= ? and
      exists(select 1
             from OBORS OJ, NNARAD N2
             where OJ.ID_ZAV = NZ.ID and
                   N2.ID = OJ.ID_NAR and
                   (N2.DT_OUT > N2.DT_IN + 0.0208))
union all
select Z.NOMER, Z.DT_IN, SR.NAME_R,
       (select ADRES
        from GET_ADRES(Z.ID_UL1, Z.ID_UL2, Z.KOD_UL, '', Z.ID_DOPADRES)), SO.NAME_R, SS.NAME_R,

       (select count(distinct OJ.ID_NAR)
        from OBORS OJ
        join NARAD NN on OJ.ID_ZAV = Z.ID and NN.ID = OJ.ID_NAR and (NN.DT_OUT > NN.DT_IN + 0.0208)) COL_V,
        
        ADDRESSES_COUNT.COUN,
            
        (select list(REPLACE(REPLACE( trim(NN.DOP_INF),ASCII_CHAR(10), ' '),ASCII_CHAR(13),' ')     , ' ')
        from OBORS OJ
        join NARAD NN on NN.ID = OJ.ID_NAR
        where OJ.ID_ZAV = Z.ID and
              NN.DT_OUT > NN.DT_IN + 0.0208)   as DOP_INF


from ADDRESSES_COUNT
join ZAVJAV Z on Z.ID_UL1 = ADDRESSES_COUNT.ID_UL1 and Z.ID_UL2 = ADDRESSES_COUNT.ID_UL2 and Z.KOD_UL = ADDRESSES_COUNT.KOD_UL and Z.ID_DOPADRES = ADDRESSES_COUNT.ID_DOPADRES and Z.ID_ATTACH in (?, ?)
join S_REVS SR on SR.ID = Z.ID_REVS
join S_OWNER SO on SO.ID = Z.ID_ALIEN
left join S_SOD SS on SS.ID = Z.ID_SOD
where Z.DT_IN > ? and
      Z.DT_IN <= ? and
      exists(select 1
             from OBORS OJ, NARAD N2
             where OJ.ID_ZAV = Z.ID and
                   N2.ID = OJ.ID_NAR and
                   (N2.DT_OUT > N2.DT_IN + 0.0208))
order by 4   