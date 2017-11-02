-- BIREYSEL_SEGMENT_AYLIK --
/*
	BIM2457 (c) 2017 
*/
DECLARE 
    HEDEF_TUTAR NUMBER;
    v_ILK NUMBER;
    v_SON1 NUMBER;
    v_SON2 NUMBER;
    SONX NUMBER := 0;
    SON_MAX NUMBER;

    FUNCTION FUNC_FARK( ILK_ IN NUMBER, SON_ IN NUMBER )
      RETURN NUMBER
    IS
    FARK_ NUMBER;
    BEGIN
    WITH 
        azalan AS (SELECT man_id, egn, name, bes_ltv, hayat_ltv, katilimci_ltv FROM bireysel_segment_aylik  ORDER BY katilimci_ltv DESC   )
        , rnazalan as ( SELECT rownum as rn, man_id, egn, name, bes_ltv, hayat_ltv, katilimci_ltv FROM azalan  )
        , bas as ( select ILK_ as satir from dual ) -- 1. satirdan         <<-- 
        , son as ( select SON_ as satir from dual ) -- 46956. satira   <<--
        , kismi_toplam AS
        ( 
          SELECT SUM(katilimci_ltv) AS ktoplam   FROM rnazalan r 
          WHERE r.rn BETWEEN
            (select satir from bas) AND (select satir from son) -- bas.satir ile son.satir arasini toplar
        ),
        hedef AS (    SELECT HEDEF_TUTAR AS htoplam FROM DUAL )
        SELECT ( ht.htoplam - kt.ktoplam )     INTO FARK_
        FROM kismi_toplam kt, hedef ht, bas, son;
    RETURN FARK_;
    END;
    
    FUNCTION FUNC_SONBUL( SGMNT IN VARCHAR2, ILK__ IN NUMBER, SON1_  IN NUMBER, SON2_  IN NUMBER)
        RETURN NUMBER 
    IS
        HEDEF_TUTAR NUMBER;
        FARK1 NUMBER := 0;
        FARK2 NUMBER := 0;
        ILK NUMBER := ILK__;
        SON1 NUMBER := SON1_;
        SON2 NUMBER := SON2_;
        SONX NUMBER := 0;
        SON_MAX NUMBER;
        FARK NUMBER;
        DENEME NUMBER := 0;
        DENEME_MAX NUMBER := 0;
        CARPIM NUMBER;
    BEGIN
        --
        FARK1  := FUNC_FARK(ILK, SON1);
        FARK2  := FUNC_FARK(ILK, SON2);
        --
        ----
        CARPIM := SIGN(FARK1)*SIGN(FARK2);
        IF CARPIM>0 THEN
            DBMS_OUTPUT.put_line (SGMNT || ' BU ARALIKTA YER ALMIYOR - SON1: ' ||SON1 || ', SON2: ' ||SON2);
        ELSIF CARPIM = 0 THEN
            IF FARK1 = 0 THEN
                DBMS_OUTPUT.put_line (SGMNT || ' FARK = 0  -->  ILK: ' || ILK || ', SON: ' ||SON1);
                RETURN SON1;
            ELSIF FARK2 = 0 THEN
                DBMS_OUTPUT.put_line (SGMNT || ' FARK = 0  -->  ILK: ' || ILK || ', SON: ' ||SON2);
                RETURN SON2;
            END IF;
        END IF;
        ----
		
        IF CARPIM < 0 THEN -- FARK1 POZITIF, FARK2 NEGATIF OLMALI.
		
        ---
        DENEME_MAX := ABS( SON2 - SON1 );
        ---
        IF SON2 - SON1 = 1 THEN
                IF FARK2 <= 0 AND FARK1>=0 THEN
                    DBMS_OUTPUT.put_line (SGMNT || ' - ILK: ' || ILK || ', SON: ' ||SON2);
                    RETURN SON2;
                ELSE 
                    DBMS_OUTPUT.put_line (SGMNT || ' HATA34');
                    RETURN -1;
                END IF;
        END IF;    

        -- FARK ->> FARK1 VEYA FARK2
        WHILE SON2 - SON1 > 1 LOOP
            
            DENEME := DENEME + 1;
            -----
            SONX := FLOOR( (SON1+SON2)/2 );
            FARK := FUNC_FARK(ILK, SONX);
            IF FARK = 0 THEN
                DBMS_OUTPUT.put_line (SGMNT || ' FARK = 0  -->  ILK: ' || ILK || ', SON: ' ||SONX);
                RETURN SONX;
            END IF;
            -----

            IF FARK >= 0 THEN
                SON1 := SONX;
                FARK1 := FARK;    
            ELSE
                SON2 := SONX;
                FARK2 := FARK;  
            END IF;
                
            IF SON2 - SON1 = 1 THEN
                IF FARK2 <= 0 AND FARK1>=0 THEN
                    DBMS_OUTPUT.put_line (SGMNT || ' - ILK: ' || ILK || ', SON: ' ||SON2);
                    RETURN SON2;
                ELSE 
                    DBMS_OUTPUT.put_line (SGMNT || ' HATA35');
                END IF;
            END IF;

            IF DENEME >= DENEME_MAX  THEN
                DBMS_OUTPUT.put_line (SGMNT || 'BU ARALIKTA YER ALMIYOR - SON1: ' ||SON1 || ', SON2: ' ||SON2);
            END IF;
            EXIT WHEN DENEME >= DENEME_MAX;
        END LOOP; -- end of WHILE SON2 - SON1 > 1 LOOP
        END IF; -- end of IF CARPIM < 0
    RETURN -1;
    END;


BEGIN
DBMS_OUTPUT.PUT_LINE('.');
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
-----
-- toplam ltv tutarinin 5te birini HEDEF_TUTAR alanina yaziyoruz
SELECT SUM(KATILIMCI_LTV)/5 INTO HEDEF_TUTAR FROM bireysel_segment_aylik;
SELECT COUNT(*) INTO SON_MAX FROM bireysel_segment_aylik;

DBMS_OUTPUT.PUT_LINE('-');
DBMS_OUTPUT.PUT_LINE('BIREYSEL_SEGMENT_AYLIK TABLOSUNDA');
DBMS_OUTPUT.PUT_LINE(SON_MAX || ' ADET KAYIT VAR.');
DBMS_OUTPUT.PUT_LINE('HEDEF TUTAR: '|| HEDEF_TUTAR);
DBMS_OUTPUT.PUT_LINE('-');

v_ILK := 1;  v_SON1 := V_ILK+1;  v_SON2 := SON_MAX;
SONX := FUNC_SONBUL('ELIT       ', v_ILK, v_SON1, v_SON2);
v_ILK := SONX + 1;  v_SON1 := V_ILK+1;  v_SON2 := SON_MAX;
SONX := FUNC_SONBUL('OZEL       ', v_ILK, v_SON1, v_SON2);
v_ILK := SONX + 1;  v_SON1 := V_ILK+1;  v_SON2 := SON_MAX;
SONX := FUNC_SONBUL('STANDART   ', v_ILK, v_SON1, v_SON2);
v_ILK := SONX + 1;  v_SON1 := V_ILK+1;  v_SON2 := SON_MAX;
SONX := FUNC_SONBUL('KITLESEL(A)', v_ILK, v_SON1, v_SON2);
v_ILK := SONX + 1;
DBMS_OUTPUT.put_line ('KITLESEL(B) - ILK: ' || v_ILK || ', SON: ' ||SON_MAX);

DBMS_OUTPUT.PUT_LINE('-');
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
DBMS_OUTPUT.PUT_LINE(':');
END;