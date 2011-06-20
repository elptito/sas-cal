\name{gregeri}
\alias{gregeri}
\title{gregeri}
\description{Zur Zeit des Schreibens dient das Makro zwei Zielen: 1)
  Automatisierung der Erstellung von CLAN97 \%auxvar() Input
  Datensaetzen. 2) Erzeugung von GREG Kalibrationsgewichten.}
\usage{
\%gregeri(formula=, design=, sample=, weight_var=,
          cal_weight_name=cal_weight, sframe=, aux_out_file=,
          pop_margins=, backend=CLAN, model_name=M, out_lib=work,
          debug=)
}
\details{
Das Makro erstellt Datensaetze, die als Input fuer CLAN97-Makro
\%auxvar() dienen. Zur Zeit unterstuetzt das Makro lediglich die
Erstellung dieser Hilfsdatensaetze aufgrund einer symbolischen
Beschreibung der Hilfsinformation, die in der Auswahlgrundlage fuer die
Stichprobe ausgewertet wird. Siehe die Argumente formula und sframe.

Ferner kann man \%gregeri benutzen, um Kalibration ohne Einsatz von
CLAN durchzufuehren. Dazu muessen die Argumente sample, weight_var und
cal_weight_name spezifiziert werden.
}
\arguments{
  \item{formula}{Beschreibt die Struktur des Hilfsdatensatzes in
symbolischer Form. Stetige Variablen muessen mit c(stetvar)
gekennzeichnet werden. Ausdruecke der Form catvar*c(stetvar) bedeuten,
dass die Totals von stetvar fuer jedes Nivea von catvar gebildet
werden. c(stetvar) allein bedeutet, dass das Total von stetvar fuer die
ganze Population gebildet wird. Die Formel muss mit ~ anfangen, die
Terme muessen mit + getrennt werden. Ausdruecke der Form catvar1 +
catvar2 bedeuten, dass die (Rand)Haeufigkeiten fuer die Niveaus von
catvar1 und catvar2 ausgerechnet werden. Falls das Kalibrationsmodell
keinen Achsenabschnitt enthalten soll, kann das mit Hinzufuegen von '0'
in der Formel unterdrueckt werden. Per Voreinstellung wird
einen Achsenabschnitt aufgenommen.
  }
  \item{sframe}{Name des SAS Datensatzes, das die Sampling Frame fuer
    die Stichprobe enthaelt. Das Modell aus formula wird in diesem
    Datensatz ausgewertet. Die Variablen, die unter formula
    angegeben sind muessen in diesem Datensatz existieren. Falls einen
    Achsenabschnitt im Modell aufgenommen wird, muss auch eine Variable
    namens _Intercept_ mit dem Wert 1 fuer jede Beobachtung im Datensatz
    vorhanden sein.
  }
  \item{aux_out_file}{Name des Hilfsdatensatzes, der als Input fuer
    \%auxvar() dient.
  }
  \item{design}{Undokumentiert!
  }
  \item{sample}{Name des SAS Datensatzes, der die Stichprobe mit den zu
    kalibrierenden Gewichten enthaelt. Die Variablen, die unter formula
    angegeben sind muessen in diesem Datensatz existieren. Falls einen
    Achsenabschnitt im Modell aufgenommen wird, muss auch eine Variable
    namens _Intercept_ mit dem Wert 1 fuer jede Beobachtung im Datensatz
    vorhanden sein.}
  \item{pop_margins}{Undokumentiert!
  }
  \item{backend}{Wenn CLAN eingegeben wird (die Voreinstellung),
    erzeugt das Makro einen Inputdatensatz mit namen aux_out_file nach
    dem unter formula angegebenen Modell. Fuer jeden anderen Wert wird
    eine Kalibrierung der unter weight_var angegebene Variable
    durchgefuehrt. Die kalibrierten Gewichte werden in die Variable
    cal_eight_name in dem Datensatz sample gespeichert.
  }
  \item{model_name}{Undokumentiert!
  }
  \item{out_lib}{Undokumentiert!
  }
  \item{debug}{Undokumentiert!
  }
}
\keyword{GREG}