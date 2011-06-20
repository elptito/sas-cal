\name{cut}
\alias{cut}
\title{cut}
\description{Ein Makro zur Diskretisierung von stetigen Variablen.}
\usage{
\%cut(var=, newvar=, breaks=, levels=, na=, missing=, right=1)
}
\details{
Das Makro darf nur innerhalb eines data steps benutzt
werden. Beobachtungen mit fehlenden Werten werden beruecksichtigt,
d.h. diese werden in die neue Variable unveraendert kopiert.
}
\arguments{
  \item{var}{Name einer numerischen Variable, die diskretisiert werden soll.
  }
  \item{newvar}{Name einer neuen Variable, in die die diskretisierte
    Version von var gespeichert werden soll.
  }
  \item{breaks}{Schnittpunkte als eine mit Leerzeichen
    getrennte Liste, die Intervallgrenzen angeben.
  }
  \item{levels}{Undokumentiert!
  }
  \item{na}{Werte, die bei der Diskretisierung nicht geandert werden
    duerfen. Dieses sollte _nicht_ benutzt werden und wird bald entfernt.}
  \item{missing}{Fehlende Werte in var, die nicht als solche deklariert
    sind. Diese werden bei der Diskretisierung ausgelassen. D.h., dass
    die neue Variable newvar diese Werte direkt von var 'beerbt'.
  }
  \item{right}{Wenn gleich 1 (Voreinstellung), dann enthalten die
    Intervalle ihre rechte Schranke.
  }
}
\keyword{cut}