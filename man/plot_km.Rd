\name{plot_km}

\alias{plot_km}

\title{Visualization of Survival Distributions}

\description{
  Function for plotting the cross-validated survival distributions of a \code{sbh} object. It plots the 
  cross-validated Kaplan-Meir estimates of survival distributions between the highest risk (inbox) versus
  lower-risk (outbox) groups of observations (PRSP), or between the two specified fixed groups (PRGSP), 
  if this option is used. The plot is done for a given peeling step (or number of steps) of the peeling sequence
  (inner loop of our PRSP or PRGSP) algorithm) of the \code{sbh} object, as specified by the user.
}

\usage{
  plot_km(object,
          main = NULL,
          xlab = "Time",
          ylab = "Probability",
          ci = TRUE,
          precision = 1e-3,
          mark = 3,
          col = ifelse(test = object$cvarg$peelcriterion != "grp", 
                       yes = c(1,2), 
                       no = c(3,4)), 
          lty = 1,
          lwd = 0.5,
          cex = 0.5,
          steps = 1:object$cvfit$cv.nsteps,
          add.caption = TRUE,
          text.caption = ifelse(test = object$cvarg$peelcriterion != "grp", 
                                yes = c("outbox","inbox"), 
                                no = levels(object$groups)), 
          nr = 3, 
          nc = 4,
          device = NULL, 
          file = "Survival Plots", 
          path = getwd(), 
          horizontal = TRUE, 
          width = 11,
          height = 8.5, ...)
}

\arguments{
  \item{object}{
    Object of class \code{sbh} as generated by the main function \code{\link[PRIMsrc]{sbh}}.
  }
  \item{main}{
    \code{Character} \code{vector}. Main Title. 
    Defaults to \code{NULL}.
  }
  \item{xlab}{
    \code{Character} \code{vector}. X-axis label. 
    Defaults to "Time".
  }
  \item{ylab}{
    \code{Character} \code{vector}. Y-axis label. 
    Defaults to "Probability".
  }
  \item{ci}{
    \code{Logical} scalar. Shall the 95\% confidence interval be plotted? 
    Defaults to \code{TRUE}.
  }
  \item{precision}{
    Precision of log-rank \eqn{p}-values of separation between two survival curves.
    Defaults to 1e-3.
  }
  \item{mark}{
    \code{Integer} scalar of mark parameter, which will be used to label the inbox and outbox curves. 
    Defaults to 3.
  }
  \item{col}{
    \code{Integer} scalar specifying the color of the inbox and outbox curves 
    (Defaults to \code{c(1,2)}), or of the two groups (Defaults to \code{c(3,4)}), 
    depending on \code{object$cvarg$peelcriterion}.
  }
  \item{lty}{
    \code{Integer} scalar. Line type for the survival curve. 
    Defaults to 1.
  }
  \item{lwd}{
    \code{Numeric} scalar. Line width for the survival curve. 
    Defaults to 0.5.
  }
  \item{cex}{
    \code{Numeric} scalar specifying the size of the marks, 
    symbol expansion used for titles, captions, and axis labels. 
    Defaults to 0.5.
  }
  \item{steps}{
    \code{Integer} \code{vector}. Vector of peeling steps at which to plot the survival curves. 
    Defaults to all the peeling steps of \code{sbh} object \code{object}.
  }
  \item{add.caption}{
    \code{Logical} scalar. Shall the caption be plotted? 
    Defaults to \code{TRUE}.
  }
  \item{text.caption}{
    \code{Character} \code{vector} of caption content. 
    Defaults to \{"outbox","inbox"\}, or \code{levels(object$groups)}, 
    depending on \code{object$cvarg$peelcriterion}.
  }
  \item{nr}{
    \code{Integer} scalar of the number of rows in the plot. 
    Defaults to 3.
  }
  \item{nc}{
    \code{Integer} scalar of the number of columns in the plot. 
    Defaults to 4.
  }
  \item{device}{
    Graphic display device in \{\code{NULL}, "PS", "PDF"\}. 
    Defaults to \code{NULL} (standard output screen).
    Currently implemented graphic display devices are "PS" (Postscript) or "PDF" (Portable Document Format).
  }
  \item{file}{
    File name for output graphic. 
    Defaults to "Survival Plots".
  }
  \item{path}{
    Absolute path (without final (back)slash separator). 
    Defaults to the working directory path.
  }
  \item{horizontal}{
    \code{Logical} scalar. Orientation of the printed image. 
    Defaults to \code{TRUE}, that is potrait orientation.
  }
  \item{width}{
    \code{Numeric} scalar. Width of the graphics region in inches. 
    Defaults to 11.
  }
  \item{height}{
    \code{Numeric} scalar. Height of the graphics region in inches. 
    Defaults to 8.5.
  }
  \item{\dots}{
    Generic arguments passed to other plotting functions, including \code{plot.survfit} (R package \pkg{survival}).
  }
}

\details{
  Some of the plotting parameters are further defined in the function \code{plot.survfit} (R package \pkg{survival}).
  Step #0 always corresponds to the situation where the starting box covers the entire test-set data before peeling.
  Cross-validated LRT, LHR of inbox samples and log-rank \eqn{p}-values of separation are shown at the bottom of the plot
  with the corresponding peeling step. \eqn{P}-values are lower-bounded by the precision limit given by \eqn{1/A}, 
  where \eqn{A} is the number of permutations.
}

\value{
  Invisible. None. Displays the plot(s) on the specified \code{device}.
}

\author{
    \itemize{
        \item "Jean-Eudes Dazard, Ph.D." \email{jean-eudes.dazard@case.edu}
        \item "Michael Choe, M.D." \email{mjc206@case.edu}
        \item "Michael LeBlanc, Ph.D." \email{mleblanc@fhcrc.org}
        \item "Alberto Santana, MBA." \email{ahs4@case.edu}
        \item "J. Sunil Rao, Ph.D." \email{Rao@biostat.med.miami.edu}
    }
    Maintainer: "Jean-Eudes Dazard, Ph.D." \email{jean-eudes.dazard@case.edu}
}

\references{
    \itemize{
        \item Dazard J-E. and Rao J.S. (2018).
              "\emph{Variable Selection Strategies for High-Dimensional Survival Bump Hunting using Recursive Peeling Methods.}"
              (in prep).
        \item Rao J.S., Huilin Y. and Dazard J-E. (2018).
              "\emph{Disparity Subtyping: Bringing Precision Medicine Closer to Disparity Science.}"
              (in prep).
        \item Diaz-Pachon D.A., Saenz J.P., Dazard J-E. and Rao J.S. (2018).
              "\emph{Mode Hunting through Active Information.}"
              (in press).
        \item Diaz-Pachon D.A., Dazard J-E. and Rao J.S. (2017).
              "\emph{Unsupervised Bump Hunting Using Principal Components.}"           
              In: Ahmed SE, editor. Big and Complex Data Analysis: Methodologies and Applications. 
              Contributions to Statistics, vol. Edited Refereed Volume. 
              Springer International Publishing, Cham Switzerland, p. 325-345.
        \item Yi C. and Huang J. (2017).
              "\emph{Semismooth Newton Coordinate Descent Algorithm for Elastic-Net Penalized Huber Loss Regression and Quantile Regression}."
              J. Comp Graph. Statistics, 26(3):547-557.
        \item Dazard J-E., Choe M., LeBlanc M. and Rao J.S. (2016).
              "\emph{Cross-validation and Peeling Strategies for Survival Bump Hunting using Recursive Peeling Methods.}"
              Statistical Analysis and Data Mining, 9(1):12-42.
        \item Dazard J-E., Choe M., LeBlanc M. and Rao J.S. (2015).
              "\emph{R package PRIMsrc: Bump Hunting by Patient Rule Induction Method for Survival, Regression and Classification.}"
              In JSM Proceedings, Statistical Programmers and Analysts Section. Seattle, WA, USA.
              American Statistical Association IMS - JSM, p. 650-664.
        \item Dazard J-E., Choe M., LeBlanc M. and Rao J.S. (2014).
              "\emph{Cross-Validation of Survival Bump Hunting by Recursive Peeling Methods.}"
              In JSM Proceedings, Survival Methods for Risk Estimation/Prediction Section. Boston, MA, USA.
              American Statistical Association IMS - JSM, p. 3366-3380.
        \item Dazard J-E. and J.S. Rao (2010).
              "\emph{Local Sparse Bump Hunting.}"
              J. Comp Graph. Statistics, 19(4):900-92.
    }
}

\section{Acknowledgments}{
    This work made use of the High Performance Computing Resource in the Core Facility for Advanced Research Computing at Case Western Reserve University. 
    This project was partially funded by the National Institutes of Health NIH - National Cancer Institute (R01-CA160593) to J-E. Dazard and J.S. Rao.
}

\note{
  End-user plotting function.
}

\keyword{Exploratory Survival/Risk Analysis}
\keyword{Survival/Risk Estimation & Prediction}
\keyword{Non-Parametric Method}
\keyword{Cross-Validation}
\keyword{Bump Hunting}
\keyword{Rule-Induction Method}

\seealso{
    \itemize{
        \item \code{plot.survfit} (R package \pkg{survival})
    }
}
