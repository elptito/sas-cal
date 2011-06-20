\name{interaction}
\alias{interaction}
\title{Interaction}
\description{Automatisiert die Zusammenfassung kategorieller Variablen
  in SAS.}
\usage{
\%interaction(var_lst=, newvar=, dat=, newdat=, fmtname=, fmtlib=work, type = clan)
}
\details{
  CLAN97 erwartet, dass die Kategorien der diskreten Variablen mit
  Zahlen von 1 bis  n kodiert sind, wobei n die Anzahl der
  Auspraegungen der Variable ist. \%interaction versucht das
  Zusammenfassen von kategoriellen  Variablen zu automatisieren. Dabei
  wird die CLAN97 Anforderung an die Kodierung beruecksichtigt.

  Das Makro darf nur _ausserhalb_ von data steps und Prozeduren benutzt
  werden.
}
\arguments{
  \item{var_lst}{Liste der Variablen, die zusammengefasst werden sollen,
    getrennt mit Leerzeichen.
  }
  \item{newvar}{Name der neuen Variable. Muss ein gueltiger SAS
    Variablenname sein. WARNING: bestehende Variablen werden
    stillschweigend ueberschrieben!
  }
  \item{dat}{Name des SAS Datensatzes (zusammen mit Bibliotheksnamen),
    der die Variablen aus var_lst enthaelt.
  }
  \item{newdat}{Name eines SAS Datensatzes, in dem das Ergebnis
    ausgegeben wird. Falls leer, interaction ueberschreibt den Datensatz
    dat. WARNING: falls der Datensatz bereits existiert, wird er
    stillschweigend ueberschrieben!
  }
  \item{fmtname}{Name eines SAS Formats, in dem das Format fuer die neue
    Variable gespeichert werden soll. Falls leer, wird kein Format
    erstellt. Probleme mit zu langen Formatnamen sind hier nicht
    ausgeschlossen! Bestehende Formate werden mit Warnung von proc
    format ueberschrieben.
  }
  \item{fmtlib}{SAS Catalog, in dem fmtname gespeichert werden
    soll. Falls leer wird fmtname in work.formats ausgeschrieben.
  }
}
\keyword{categorical}
