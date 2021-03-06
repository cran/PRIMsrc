\name{PRIMsrc-package}

\alias{PRIMsrc}

\docType{package}

\title{Bump Hunting by Patient Rule Induction Method in Survival, Regression, and Classification settings}

\description{
    "Bump Hunting" (BH) refers to the procedure of mapping out a local region of the multi-dimensional input space where a target function of interest, 
    usually unknown, assumes smaller or larger values than its average over the entire space. In general, the region \eqn{R} could be any smooth shape 
    (e.g. a convex hull) possibly disjoint.
    
    \pkg{PRIMsrc} implements a unified treatment of "Bump Hunting" (BH) by Patient Rule Induction Method (PRIM) with 
    Survival, Regression and Classification outcomes (SRC). To estimate the region, PRIM generates decision rules delineating hyperdimensional boxes 
    (hyperrectangles) of the input space, not necessarily contiguous, where the outcome is smaller or larger than its average over the entire space.
    
    Assumptions are that the multivariate input variables can be discrete or continuous, and the univariate outcome variable can be discrete 
    (Classification), continuous (Regression), or a time-to-event, possibly censored (Survival). It is intended to handle low and high-dimensional 
    multivariate datasets, including the paradigm where the number of covariates \eqn{p} exceeds or dominates that of samples 
    (\eqn{p > n} or \eqn{p \gg n}).

    Please note that the current version is a development release that only implements the case of a survival outcome. At this point, this version of 
    `PRIMsrc` is also restricted to a directed peeling search of the first box covered by the recursive coverage (outer) loop of our Patient Recursive 
    Survival Peeling (PRSP) algorithm (Dazard et al., 2014, 2015, 2016, 2018). New features will be added as soon as available.
}

\details{
    In a direct application, "Bump Hunting" (BH) can identify subgroups of observations for which their outcome 
    is as extreme as possible. Similarly to this traditional goal of subgroup finding, \pkg{PRIMsrc} also implements the alternative goal of mapping 
    out a region (possibly disjointed) of the input space where the outcome \emph{difference} between existing (fixed) groups of observations is as 
    extreme as possible. We refer to the later goal as "Group Bump Hunting" (GBH).
    
    In the case of a time-to event, possibly censored (Survival) outcome, "Survival Bump Hunting" (SBH) is done by our Patient Recursive 
    Survival Peeling (PRSP) algorithm (see Dazard et al. (2014, 2015, 2016, 2018) for details). Alternatively, "Group Survival Bump Hunting" (GSBH)
    is done by using specifc peeling and cross-validation criterion in a derivation of PRSP, which we call Patient Recursive Group Survival Peeling 
    (PRGSP) (see Rao et al. (2018) for details and an application in Survival Disparity Subtyping). 
    
    The package relies on an optional variable screening (pre-selection) procedure that is run before the PRSP algorithm 
    and final variable usage (selection) procedure is done. This is done by four possible cross-validated variable screening 
    (pre-selection) procedures offered to the user from the main end-user survival Bump Hunting function \code{\link{sbh}} 
    (see below and Dazard et al. (2018) for details). 
    
    The following describes the end-user functions that are needed to run a complete procedure. The other internal subroutines 
    are not documented in the manual and are not to be called by the end-user at any time. For computational efficiency, 
    some end-user functions offer a parallelization option that is done by passing a few parameters needed to configure a cluster. 
    This is indicated by an asterisk (* = optionally involving cluster usage). The R features are categorized as follows:

    \enumerate{

      \item{END-USER FUNCTION FOR PACKAGE NEWS} \cr
      \code{\link{PRIMsrc.news}}
      \bold{Display the \pkg{PRIMsrc} Package News}\cr
            Function to display the log file \code{NEWS} of updates of the \pkg{PRIMsrc} package.\cr
            
      \item{END-USER S3-METHOD FUNCTIONS FOR SUMMARY, DISPLAY, PLOT AND PREDICTION} \cr
      \code{\link{summary}}
      \bold{Summary Function}\cr
            S3-method summary function to summarize the main parameters used to generate the \code{sbh} object.\cr
            
      \code{\link{print}}
      \bold{Print Function}\cr
            S3-method print function to display the cross-validated estimated values of the \code{sbh} object.\cr

      \code{\link{plot}}
      \bold{2D Visualization of Data Scatter and Encapsulating Box} \cr           
            S3-method plot function for two-dimensional visualization of scatter of data points 
            and cross-validated encapsulating box of a \code{sbh} object for the highest risk (inbox) versus
            lower-risk (outbox) groups (PRSP), and between the two specified fixed groups (PRGSP), 
            if this option is used. The scatter plot is done for a given peeling step (or number of steps) 
            of the peeling sequence (inner loop of our PRSP or PRGSP) and in a given plane of the used covariates 
            of the \code{sbh} object, both specified by the user.\cr

      \code{\link{predict}}
      \bold{Predict Function}\cr
            S3-method predict function to predict the box membership and box vertices 
            on an independent set.\cr
  
      \item{END-USER SURVIVAL BUMP HUNTING FUNCTION} \cr
      \code{\link{sbh}} *
      \bold{Cross-Validated Survival Bump Hunting} \cr
            Main end-user function for fitting a Survival Bump Hunting (SBH) model. It returns an object of class \code{sbh}, 
            as generated by our Patient Recursive Survival Peeling (PRSP) algorithm (or Patient Recursive Group Survival Peeling (PRGSP)), 
            containing cross-validated estimates of the target region of the input space with end-points statistics
            of interest. The main function relies on an optional internal variable screening (pre-selection) procedure that is run before 
            the actual variable usage (selection) is done at the time of fitting the Survival Bump Hunting (SBH) or Group Survival 
            Bump Hunting (GSBH) model model using our PRSP or PRGSP algorithm. At this point, the user can choose between four 
            possible variable screening (pre-selection) procedures:
            \enumerate{
                \item{Univariate Patient Recursive Survival Peeling algorithm (default of package 
                    \href{https://CRAN.R-project.org/package=PRIMsrc}{PRIMsrc})}
                \item{Penalized Censored Quantile Regression (by Semismooth Newton Coordinate Descent algorithm adapted from package 
                    \href{https://CRAN.R-project.org/package=hqreg}{hqreg})}
                \item{Penalized Partial Likelihood (adapted from package
                    \href{https://CRAN.R-project.org/package=glmnet}{glmnet})}
                \item{Supervised Principal Component Analysis (adapted from package
                    \href{https://CRAN.R-project.org/package=superpc}{superpc})} 
            }
            In this version, the Cross-Validation (CV) that controls model size (#covariates) and model complexity (#peeling steps), 
            respectively, to fit the Survival Bump Hunting model, are carried out internally by two consecutive tasks within the single 
            main function \code{sbh()}. The returned S3-class \code{sbh} object contains cross-validated estimates of all the decision-rules 
            of used covariates and all other statistical quantities of interest at each iteration of the peeling sequence (inner loop of the 
            PRSP algorithm). This enables the graphical display of results of profiling curves for model selection/tuning, peeling trajectories, 
            covariate traces and survival distributions (see plotting functions for more details). The function offers a number of options 
            for the number of replications of the fitting procedure to be perfomed: \eqn{B}; the type of \eqn{K}-fold cross-validation desired: 
            (replicated)-averaged or-combined; as well as the peeling and cross-validation critera for model selection/tuning,
            and a few more parameters for the PRSP algorithm. The function takes advantage of the R packages \pkg{parallel} and \pkg{snow}, 
            which allows users to create a parallel backend within an R session, enabling access to a cluster of compute cores 
            and/or nodes on a local and/or remote machine(s) with either. \pkg{PRIMsrc} supports two types of communication mechanisms 
            between master and worker processes: 'Socket' or  'Message-Passing Interface' ('MPI').\cr

      \item{END-USER PLOTTING FUNCTIONS FOR MODEL VALIDATION AND VISUALIZATION OF RESULTS} \cr
      \code{\link{plot_profile}}
      \bold{Visualization for Model Selection/Validation} \cr
            Function for plotting the cross-validated model selection/tuning profiles of a \code{sbh} object. 
            It uses the user's choice of cross-validation criterion statistics among the Log Hazard Ratio (LHR), 
            Log-Rank Test (LRT) or Concordance Error Rate (CER). The function plots (as it applies) both profiles 
            of cross-validation criterion as a function of variables screening size (cardinal subset of top-screened 
            variables in the PRSP variable screening procedure), and peeling length (number of peeling steps
            of the peeling sequence in the inner loop of the PRSP or PRGSP algorithm).\cr
      \code{\link{plot_traj}}
      \bold{Visualization of Peeling Trajectories/Profiles} \cr
            Function for plotting the cross-validated peeling trajectories/profiles of a \code{sbh} object.
            Applies to the user-specified covariates among the pre-selected ones and all other statistical quantities of interest
            at each iteration of the peeling sequence (inner loop of our PRSP or PRGSP algorithm). \cr
      \code{\link{plot_trace}}
      \bold{Visualization of Covariates Traces} \cr
            Function for plotting the cross-validated covariates traces of a \code{sbh} object.
            Plot the cross-validated modal trace curves of covariate importance and covariate usage of the user-specified 
            covariates among the pre-selected ones at each iteration of the peeling sequence (inner loop of our PRSP or PRGSP algorithm). \cr
      \code{\link{plot_km}}
      \bold{Visualization of Survival Distributions} \cr
            Function for plotting the cross-validated survival distributions of a \code{sbh} object. It plots the 
            cross-validated Kaplan-Meir estimates of survival distributions between the highest risk (inbox) versus
            lower-risk (outbox) groups of observations (PRSP), or between the two specified fixed groups (PRGSP), 
            if this option is used. The plot is done for a given peeling step (or number of steps) of the peeling sequence
            (inner loop of our PRSP or PRGSP) algorithm) of the \code{sbh} object, as specified by the user. \cr

      \item{END-USER DATASETS} \cr
      \code{\link{Synthetic.1}},
      \code{\link{Synthetic.1b}}, 
      \code{\link{Synthetic.2}},
      \code{\link{Synthetic.3}}, 
      \code{\link{Synthetic.4}}
      \bold{Five Datasets From Simulated Regression Survival Models} \cr
            Five datasets from simulated regression survival models #1-4 as described in Dazard et al. (2015), 
            representing low- and high-dimensional situations, and where regression parameters represent various types 
            of relationship between survival times and covariates including saturated and noisy situations. 
            In three datasets where non-informative noisy covariates were used, these covariates were not part of the design matrix 
            (models #2-3 and #4). In one dataset, the signal is limited to a box-shaped region \eqn{R} 
            of the predictor space (model #1b). In the last dataset, the signal is limited to 10\% of the predictors 
            in a \eqn{p > n} situation (model #4). See each dataset for more details.\cr
            
      \code{\link{Real.1}}
      \bold{Clinical Dataset} \cr
            Publicly available HIV clinical data from the Women's Interagency HIV cohort Study (WIHS). 
            The entire study enrolled 1164 women. Inclusion criteria of the study are: women at enrolment must be
            (i) alive, (ii) HIV-1 infected, and (iii) free of clinical AIDS symptoms. Women were followed until the 
            first of the following occurred: (i) treatment initiation (HAART), (ii) AIDS diagnosis, (iii) death, 
            or administrative censoring. The studied outcomes were the competing risks "AIDS/Death (before HAART)" 
            and "Treatment Initiation (HAART)". However, for simplification purposes, only the first of the two competing events 
            (i.e. the time to AIDS/Death), was used. Likewise, for simplification in this clinical dataset example, 
            only \eqn{n=485} complete cases were used. Variables included history of Injection Drug Use ("IDU") 
            at enrollment, African American ethnicity ('Race'), age ('Age'), and baseline CD4 count ('CD4'). 
            The question in this dataset example was whether it is possible to achieve a prognostication of patients 
            for AIDS and HAART. See dataset documentation for more details.\cr

      \code{\link{Real.2}}
      \bold{Genomic Dataset} \cr
            Publicly available lung cancer genomic data from the Chemores Cohort Study. This data is part of an integrated study 
            of mRNA, miRNA and clinical variables to characterize the molecular distinctions between squamous cell carcinoma (SCC) 
            and adenocarcinoma (AC) in Non Small Cell Lung Cancer (NSCLC) aside large cell lung carcinoma (LCC). Tissue samples 
            were analysed from a cohort of 123 patients, who underwent complete surgical resection at the Institut Mutualiste 
            Montsouris (Paris, France) between 30 January 2002 and 26 June 2006. The studied outcome was the "Disease-Free Survival Time". 
            Patients were followed until the first relapse occurred or administrative censoring. In this genomic dataset, 
            the expression levels of Agilent miRNA probes (\eqn{p=939}) were included from the \eqn{n=123} cohort samples.
            In addition to the genomic data, five clinical variables, also evaluated on the cohort samples, are included as 
            continuous variable ('Age') and nominal variables ('Type','KRAS.status','EGFR.status','P53.status'). 
            This dataset represents a situation where the number of covariates dominates the number of complete observations, 
            or \eqn{p >> n} case. See dataset documentation for more details.\cr
    }
    Known Bugs/Problems : None at this time.
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

\keyword{Exploratory Survival/Risk Analysis}
\keyword{Survival/Risk Estimation & Prediction}
\keyword{Non-Parametric Method}
\keyword{Cross-Validation}
\keyword{Bump Hunting}
\keyword{Rule-Induction Method}

\seealso{
    \itemize{
        \item R package \pkg{parallel}
        \item R package \pkg{glmnet}
        \item R package \pkg{hqreg}
        \item R package \pkg{superpc}
    }
}
