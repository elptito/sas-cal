/* Read raw data: WARNING: which init.sas is included? */

*%include "init.sas";

/* Prep Europaeische Erhebung zur Berufliche Weiterbildung 2006*/
%include "&FDZdataDir\fdz_cvts_cf_2006_setup.sas";

/* Prep Pruefungsstatistik... 2000 */
%include "&FDZdataDir\pruefung_cf_2000.sas";

/* Verdienststrukturerhebung 2006*/
%include "&FDZdataDir\fdz_vse_cf_2006_setup.sas";

/* Lohn- und Einkommenssteuerstatistik */

%include "&FDZdataDir\fdz_lest_cf_2001_sas.sas";

/* Versichertenstatistik */

%include "&FDZdataDir\fdz_gkv_cf_2002_setup_sas_jahr.sas";
%include "&FDZdataDir\fdz_gkv_cf_2002_setup_sas_amb.sas";
