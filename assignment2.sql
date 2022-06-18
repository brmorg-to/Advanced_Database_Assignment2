/* Assignment 4-9: Using an Explicit Cursor
Create a block to retrieve and display pledge and payment information for a specific donor. For
each pledge payment from the donor, display the pledge ID, pledge amount, number of monthly
payments, payment date, and payment amount. The list should be sorted by pledge ID and then
by payment date. For the first payment made for each pledge, display “first payment” on that
output row.*/

DECLARE
    CURSOR pledged_payment (donor_id dd_donor.iddonor%TYPE) IS
        SELECT (don.firstname || ' ' || don.lastname) donor, pld.idpledge, pld.pledgeamt, pld.paymonths, pay.paydate
            FROM dd_donor don 
            JOIN dd_pledge pld ON pld.iddonor = don.iddonor
            JOIN dd_payment pay ON pld.idpledge = pay.idpledge
        WHERE don.iddonor = donor_id
        ORDER BY pld.idpledge, pay.paydate;
        lv_don1_num dd_donor.iddonor%TYPE := 301;
        lv_don2_num dd_donor.iddonor%TYPE := 302;
        lv_curr_pledge NUMBER(4) := 0;
BEGIN
    FOR cur_pledge IN pledged_payment(lv_don1_num) LOOP
        IF lv_curr_pledge = 0 OR lv_curr_pledge != cur_pledge.idpledge THEN 
            DBMS_OUTPUT.PUT_LINE('* FIRST PAYMENT *');
        END IF;
        DBMS_OUTPUT.PUT_LINE('Donor: ' || cur_pledge.donor);
        DBMS_OUTPUT.PUT_LINE('Pledge ID: ' || cur_pledge.idpledge);
        DBMS_OUTPUT.PUT_LINE( 'Amount: ' || cur_pledge.pledgeamt || ' --- ' || ' Payment Months: ' || cur_pledge.paymonths || ' --- ' || ' Pay Date: ' || cur_pledge.paydate);
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------');
        lv_curr_pledge := cur_pledge.idpledge;
    END LOOP;
END;


/*
Assignment 4-10: Using a Different Form of Explicit Cursors
Redo Assignment 4-9, but use a different cursor form to perform the same task.
*/

DECLARE
    CURSOR pledged_payment (donor_id dd_donor.iddonor%TYPE) IS
        SELECT (don.firstname || ' ' || don.lastname) donor, pld.idpledge, pld.pledgeamt, pld.paymonths, pay.paydate
                FROM dd_donor don 
                JOIN dd_pledge pld ON pld.iddonor = don.iddonor
                JOIN dd_payment pay ON pld.idpledge = pay.idpledge
            WHERE don.iddonor = donor_id
            ORDER BY pld.idpledge, pay.paydate;
    TYPE pledges_table IS TABLE OF VARCHAR2(4);
    TYPE type_pledge IS RECORD
        (full_name dd_donor.firstname%TYPE,
        pledge_id dd_pledge.idpledge%TYPE,
        amount dd_pledge.pledgeamt%TYPE,
        months dd_pledge.paymonths%TYPE,
        pay_date dd_payment.paydate%TYPE);
        cur_pledge type_pledge;
        pledges pledges_table := pledges_table();
        lv_don1_num dd_donor.iddonor%TYPE := 303;
        lv_don2_num dd_donor.iddonor%TYPE := 308;
        lv_curr_pledge NUMBER(4) := 0;
BEGIN
    OPEN pledged_payment(lv_don1_num);
        LOOP
            FETCH pledged_payment INTO cur_pledge;
            EXIT WHEN pledged_payment%NOTFOUND;
                IF cur_pledge.pledge_id MEMBER OF pledges THEN
                DBMS_OUTPUT.PUT_LINE('* FIRST PAYMENT *');
                END IF;

                DBMS_OUTPUT.PUT_LINE('Donor: ' || cur_pledge.full_name);
                DBMS_OUTPUT.PUT_LINE('Pledge ID: ' || cur_pledge.pledge_id);
                DBMS_OUTPUT.PUT_LINE('Amount: ' || cur_pledge.amount);
                DBMS_OUTPUT.PUT_LINE('Payment Months' || cur_pledge.months);
                DBMS_OUTPUT.PUT_LINE('Pay Date: ' || cur_pledge.pay_date);
                DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------');

                pledges.EXTEND(1);
                pledges(pledges.LAST) := cur_pledge.pledge_id;
        END LOOP;
    CLOSE pledged_payment;
END;


/*
Assignment 4-11: Adding Cursor Flexibility
An administration page in the DoGood Donor application allows employees to enter multiple
combinations of donor type and pledge amount to determine data to retrieve. Create a block
with a single cursor that allows retrieving data and handling multiple combinations of donor type
and pledge amount as input. The donor name and pledge amount should be retrieved and
displayed for each pledge that matches the donor type and is greater than the pledge amount
indicated. Use a collection to provide the input data. Test the block using the following input
data. Keep in mind that these inputs should be processed with one execution of the block. The
donor type code I represents Individual, and B represents Business.
*/

DECLARE
    TYPE search_donor IS RECORD
    (
        donor_type dd_donor.typecode%TYPE,
        amount dd_pledge.pledgeamt%TYPE
    );
    TYPE table_of_donors IS TABLE OF search_donor;
    first_search search_donor;
    second_search search_donor;
    donors table_of_donors := table_of_donors();
    CURSOR donor_pledged (donors table_of_donors, curr_index NUMBER) IS
        SELECT (don.firstname || ' ' || don.lastname) donor, pld.pledgeamt
                FROM dd_donor don 
                JOIN dd_pledge pld USING(iddonor)
            WHERE don.typecode IN donors(curr_index).donor_type
                AND pld.pledgeamt > donors(curr_index).amount;
BEGIN
    first_search.donor_type := 'I';
    first_search.amount := 250;
    second_search.donor_type := 'B';
    second_search.amount := 500;
    donors.EXTEND;
    donors(1) := first_search;
    donors.EXTEND;
    donors(2) := second_search;
    FOR i IN 1 .. donors.COUNT LOOP
        FOR cur_pledge IN donor_pledged (donors, i) LOOP
            DBMS_OUTPUT.PUT_LINE('Donor: ' || cur_pledge.donor);
            DBMS_OUTPUT.PUT_LINE('Pledge Amount: ' || cur_pledge.pledgeamt);
            DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------');
        END LOOP;
    END LOOP;
END;


/*
Assignment 4-12: Using a Cursor Variable
Create a block with a single cursor that can perform a different query of pledge payment data
based on user input. Input provided to the block includes a donor ID and an indicator value of
D or S. The D represents details and indicates that each payment on all pledges the donor has
made should be displayed. The S indicates displaying summary data of the pledge payment
total for each pledge the donor has made.
*/

DECLARE
    cv_pledge SYS_REFCURSOR;
   TYPE payment_detailed IS RECORD
        (
        donor_id dd_donor.iddonor%TYPE,
        pledge_id dd_pledge.idpledge%TYPE,
        payment dd_payment.payamt%TYPE
        );
   TYPE payment_summary IS RECORD
        (
        donor_id dd_donor.iddonor%TYPE,
        total_payment dd_payment.payamt%TYPE
        );
    details payment_detailed;
    summary payment_summary;
    donor_id dd_donor.iddonor%TYPE;
    indicator_value CHAR(1);
BEGIN
    donor_id := 302;
    indicator_value := 'S';
    IF indicator_value = 'D' THEN
        OPEN cv_pledge FOR SELECT
                    iddonor, idpledge, payamt
                    FROM dd_donor 
                    JOIN dd_pledge USING(iddonor)
                    JOIN dd_payment USING(idpledge)
                WHERE iddonor = donor_id;
        LOOP
            FETCH cv_pledge INTO details;
            EXIT WHEN cv_pledge%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Donor ID: ' || details.donor_id);
            DBMS_OUTPUT.PUT_LINE('Pledge ID: ' || details.pledge_id);
            DBMS_OUTPUT.PUT_LINE('Payment: ' || details.payment);
            DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------');
        END LOOP;
    ELSIF indicator_value = 'S' THEN
        OPEN cv_pledge FOR SELECT 
                    iddonor, SUM(payamt)
                    FROM dd_donor 
                    JOIN dd_pledge USING(iddonor)
                    JOIN dd_payment USING(idpledge)
                GROUP BY iddonor
                HAVING iddonor = donor_id;
        LOOP
            FETCH cv_pledge INTO summary;
            EXIT WHEN cv_pledge%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Donor ID: ' || summary.donor_id);
            DBMS_OUTPUT.PUT_LINE('Total Payment: ' || summary.total_payment);
        END LOOP;
    END IF;
END;


/*
Assignment 4-13: Exception Handling
The DoGood Donor application contains a page that allows administrators to change the ID
assigned to a donor in the DD_DONOR table. Create a PL/SQL block to handle this task.
Include exception-handling code to address an error raised by attempting to enter a duplicate
donor ID. If this error occurs, display the message “This ID is already assigned.” Test the code
by changing donor ID 305. (Don’t include a COMMIT statement; roll back any DML actions used.)
*/

DECLARE
    ex_duplicate_id EXCEPTION;
    PRAGMA exception_init(ex_duplicate_id, -20001);
    
    TYPE type_id IS RECORD (donor_id dd_donor.iddonor%TYPE);
    TYPE t_id_type IS TABLE OF type_id;
    id type_id;
    t_id t_id_type := t_id_type();
    lv_donor_id dd_donor.iddonor%TYPE := 305;
    lv_new_id dd_donor.iddonor%TYPE := 301;
    lv_exist NUMBER;
BEGIN
    UPDATE dd_donor 
        SET iddonor = lv_new_id
        WHERE iddonor = lv_donor_id;
    
    SELECT COUNT(*)
        INTO lv_exist
        FROM dd_donor
    WHERE iddonor = lv_new_id;

    IF lv_exist = 1 THEN
        RAISE ex_duplicate_id;
    END IF;

    EXCEPTION
        WHEN ex_duplicate_id THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('* This ID is already assigned. *');
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('* This ID is already assigned. Please choose a different ID. *');
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('* Please verify the imput information. A problem has occurred. *');
END;
