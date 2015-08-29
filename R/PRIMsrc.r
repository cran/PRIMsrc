##########################################################################################################################################
# PRIMsrc
##########################################################################################################################################

##########################################################################################################################################
# 1. END-USER SURVIVAL BUMP HUNTING FUNCTION
##########################################################################################################################################

##########################################################################################################################################
################
# Usage         :
################
#                   sbh(dataset,
#                       B=10, K=5, A=1000,
#                       vs=TRUE, cpv=FALSE,
#                       cvtype=c("combined", "averaged", "none"),
#                       cvcriterion=c("lrt", "cer", "lhr"),
#                       arg="beta=0.05,alpha=0.1,minn=10,L=NULL,peelcriterion=\"lr\"",
#                       probval=NULL, timeval=NULL,
#                       parallel=FALSE, conf=NULL, seed=NULL)
#
################
# Description   :
################
#
################
# Arguments     :
################
#
################
# Values        :
################
#
##########################################################################################################################################

sbh <- function(dataset,
                B=10, K=5, A=1000,
                vs=TRUE, cpv=FALSE,
                cvtype=c("combined", "averaged", "none"),
                cvcriterion=c("lrt", "cer", "lhr"),
                arg="beta=0.05,alpha=0.1,minn=10,L=NULL,peelcriterion=\"lr\"",
                probval=NULL, timeval=NULL,
                parallel=FALSE, conf=NULL, seed=NULL) {

  # Parsing and evaluating parameters
  alpha <- NULL
  beta <- NULL
  minn <- NULL
  L <- NULL
  peelcriterion <- NULL
  eval(parse( text=unlist(strsplit(x=arg, split=",")) ))
  digits <- getOption("digits")

  cvtype <- match.arg(arg=cvtype, choices=c("combined", "averaged", "none"), several.ok=FALSE)
  cvcriterion <- match.arg(arg=cvcriterion, choices=c("lrt", "cer", "lhr"), several.ok=FALSE)

  # Checking
  if (missing(dataset)) {
    stop("\nNo dataset provided !\n\n")
  } else {
    cat("\nSurvival dataset provided.\n\n")
    if (!(is.data.frame(dataset))) {
      dataset <- as.data.frame(dataset)
    }
    x <- as.matrix(dataset[ ,-c(1,2), drop=FALSE])
    mode(x) <- "numeric"
    times <- dataset$stime
    status <- dataset$status
    times[times <= 0] <- 10^(-digits)
    n <- nrow(x)
    p <- ncol(x)
    if (is.null(colnames(x))) colnames(x) <- paste("X", 1:ncol(x), sep="")
  }

  # Summarizing user choices
  if (cvtype != "none") {
    if (B > 1) {
        if (parallel) {
            cat("Requested parallel replicated ", K, "-fold cross-validation with ", conf$cpus*ceiling(B/conf$cpus), " replications \n", sep="")
        } else {
            cat("Requested replicated ", K, "-fold cross-validation with ", B, " replications \n", sep="")
        }
    } else {
        cat("Requested single ", K, "-fold cross-validation without replications \n", sep="")
    }
  } else {
    cvcriterion <- "none"
    B <- 1
    K <- 1
    parallel <- FALSE
    conf <- NULL
    cat("No cross-validation requested. No replication will be performed. No need of parallelization. \n")
  }
  cat("Cross-validation technique: ", cvtype, "\n")
  cat("Cross-validation criterion: ", disp(criterion=cvcriterion), "\n")
  cat("Variable pre-selection:", vs, "\n")
  cat("Computation of permutation p-values:", cpv, "\n")
  cat("Peeling criterion: ", disp(criterion=peelcriterion), "\n")
  cat("Parallelization:", parallel, "\n")
  cat("\n")

  # Optional pre-selection of covariates
  if (vs) {
    cat("Pre-selection of covariates and determination of directions of peeling... \n")
  } else {
    cat("Determination of directions of peeling... \n")
  }
  cv.presel.obj <- cv.presel(x=x, times=times, status=status, vs=vs, n=n, p=p, K=K, seed=seed)
  success <- cv.presel.obj$success

  # Survival Bump Hunting Modeling
  if (!success) {

    # Pre-selected covariates
    cat("Failed to pre-select any informative covariate. Exiting...\n", sep="")
    bool.plot <- FALSE
    varsign <- NULL
    selected <- NULL
    used <- NULL
    # Cross-validated minimum length from all replicates
    CV.maxsteps <- NULL
    # List of CV profiles
    CV.profiles <- NULL
    # Cross-validated optimal length from all replicates
    CV.nsteps <- NULL
    # Modal or majority vote trace value over the replicates
    CV.trace <- NULL
    # List of box boxcut and box peeling rules for each step
    CV.rules <- NULL
    # Box membership indicator vector of all observations for each step
    CV.boxind <- NULL
    # List of box statistics for each step
    CV.stats <- NULL
    # List of p-values for each step
    CV.pval <- NULL

  } else {

    # Pre-selected covariates
    indsel <- cv.presel.obj$indsel
    selected <- cv.presel.obj$selected
    x <- x[, indsel, drop=FALSE]
    p <- length(indsel)
    if (vs) {
        cat("Successfully pre-selected ", p, " covariates:\n", sep="")
    } else {
        cat("All ", p, " covariates were selected:\n", sep="")
    }
    print(selected)

    # Directions of directed peeling of pre-selected covariates
    varsign <- cv.presel.obj$varsign
    if (vs) {
        cat("Directions of peeling of pre-selected covariates:\n", sep="")
    } else {
        cat("Directions of peeling of all covariates:\n", sep="")
    }
    print(varsign)
    
    # Initial box boundaries
    initcutpts <- numeric(p)
    for(j in 1:p){
        if (varsign[j] == 1) {
            initcutpts[j] <- min(x[,j])
        } else if (varsign[j] == -1) {
            initcutpts[j] <- max(x[,j])
        } else {
            stop("The direction of peeling for covariate: ", j, " is invalid!\n", sep="")
        }
    }

    cat("Fitting and cross-validating the Survival Bump Hunting model using the PRSP algorithm ... \n")
    if (!parallel) {
        if (is.null(seed)) {
            seed <- runif(n=B, min=1, max=2) * 10^(digits-2)
        } else {
            seed <- (0:(B-1)) + seed
        }
        CV.box.rep.obj <- cv.box.rep(x=x, times=times, status=status,
                                     B=B, K=K, arg=arg,
                                     cvtype=cvtype,
                                     probval=probval, timeval=timeval,
                                     varsign=varsign, initcutpts=initcutpts,
                                     parallel=parallel, seed=seed)
    } else {
        if (conf$type == "SOCK") {
            cl <- makeCluster(spec=conf$names,
                              type=conf$type,
                              homogeneous=conf$homo,
                              outfile=conf$outfile,
                              verbose=conf$verbose)
        } else {
            cl <- makeCluster(spec=conf$cpus,
                              type=conf$type,
                              homogeneous=conf$homo,
                              outfile=conf$outfile,
                              verbose=conf$verbose)
        }
        clusterSetRNGStream(cl=cl, iseed=seed)
        a <- ceiling(B/conf$cpus)
        B <- a*conf$cpus
        obj.cl <- clusterCall(cl=cl, fun=cv.box.rep,
                              x=x, times=times, status=status,
                              B=a, K=K, arg=arg,
                              cvtype=cvtype,
                              probval=probval, timeval=timeval,
                              varsign=varsign, initcutpts=initcutpts,
                              parallel=parallel, seed=NULL)
        stopCluster(cl)
        CV.box.rep.obj <- list("cv.maxsteps"=numeric(0),
                               "cv.trace"=vector(mode="list", length=B),
                               "cv.boxind"=vector(mode="list", length=B),
                               "cv.boxcut"=vector(mode="list", length=B),
                               "cv.support"=vector(mode="list", length=B),
                               "cv.lhr"=vector(mode="list", length=B),
                               "cv.lrt"=vector(mode="list", length=B),
                               "cv.cer"=vector(mode="list", length=B),
                               "cv.time.bar"=vector(mode="list", length=B),
                               "cv.prob.bar"=vector(mode="list", length=B),
                               "cv.max.time.bar"=vector(mode="list", length=B),
                               "cv.min.prob.bar"=vector(mode="list", length=B))
        for (b in 1:conf$cpus) {
            CV.box.rep.obj$cv.maxsteps <- c(CV.box.rep.obj$cv.maxsteps, obj.cl[[b]]$cv.maxsteps)
            CV.box.rep.obj$cv.trace[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.trace
            CV.box.rep.obj$cv.boxind[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.boxind
            CV.box.rep.obj$cv.boxcut[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.boxcut
            CV.box.rep.obj$cv.support[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.support
            CV.box.rep.obj$cv.lhr[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.lhr
            CV.box.rep.obj$cv.lrt[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.lrt
            CV.box.rep.obj$cv.cer[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.cer
            CV.box.rep.obj$cv.time.bar[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.time.bar
            CV.box.rep.obj$cv.prob.bar[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.prob.bar
            CV.box.rep.obj$cv.max.time.bar[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.max.time.bar
            CV.box.rep.obj$cv.min.prob.bar[((b-1)*a+1):(b*a)] <- obj.cl[[b]]$cv.min.prob.bar
        }
        CV.box.rep.obj$success <- obj.cl[[1]]$success
    }

    # Collect the peeling statistics for each step from all the replicates
    CV.maxsteps <- CV.box.rep.obj$cv.maxsteps
    CV.trace <- CV.box.rep.obj$cv.trace
    CV.boxind <- CV.box.rep.obj$cv.boxind
    CV.boxcut <- CV.box.rep.obj$cv.boxcut
    CV.support <- CV.box.rep.obj$cv.support
    CV.lhr <- CV.box.rep.obj$cv.lhr
    CV.lrt <- CV.box.rep.obj$cv.lrt
    CV.cer <- CV.box.rep.obj$cv.cer
    CV.time.bar <- CV.box.rep.obj$cv.time.bar
    CV.prob.bar <- CV.box.rep.obj$cv.prob.bar
    CV.max.time.bar <- CV.box.rep.obj$cv.max.time.bar
    CV.min.prob.bar <- CV.box.rep.obj$cv.min.prob.bar
    success <- CV.box.rep.obj$success

    if (!success) {

        cat("Failure! Could not find any bump in this dataset. Exiting... \n", sep="")
        bool.plot <- FALSE
        used <- NULL
        # Cross-validated minimum length from all replicates
        CV.maxsteps <- NULL
        # List of CV mean profiles
        CV.mean.profiles <- list("lhr"=NULL, "lrt"=NULL, "cer"=NULL)
        # List of CV profiles
        CV.profiles <- NULL
        # Cross-validated optimal length from all replicates
        CV.nsteps <- NULL
        # Modal or majority vote trace value over the replicates
        CV.trace <- NULL
        # List of box boxcut and box peeling rules for each step
        CV.rules <- NULL
        # Box membership indicator vector of all observations for each step
        CV.boxind <- NULL
        # List of box statistics for each step
        CV.stats <- NULL
        # List of p-values for each step
        CV.pval <- NULL

    } else {

        cat("Success! ", B, " (replicated) cross-validation(s) has(ve) completed \n", sep="")
        bool.plot <- TRUE

        # Cross-validated minimum length from all replicates
        CV.maxsteps <- ceiling(mean(CV.maxsteps))

        # List of CV profiles
        cat("Generating cross-validated profiles and optimal peeling length ...\n")
        if ((cvtype == "averaged") || (cvtype == "combined")) {
            CV.lhr.mat <- list2mat(list=CV.lhr, fill=0, coltrunc=CV.maxsteps)
            CV.lrt.mat <- list2mat(list=CV.lrt, fill=0, coltrunc=CV.maxsteps)
            CV.cer.mat <- list2mat(list=CV.cer, fill=1, coltrunc=CV.maxsteps)
        } else if (cvtype == "none") {
            CV.lhr.mat <- matrix(data=NA, nrow=B, ncol=CV.maxsteps)
            CV.lrt.mat <- matrix(data=NA, nrow=B, ncol=CV.maxsteps)
            CV.cer.mat <- matrix(data=NA, nrow=B, ncol=CV.maxsteps)
        } else {
            stop("Invalid CV type option \n")
        }
        CV.profiles <- list("lhr"=CV.lhr.mat, "lrt"=CV.lrt.mat, "cer"=CV.cer.mat)
        colnames(CV.profiles$lhr) <- paste("step", 0:(CV.maxsteps-1), sep="")
        colnames(CV.profiles$lrt) <- paste("step", 0:(CV.maxsteps-1), sep="")
        colnames(CV.profiles$cer) <- paste("step", 0:(CV.maxsteps-1), sep="")

        # List of CV mean profiles
        CV.mean.lhr <- apply(CV.profiles$lhr, 2, mean)
        CV.mean.lrt <- apply(CV.profiles$lrt, 2, mean)
        CV.mean.cer <- apply(CV.profiles$cer, 2, mean)
        CV.mean.profiles <- list("lhr"=CV.mean.lhr, "lrt"=CV.mean.lrt, "cer"=CV.mean.cer)

        # Cross-validated optimal peeling length from all replicates
        if (cvtype == "none") {
            CV.nsteps <- CV.maxsteps
        } else if ((cvtype == "averaged") || (cvtype == "combined")) {
            if (cvcriterion=="lhr") {
                CV.nsteps <- which.max(CV.mean.profiles$lhr)
            } else if (cvcriterion=="lrt") {
                CV.nsteps <- which.max(CV.mean.profiles$lrt)
            } else if (cvcriterion=="cer") {
                CV.nsteps <- which.min(CV.mean.profiles$cer)
            }
        } else {
            stop("Invalid CV type option \n")
        }

        # covariate traces for each step
        # Distribution of trace values over the replicates (by step)
        # Modal trace values over the replicates (by step)
        cat("Generating cross-validated covariate traces ...\n")
        trace.dist <- lapply.array(X=CV.trace,
                                   rowtrunc=CV.nsteps,
                                   FUN=function(x){if (any(is.na(x)))
                                                    return(NA)
                                                   else
                                                    return(as.numeric(names(which.max(table(x, useNA="no")))))
                                                  },
                                   MARGIN=c(1,3))
        dimnames(trace.dist) <- list(paste("step", 0:(CV.nsteps-1), sep=""), 1:B)
        trace.mode <- apply(X=trace.dist,
                            FUN=function(x){as.numeric(names(which.max(table(x, useNA="no"))))},
                            MARGIN=1)
        names(trace.mode) <- paste("step", 0:(CV.nsteps-1), sep="")
        CV.trace <- list("dist"=trace.dist, "mode"=trace.mode)

        # covariates used for peeling based on covariate trace modal values
        used <- sort(unique(as.numeric(CV.trace$mode[-1])))
        names(used) <- colnames(x)[used]
        cat("Covariates used for peeling based on covariate trace modal values:\n")
        print(used)

        # List of box rules for each step
        cat("Generating cross-validated box rules for each step ...\n")
        CV.boxcut.mu <- lapply.array(X=CV.boxcut, rowtrunc=CV.nsteps, FUN=function(x){mean(x, na.rm=TRUE)}, MARGIN=1:2)
        CV.boxcut.sd <- lapply.array(X=CV.boxcut, rowtrunc=CV.nsteps, FUN=function(x){sd(x, na.rm=TRUE)}, MARGIN=1:2)
        rownames(CV.boxcut.mu) <- paste("step", 0:(CV.nsteps-1), sep="")
        rownames(CV.boxcut.sd) <- paste("step", 0:(CV.nsteps-1), sep="")
        colnames(CV.boxcut.mu) <- colnames(x)
        colnames(CV.boxcut.sd) <- colnames(x)
        CV.tmp <- as.data.frame(matrix(data=NA, nrow=CV.nsteps, ncol=p, dimnames=list(paste("step", 0:(CV.nsteps-1), sep=""), colnames(x))))
        for (j in 1:p) {
        if (varsign[j] > 0) {
            ss <- ">="
        } else {
            ss <- "<="
        }
        CV.tmp[, j] <- paste(paste(colnames(x)[j], ss, format(x=CV.boxcut.mu[, j], digits=3, nsmall=3), sep=""),
                             format(x=CV.boxcut.sd[, j], digits=3, nsmall=3), sep=" +/- ")
        }
        CV.rules <- list("mean"=CV.boxcut.mu, "sd"=CV.boxcut.sd, "frame"=CV.tmp)

        # Box membership indicator vector of all observations for each step
        # using the modal or majority vote value over the replicates
        cat("Generating cross-validated box memberships for each step ...\n")
        CV.boxind <- lapply.array(X=CV.boxind, rowtrunc=CV.nsteps, FUN=function(x){mean(x, na.rm=TRUE) >= 0.5}, MARGIN=1:2)
        rownames(CV.boxind) <- paste("step", 0:(CV.nsteps-1), sep="")
        colnames(CV.boxind) <- rownames(x)

        # List of box statistics for each step
        cat("Generating cross-validated box statistics for each step ...\n")
        CV.support.mu <- lapply.mat(X=CV.support, FUN=function(x){mean(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.support.sd <- lapply.mat(X=CV.support, FUN=function(x){sd(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.lhr.mu <- lapply.mat(X=CV.lhr, FUN=function(x){mean(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.lhr.sd <- lapply.mat(X=CV.lhr, FUN=function(x){sd(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.lrt.mu <- lapply.mat(X=CV.lrt, FUN=function(x){mean(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.lrt.sd <- lapply.mat(X=CV.lrt, FUN=function(x){sd(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.cer.mu <- lapply.mat(X=CV.cer, FUN=function(x){mean(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.cer.sd <- lapply.mat(X=CV.cer, FUN=function(x){sd(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.time.bar.mu <- lapply.mat(X=CV.time.bar, FUN=function(x){mean(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.time.bar.sd <- lapply.mat(X=CV.time.bar, FUN=function(x){sd(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.prob.bar.mu <- lapply.mat(X=CV.prob.bar, FUN=function(x){mean(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.prob.bar.sd <- lapply.mat(X=CV.prob.bar, FUN=function(x){sd(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.max.time.bar.mu <- lapply.mat(X=CV.max.time.bar, FUN=function(x){mean(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.max.time.bar.sd <- lapply.mat(X=CV.max.time.bar, FUN=function(x){sd(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.min.prob.bar.mu <- lapply.mat(X=CV.min.prob.bar, FUN=function(x){mean(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.min.prob.bar.sd <- lapply.mat(X=CV.min.prob.bar, FUN=function(x){sd(x, na.rm=TRUE)}, coltrunc=CV.nsteps)
        CV.stats.mu <- data.frame("cv.support"=CV.support.mu,
                                  "cv.lhr"=CV.lhr.mu,
                                  "cv.lrt"=CV.lrt.mu,
                                  "cv.cer"=CV.cer.mu,
                                  "cv.time.bar"=CV.time.bar.mu,
                                  "cv.prob.bar"=CV.prob.bar.mu,
                                  "cv.max.time.bar"=CV.max.time.bar.mu,
                                  "cv.min.prob.bar"=CV.min.prob.bar.mu)
        rownames(CV.stats.mu) <- paste("step", 0:(CV.nsteps-1), sep="")
        CV.stats.sd <- data.frame("cv.support"=CV.support.sd,
                                  "cv.lhr"=CV.lhr.sd,
                                  "cv.lrt"=CV.lrt.sd,
                                  "cv.cer"=CV.cer.sd,
                                  "cv.time.bar"=CV.time.bar.sd,
                                  "cv.prob.bar"=CV.prob.bar.sd,
                                  "cv.max.time.bar"=CV.max.time.bar.sd,
                                  "cv.min.prob.bar"=CV.min.prob.bar.sd)
        rownames(CV.stats.sd) <- paste("step", 0:(CV.nsteps-1), sep="")
        CV.stats <- list("mean"=CV.stats.mu, "sd"=CV.stats.sd)

        # Vector of p-values for each step
        if (cpv) {
            cat("Computation of cross-validated permutation p-values for each step ... \n")
            arg <- paste("beta=", beta, ",alpha=", alpha, ",minn=", minn, ",L=", CV.nsteps-1, ",peelcriterion=\"", peelcriterion, "\"", sep="")
            CV.pval <- cv.pval(x=x, times=times, status=status,
                               cvtype=cvtype,
                               varsign=varsign, initcutpts=initcutpts,
                               A=A, K=K, arg=arg, obs.chisq=CV.stats$mean$cv.lrt,
                               parallel=parallel, conf=conf)
        } else {
            CV.pval <- NULL
        }
    }
  }

  # Creating the return object 'CV.fit'
  CV.fit <- list("cv.maxsteps"=CV.maxsteps,
                 "cv.nsteps"=CV.nsteps,
                 "cv.trace"=CV.trace,
                 "cv.boxind"=CV.boxind,
                 "cv.rules"=CV.rules,
                 "cv.stats"=CV.stats,
                 "cv.pval"=CV.pval)
  cat("Finished!\n")

  # Returning the final 'PRSP' object
  return(structure(list("x"=x, "times"=times, "status"=status,
                        "B"=B, "K"=K, "A"=A, "vs"=vs, "cpv"=cpv, "arg"=arg,
                        "cvtype"=cvtype, "cvcriterion"=cvcriterion,
                        "varsign"=varsign, "selected"=selected, "used"=used,
                        "probval"=probval, "timeval"=timeval,
                        "cvfit"=CV.fit,
                        "cvprofiles"=CV.profiles,
                        "cvmeanprofiles"=CV.mean.profiles,
                        "plot"=bool.plot, 
                        "config"=list("parallel"=parallel, 
                                      "names"=conf$names, 
                                      "cpus"=conf$cpus,
                                      "type"=conf$type,
                                      "homo"=conf$homo,
                                      "verbose"=conf$verbose,
                                      "outfile"=conf$outfile),
                        "seed"=seed),
                   class = "PRSP"))
}
##########################################################################################################################################




##########################################################################################################################################
# 2. END-USER FUNCTIONS FOR NEWS, SUMMARY AND PREDICTION
##########################################################################################################################################

##########################################################################################################################################
################
#Usage         :
################
#                   PRIMsrc.news(...)
#
################
# Description   :
################
#
################
# Arguments     :
################
#
################
# Values        :
################
#
##########################################################################################################################################

PRIMsrc.news <- function(...) {
    newsfile <- file.path(system.file(package="PRIMsrc"), "NEWS")
    file.show(newsfile)
}
##########################################################################################################################################




##########################################################################################################################################
################
#Usage         :
################
#                   summary(object, ...)
#
################
# Description   :
################
#
################
# Arguments     :
################
#
################
# Values        :
################
#
##########################################################################################################################################

summary.PRSP <- function(object, ...) {

  if (!inherits(object, 'PRSP'))
        stop("Primary argument much be an object of class 'PRSP' \n")

  alpha <- NULL
  beta <- NULL
  minn <- NULL
  L <- NULL
  peelcriterion <- NULL
  eval(parse( text=unlist(strsplit(x=object$arg, split=",")) ))

  cat("S3-class object: `", attr(x=object, "class"), "` \n\n")

  if (object$cvtype != "none") {
    if (object$B > 1) {
        if (object$config$parallel) {
            cat("Replicated ", object$K, "-fold cross-validation with ", object$config$cpus*ceiling(object$B/object$config$cpus), " replications \n\n", sep="")
        } else {
            cat("Replicated ", object$K, "-fold cross-validation with ", object$B, " replications \n\n", sep="")
        }
    } else {
        cat("Single ", object$K, "-fold cross-validation without replications \n\n", sep="")
    }
  } else {
    cat("'PRSP' object without cross-validation and replications\n\n", sep="")
  }
  cat("Variable pre-selection:", object$vs, "\n")
  cat("PRSP parameters:\n")
  cat("\t Peeling criterion: ", disp(criterion=peelcriterion), "\n")
  cat("\t Peeling percentile: ", alpha*100, "%\n")
  cat("\t Minimal box support: ", beta*100, "%\n")
  cat("\t Minimal box sample size: ", minn, "\n")
  cat("\t Peeling steps: ", L, "\n")
  cat("Cross-validation technique: ", object$cvtype, "\n")
  cat("Cross-validation criterion: ", disp(criterion=object$cvcriterion), "\n")
  cat("Computation of permutation p-values:", object$cpv, "\n")
  cat("Configuration of parallelization : \n")
  print(object$config)
  cat("\n")
  
  invisible()
}
##########################################################################################################################################




##########################################################################################################################################
################
#Usage         :
################
#                   print(x, digits=3, ...)
#
################
# Description   :
################
#
################
# Arguments     :
################
#
################
# Values        :
################
#
##########################################################################################################################################

print.PRSP <- function(x, digits=3, ...) {

  if (!inherits(x, 'PRSP'))
        stop("Primary argument much be an object of class 'PRSP' \n")

  obj <- x
  cat("Selected covariates:\n")
  print(obj$selected)
  cat("\n")
  
  cat("Used covariates:\n")
  print(obj$used)
  cat("\n")

  cat("Maximum number of peeling steps:\n")
  print(obj$cvfit$cv.maxsteps)
  cat("\n")
  
  out <- obj$cvfit$cv.nsteps-1
  names(out) <- NULL
  cat("Optimum number of peeling steps (not counting step #0):\n")
  print(out)
  cat("\n")
  
  cat("Traces of covariate usage for all replications (columns) for all steps (rows):\n")
  print(obj$cvfit$cv.trace$dist)
  cat("\n")
  
  cat("Modal trace values of covariate usage at each peeling step:\n")
  print(obj$cvfit$cv.trace$mode)
  cat("\n")
  
  cat("Cross-validated permutation p-values at each peeling step:\n")
  print(format(obj$cvfit$cv.pval, digits=digits), quote = FALSE)
  cat("\n")

  used <- obj$used
  cat("Decision rules on the covariates (columns) for all peeling steps (rows):\n")
  print(obj$cvfit$cv.rules$frame[,used,drop=FALSE], quote = FALSE)
  cat("\n")
  
  out <- format(obj$cvfit$cv.stats$mean, digits=digits)
  colnames(out) <- c("Support", "LHR", "LRT", "CER", "EFT", "EFP", "MEFT", "MEFP")
  cat("Box endpoint quantities of interest (columns) for all peeling steps (rows):\n")
  print(out)
  cat("\n")
  
  cat("Box support (sample) size at each peeling step:\n")
  print(round(nrow(obj$x)*obj$cvfit$cv.stats$mean$cv.support,0))
  cat("\n")
  
  cat("Individual observation box membership indicator (columns) for all peeling steps (rows):\n")
  print(obj$cvfit$cv.boxind)
  cat("\n")
  
  invisible()
}
##########################################################################################################################################




##########################################################################################################################################
################
#Usage         :
################
#                   predict(object, newdata, steps, na.action = na.omit, ...)
#
################
# Description   :
################
#
################
# Arguments     :
################
#
################
# Values        :
################
#
##########################################################################################################################################

predict.PRSP <- function (object, newdata, steps, na.action = na.omit, ...) {

  if (!inherits(object, 'PRSP'))
        stop("Primary argument much be an object of class 'PRSP' \n")

  X <- as.matrix(newdata)
  X.names <- colnames(X)
  X.range <- apply(X=X, MARGIN=2, FUN=range)
  n <- nrow(X)
  p <- ncol(X)

  if (ncol(object$x) != p) {
    stop("Non-matching dimensions of newdata to PRSP object \n")
  }

  if (missing(steps) || is.null(steps))
    steps <- object$cvfit$cv.nsteps

  L <- length(steps)
  boxcut <- object$cvfit$cv.rules$mean[steps,,drop=FALSE]
  varsign <- object$varsign

  pred.boxind <- matrix(NA, nrow=L, ncol=n, dimnames=list(paste("step ", steps, sep=""), rownames(X)))
  for (l in 1:L) {
    boxcutsign <- boxcut[l, ] * varsign
    x.cut <- t(t(X) * varsign)
    x.ind <- t(t(x.cut) >= boxcutsign)
    pred.boxind[l,] <- (rowMeans(x.ind) == 1)  # Set as TRUE which observations are inside the box boundaries for all axes directions
  }

  pred.vertices <- vector(mode="list", length=L)
  names(pred.vertices) <- paste("step ", steps, sep="")
  for (i in 1:L) {
    pred.vertices[[i]] <- matrix(data=NA, nrow=2, ncol=p, dimnames=list(c("LB","UB"), X.names))
    for (j in 1:p) {
      pred.vertices[[i]][1,j] <- ifelse(test=(varsign[j] > 0),
                                        yes=max(X.range[1,j], boxcut[i,j]),
                                        no=min(X.range[1,j], boxcut[i,j]))
      pred.vertices[[i]][2,j] <- ifelse(test=(varsign[j] < 0),
                                        yes=min(X.range[2,j], boxcut[i,j]),
                                        no=max(X.range[2,j], boxcut[i,j]))
    }
  }

  return(list("boxind"=pred.boxind, "vertices"=pred.vertices))
}
##########################################################################################################################################




##########################################################################################################################################
# 3. END-USER PLOTTING FUNCTIONS FOR MODEL VALIDATION AND VISUALIZATION OF RESULTS
##########################################################################################################################################

##########################################################################################################################################
################
# Usage         :
################
#                    plot_profile(object,
#                                 main=NULL,
#                                 xlab="Peeling Steps", ylab="Mean Profiles",
#                                 add.sd=TRUE, add.legend=TRUE, add.profiles=TRUE,
#                                 pch=20, col=1, lty=1, lwd=2, cex=2,
#                                 device=NULL, file="Profile Plot", path=getwd(),
#                                 horizontal=FALSE, width=8.5, height=5.0, ...) {
#
################
# Description   :
################
#
################
# Arguments     :
################
#
################
# Values        :
################
#
##########################################################################################################################################

plot_profile <- function(object,
                         main=NULL,
                         xlab="Peeling Steps", ylab="Mean Profiles",
                         add.sd=TRUE, add.legend=TRUE, add.profiles=TRUE,
                         pch=20, col=1, lty=1, lwd=2, cex=2,
                         device=NULL, file="Profile Plot", path=getwd(),
                         horizontal=FALSE, width=8.5, height=5.0, ...) {

  if (!inherits(object, 'PRSP'))
        stop("Primary argument much be an object of class 'PRSP' \n")

  if (object$plot) {
    if (is.null(object$cvcriterion)) {
      cat("No CV here, so no cross-validated tuning profile to plot!\n")
    } else {

      profileplot <- function(object, main, xlab, ylab,
                              add.sd, add.legend, add.profiles,
                              pch, col, lty, lwd, cex, ...) {

        if (object$cvcriterion == "lhr") {
          txt <- "LHR"
          profiles <- object$cvprofiles$lhr
          ylim <- range(0, profiles, na.rm=TRUE)
        } else if (object$cvcriterion == "lrt") {
          txt <- "LRT"
          profiles <- object$cvprofiles$lrt
          ylim <- range(0, profiles, na.rm=TRUE)
        } else if (object$cvcriterion == "cer") {
          txt <- "CER"
          profiles <- object$cvprofiles$cer
          ylim <- range(0, 1, profiles, na.rm=TRUE)
        } else {
          stop("Invalid CV criterion.\n")
        }     
        if (!is.null(main)) {
            par(mfrow=c(1, 1), oma=c(0, 0, 3, 0), mar=c(2.5, 2.5, 4.0, 1.5), mgp=c(1.5, 0.5, 0))
        } else {
            par(mfrow=c(1, 1), oma=c(0, 0, 0, 0), mar=c(2.5, 2.5, 4.0, 1.5), mgp=c(1.5, 0.5, 0))
        }
        Lm <- object$cvfit$cv.maxsteps
        mean.profile <- apply(profiles, 2, mean, na.rm=TRUE)
        se.profile <- apply(profiles, 2, sd, na.rm=TRUE)
        if (add.profiles) {
          matplot(t(profiles), axes=FALSE, type="b",
                  xlab="", ylab="", main="", ylim=ylim,
                  pch=pch, lty=1, lwd=lwd/4, cex=cex/4)
          par(new=TRUE)
        }
        plot(0:(Lm-1), mean.profile, axes=FALSE, type="b",
             xlab=xlab, ylab=paste(txt ," ", ylab, sep=""), main=NULL, ylim=ylim,
             pch=pch, col=col, lty=lty, lwd=lwd, cex=cex)
        axis(side=1, pos=min(ylim), at=0:(Lm-1), labels=0:(Lm-1), cex.axis=1, line=NA)
        axis(side=2, pos=0, at=pretty(ylim), cex.axis=1, line=NA)
        segments(x0=object$cvfit$cv.nsteps-1, y0=min(ylim), x1=object$cvfit$cv.nsteps-1, y1=mean.profile[object$cvfit$cv.nsteps], col=col, lty=2, lwd=lwd)
        if (add.sd) {
            arrows(0:(Lm-1), mean.profile, 0:(Lm-1), mean.profile - se.profile, length=0.1, angle=90, code=2, col=col, lwd=lwd)
            arrows(0:(Lm-1), mean.profile, 0:(Lm-1), mean.profile + se.profile, length=0.1, angle=90, code=2, col=col, lwd=lwd)
        }
        if (!is.null(main)) {
            mtext(text=main, cex=1, side=3, outer=TRUE)
        }
        if (add.legend) {
            legend("top", xpd=TRUE, inset=0, legend=c("Sample Mean", "Std. Error"), pch=pch, col=col, lty=lty, lwd=lwd, cex=0.6, pt.cex=cex/2)
        }
      }

      if (is.null(device)) {
        dev.new(width=width, height=height, title="Profile Plot", noRStudioGD = TRUE)
        profileplot(object=object, main=main, xlab=xlab, ylab=ylab,
                    add.sd=add.sd, add.legend=add.legend, add.profiles=add.profiles,
                    pch=pch, col=col, lty=lty, lwd=lwd, cex=cex)
      } else if (device == "PS") {
        path <- normalizePath(path=paste(path, "/", sep=""), winslash="\\", mustWork=FALSE)
        file <- paste(file, ".ps", sep="")
        cat("\nOUTPUT: \n")
        cat("Filename : ", file, "\n")
        cat("Directory: ", path, "\n")
        postscript(file=paste(path, file, sep=""), width=width, height=height, onefile=TRUE, horizontal=horizontal)
        profileplot(object=object, main=main, xlab=xlab, ylab=ylab,
                    add.sd=add.sd, add.legend=add.legend, add.profiles=add.profiles,
                    pch=pch, col=col, lty=lty, lwd=lwd, cex=cex)
        dev.off()
      } else if (device == "PDF") {
        path <- normalizePath(path=paste(path, "/", sep=""), winslash="\\", mustWork=FALSE)
        file <- paste(file, ".pdf", sep="")
        cat("\nOUTPUT: \n")
        cat("Filename : ", file, "\n")
        cat("Directory: ", path, "\n")
        pdf(file=paste(path, file, sep=""), width=width, height=height, onefile=TRUE, paper=ifelse(test=horizontal, yes="USr", no="US"))
        profileplot(object=object, main=main, xlab=xlab, ylab=ylab,
                    add.sd=add.sd, add.legend=add.legend, add.profiles=add.profiles,
                    pch=pch, col=col, lty=lty, lwd=lwd, cex=cex)
        dev.off()
      } else {
        stop("Currently allowed display devices are \"PS\" (Postscript) or \"PDF\" (Portable Document Format) \n")
      }
    }
  } else {
    cat("Either the covariate pre-selection or the Survival Bump Hunting modeling failed for this dataset.\n
        So, there is nothing to plot here.\n")
  }
  invisible()
}
##########################################################################################################################################





##########################################################################################################################################
################
# Usage         :
################
#                    plot_scatter(object,
#                                 main=NULL,
#                                 proj=c(1,2), splom=TRUE, boxes=FALSE,
#                                 steps=object$cvfit$cv.nsteps,
#                                 pch=16, cex=0.5, col=, col=2:(length(steps)+1),
#                                 col.box=2:(length(steps)+1), lty.box=rep(2,length(steps)), lwd.box=rep(1,length(steps)),
#                                 add.legend=TRUE,
#                                 device=NULL, file="Scatter Plot", path=getwd(),
#                                 horizontal=FALSE, width=5, height=5, ...)
#
################
# Description   :
################
#
################
# Arguments     :
################
#
################
# Values        :
################
#
##########################################################################################################################################

plot_scatter <- function(object,
                         main=NULL,
                         proj=c(1,2), splom=TRUE, boxes=FALSE,
                         steps=object$cvfit$cv.nsteps,
                         pch=16, cex=0.5, col=2:(length(steps)+1),
                         col.box=2:(length(steps)+1), lty.box=rep(2,length(steps)), lwd.box=rep(1,length(steps)),
                         add.legend=TRUE,
                         device=NULL, file="Scatter Plot", path=getwd(),
                         horizontal=FALSE, width=5, height=5, ...) {

  if (!inherits(object, 'PRSP'))
        stop("Primary argument much be an object of class 'PRSP' \n")

  if (object$plot) {

    scatterplot <- function(object,
                            main,
                            proj, splom, boxes,
                            steps,
                            add.legend, pch, cex, col,
                            col.box, lty.box, lwd.box, ...) {

        if (!is.null(main)) {
            par(mfrow=c(1, 1), oma=c(0, 0, 3, 0), mar=c(2.5, 2.5, 4.0, 1.5), mgp=c(1.5, 0.5, 0))
        } else {
            par(mfrow=c(1, 1), oma=c(0, 0, 0, 0), mar=c(2.5, 2.5, 4.0, 1.5), mgp=c(1.5, 0.5, 0))
        }

        X <- object$x[,proj]
        X.names <- colnames(X)

        if (is.null(steps))
          steps <- object$cvfit$cv.nsteps

        L <- length(steps)
        eqscplot(x=X, type="p", pch=pch, cex=cex, col=1, main=NULL, xlab=X.names[1], ylab=X.names[2], ...)
        if (splom) {
            for (i in 1:L) {
                w <- object$cvfit$cv.boxind[steps[i],]
                points(x=object$x[w,proj], type="p", pch=pch, cex=cex, col=col[i], ...)
            }
        }
        if (boxes) {
            X.range <- apply(X=X, MARGIN=2, FUN=range)
            boxcut <- object$cvfit$cv.rules$mean[steps,proj,drop=FALSE]
            varsign <- object$varsign[proj]
            vertices <- vector(mode="list", length=L)
            for (i in 1:L) {
                vertices[[i]] <- matrix(data=NA, nrow=2, ncol=2, dimnames=list(c("LB","UB"), X.names))
                for (j in 1:2) {
                    vertices[[i]][1,j] <- ifelse(test=(varsign[j] > 0),
                                                 yes=max(X.range[1,j], boxcut[i,j]),
                                                 no=min(X.range[1,j], boxcut[i,j]))
                    vertices[[i]][2,j] <- ifelse(test=(varsign[j] < 0),
                                                 yes=min(X.range[2,j], boxcut[i,j]),
                                                 no=max(X.range[2,j], boxcut[i,j]))
                }
            }
            for (i in 1:L) {
                rect(vertices[[i]][1,1], vertices[[i]][1,2], vertices[[i]][2,1], vertices[[i]][2,2],
                     border=col.box[i], col=NA, lty=lty.box[i], lwd=lwd.box[i])
            }
        }
        if (!is.null(main)) {
            mtext(text=main, cex=1, side=3, outer=TRUE)
        }
        if (add.legend) {
            legend("topleft", xpd=TRUE, inset=0.01, legend=paste("Step: ", steps, sep=""), pch=pch, col=col, cex=cex)
        }
    }

    if (is.null(device)) {
        dev.new(width=width, height=height, title="Scatter Plot", noRStudioGD = TRUE)
        scatterplot(object=object,
                    main=main,
                    proj=proj, splom=splom, boxes=boxes, steps=steps,
                    add.legend=add.legend, pch=pch, cex=cex, col=col,
                    col.box=col.box, lty.box=lty.box, lwd.box=lwd.box)
    } else if (device == "PS") {
        path <- normalizePath(path=paste(path, "/", sep=""), winslash="\\", mustWork=FALSE)
        file <- paste(file, ".ps", sep="")
        cat("\nOUTPUT: \n")
        cat("Filename : ", file, "\n")
        cat("Directory: ", path, "\n")
        postscript(file=paste(path, file, sep=""), width=width, height=height, onefile=TRUE, horizontal=horizontal)
        scatterplot(object=object,
                    main=main,
                    proj=proj, splom=splom, boxes=boxes, steps=steps,
                    add.legend=add.legend, pch=pch, cex=cex, col=col,
                    col.box=col.box, lty.box=lty.box, lwd.box=lwd.box)
        dev.off()
    } else if (device == "PDF") {
        path <- normalizePath(path=paste(path, "/", sep=""), winslash="\\", mustWork=FALSE)
        file <- paste(file, ".pdf", sep="")
        cat("\nOUTPUT: \n")
        cat("Filename : ", file, "\n")
        cat("Directory: ", path, "\n")
        pdf(file=paste(path, file, sep=""), width=width, height=height, onefile=TRUE, paper=ifelse(test=horizontal, yes="USr", no="US"))
        scatterplot(object=object,
                    main=main,
                    proj=proj, splom=splom, boxes=boxes, steps=steps,
                    add.legend=add.legend, pch=pch, cex=cex, col=col,
                    col.box=col.box, lty.box=lty.box, lwd.box=lwd.box)
        dev.off()
    } else {
        stop("Currently allowed display devices are \"PS\" (Postscript) or \"PDF\" (Portable Document Format) \n")
    }
  } else {
    cat("Either the covariate pre-selection or the Survival Bump Hunting modeling failed for this dataset.\n
        So, there is nothing to plot here.\n")
  }
  invisible()
}
##########################################################################################################################################




##########################################################################################################################################
################
# Usage         :
################
#                    plot_boxtraj (object,
#                                  main=NULL,
#                                  xlab="Box Mass", ylab="Covariate Range",
#                                  toplot=object$used,
#                                  col.cov, lty.cov, lwd.cov,
#                                  col=1, lty=1, lwd=1,
#                                  cex=1, add.legend=FALSE, text.legend=NULL,
#                                  nr=NULL, nc=NULL,
#                                  device=NULL, file="Covariate Trajectory Plots", path=getwd())
#                                  horizontal=FALSE, width=8.5, height=8.5, ...)
#
################
# Description   :
################
#
################
# Arguments     :
################
#
################
# Values        :
################
#
##########################################################################################################################################

plot_boxtraj <- function(object,
                         main=NULL,
                         xlab="Box Mass", ylab="Covariate Range",
                         toplot=object$used,
                         col.cov, lty.cov, lwd.cov,
                         col=1, lty=1, lwd=1,
                         cex=1, add.legend=FALSE, text.legend=NULL,
                         nr=NULL, nc=NULL,
                         device=NULL, file="Covariate Trajectory Plots", path=getwd(),
                         horizontal=FALSE, width=8.5, height=11.5, ...) {

  if (!inherits(object, 'PRSP'))
        stop("Primary argument much be an object of class 'PRSP' \n")

  if (object$plot) {
    boxtrajplot <- function(object,
                            main, xlab, ylab,
                            toplot,
                            col.cov, lty.cov, lwd.cov,
                            col, lty, lwd,
                            cex, add.legend, text.legend,
                            nr, nc, ...) {

        p <- length(toplot)
        varnames <- colnames(object$x)
        if (is.null(nc))
            nc <- 3
        if (is.null(nr)) {
            if (p %% nc == 0) {
                nr <- p%/%nc + 2
            } else {
                nr <- ((p+(1:nc))[which((p+(1:nc)) %% nc == 0)])%/%nc + 2
            }
        }
        if (missing(col.cov)) {
            col.cov <- 2:(p+1)
        }
        if (missing(lty.cov)) {
            lty.cov <- rep(1,p)
        }
        if (missing(lwd.cov)) {
            lwd.cov <- rep(1,p)
        }

        if (!is.null(main)) {
            par(mfrow=c(nr, nc), oma=c(0, 0, 3, 0), mar=c(2.5, 2.5, 2.0, 1.5), mgp=c(1.5, 0.5, 0))
        } else {
            par(mfrow=c(nr, nc), oma=c(0, 0, 0, 0), mar=c(2.5, 2.5, 2.0, 1.5), mgp=c(1.5, 0.5, 0))
        }

        for (j in 1:p) {
            plot(x=object$cvfit$cv.stats$mean$cv.support,
                 y=object$cvfit$cv.rules$mean[,toplot[j]],
                 type='s', col=col.cov[j], lty=lty.cov[j], lwd=lwd.cov[j],
                 main=paste(varnames[toplot[j]], " covariate trajectory", sep=""), cex.main=cex,
                 xlim=range(0,1),
                 ylim=range(object$x[,toplot[j]], na.rm=TRUE),
                 xlab=xlab,
                 ylab=ylab)
        }
        if (add.legend)
          legend("bottomleft", inset=0.01, legend=text.legend, cex=cex)

        par(mfg=c(nr-1, 1))
        plot(object$cvfit$cv.stats$mean$cv.support,
             object$cvfit$cv.stats$mean$cv.support,
             type='s', col=col, lty=lty, lwd=lwd,
             main="Box support trajectory", cex.main=cex,
             xlim=range(0,1),
             ylim=range(0,1),
             xlab=xlab,
             ylab=expression(paste("Support (", beta, ")", sep="")))
        if (add.legend)
            legend("bottomright", inset=0.01, legend=text.legend, cex=cex)

        par(mfg=c(nr-1, 2))
        plot(object$cvfit$cv.stats$mean$cv.support,
             object$cvfit$cv.stats$mean$cv.max.time.bar,
             type='s', col=col, lty=lty, lwd=lwd,
             main="MEFT trajectory", cex.main=cex,
             xlim=range(0,1),
             ylim=range(0, object$cvfit$cv.stats$mean$cv.max.time.bar, na.rm=TRUE),
             xlab=xlab,
             ylab="Time")
        if (add.legend)
            legend("bottomright", inset=0.01, legend=text.legend, cex=cex)

        par(mfg=c(nr-1, 3))
        plot(object$cvfit$cv.stats$mean$cv.support,
             object$cvfit$cv.stats$mean$cv.min.prob.bar,
             type='s', col=col, lty=lty, lwd=lwd,
             main="MEFP trajectory", cex.main=cex,
             xlim=range(0,1),
             ylim=range(0,1),
             xlab=xlab,
             ylab="Probability")
        if (add.legend)
            legend("bottomright", inset=0.01, legend=text.legend, cex=cex)

        par(mfg=c(nr, 1))
        plot(object$cvfit$cv.stats$mean$cv.support,
             object$cvfit$cv.stats$mean$cv.lhr,
             type='s', col=col, lty=lty, lwd=lwd,
             main="LHR trajectory", cex.main=cex,
             xlim=range(0,1),
             ylim=range(0, object$cvfit$cv.stats$mean$cv.lhr, na.rm=TRUE),
             xlab=xlab,
             ylab=expression(paste("Log-Hazard Ratio (", lambda,")", sep="")))
        if (add.legend)
            legend("top", inset=0.01, legend=text.legend, cex=cex)

        par(mfg=c(nr, 2))
        plot(object$cvfit$cv.stats$mean$cv.support,
             object$cvfit$cv.stats$mean$cv.lrt,
             type='s', col=col, lty=lty, lwd=lwd,
             main="LRT trajectory", cex.main=cex,
             xlim=range(0,1),
             ylim=range(0, object$cvfit$cv.stats$mean$cv.lrt, na.rm=TRUE),
             xlab=xlab,
             ylab=expression(paste("Log-rank test (", chi^2 ,")", sep="")))
        if (add.legend)
            legend("top", inset=0.01, legend=text.legend, cex=cex)

        par(mfg=c(nr, 3))
        plot(object$cvfit$cv.stats$mean$cv.support,
             object$cvfit$cv.stats$mean$cv.cer,
             type='s', col=col, lty=lty, lwd=lwd,
             main="CER trajectory", cex.main=cex,
             xlim=range(0,1),
             ylim=range(0,1),
             xlab=xlab,
             ylab=expression(paste("1-C (", theta,")", sep="")))
        if (add.legend)
            legend("top", inset=0.01, legend=text.legend, cex=cex)
        if (!is.null(main)) {
            mtext(text=main, cex=1, side=3, outer=TRUE)
        }
    }

    if (is.null(device)) {
        dev.new(width=width, height=height, title="Covariate Trajectory Plots", noRStudioGD = TRUE)
        boxtrajplot(object=object,
                    main=main, xlab=xlab, ylab=ylab,
                    toplot=toplot,
                    col.cov=col.cov, lty.cov=lty.cov, lwd.cov=lwd.cov,
                    col=col, lty=lty, lwd=lwd,
                    cex=cex, add.legend=add.legend, text.legend=text.legend,
                    nr=nr, nc=nc)
    } else if (device == "PS") {
        path <- normalizePath(path=paste(path, "/", sep=""), winslash="\\", mustWork=FALSE)
        file <- paste(file, ".ps", sep="")
        cat("\nOUTPUT: \n")
        cat("Filename : ", file, "\n")
        cat("Directory: ", path, "\n")
        postscript(file=paste(path, file, sep=""), width=width, height=height, onefile=TRUE, horizontal=horizontal)
        boxtrajplot(object=object,
                    main=main, xlab=xlab, ylab=ylab,
                    toplot=toplot,
                    col.cov=col.cov, lty.cov=lty.cov, lwd.cov=lwd.cov,
                    col=col, lty=lty, lwd=lwd,
                    cex=cex, add.legend=add.legend, text.legend=text.legend,
                    nr=nr, nc=nc)
        dev.off()
    } else if (device == "PDF") {
        path <- normalizePath(path=paste(path, "/", sep=""), winslash="\\", mustWork=FALSE)
        file <- paste(file, ".pdf", sep="")
        cat("\nOUTPUT: \n")
        cat("Filename : ", file, "\n")
        cat("Directory: ", path, "\n")
        pdf(file=paste(path, file, sep=""), width=width, height=height, onefile=TRUE, paper=ifelse(test=horizontal, yes="USr", no="US"))
        boxtrajplot(object=object,
                    main=main, xlab=xlab, ylab=ylab,
                    toplot=toplot,
                    col.cov=col.cov, lty.cov=lty.cov, lwd.cov=lwd.cov,
                    col=col, lty=lty, lwd=lwd,
                    cex=cex, add.legend=add.legend, text.legend=text.legend,
                    nr=nr, nc=nc)
        dev.off()
    } else {
        stop("Currently allowed display devices are \"PS\" (Postscript) or \"PDF\" (Portable Document Format) \n")
    }
  } else {
    cat("Either the covariate pre-selection or the Survival Bump Hunting modeling failed for this dataset.\n
        So, there is nothing to plot here.\n")
  }
  invisible()
}
##########################################################################################################################################





##########################################################################################################################################
################
# Usage         :
################
#                    plot_boxtrace (object,
#                                   main=NULL,
#                                   xlab="Box Mass", ylab="Covariate Range (centered)",
#                                   toplot=object$used,
#                                   center=TRUE, scale=FALSE,
#                                   col.cov, lty.cov, lwd.cov,
#                                   col=1, lty=1, lwd=1,
#                                   cex=1, add.legend=FALSE, text.legend=NULL,
#                                   device=NULL, file="Covariate Trace Plots", path=getwd(),
#                                   horizontal=FALSE, width=8.5, height=8.5, ...)
#
################
# Description   :
################
#
################
# Arguments     :
################
#
################
# Values        :
################
#
##########################################################################################################################################

plot_boxtrace <- function(object,
                          main=NULL, xlab="Box Mass", ylab="Covariate Range (centered)",
                          toplot=object$used,
                          center=TRUE, scale=FALSE,
                          col.cov, lty.cov, lwd.cov,
                          col=1, lty=1, lwd=1,
                          cex=1, add.legend=FALSE, text.legend=NULL,
                          device=NULL, file="Covariate Trace Plots", path=getwd(),
                          horizontal=FALSE, width=8.5, height=8.5, ...) {

  if (!inherits(object, 'PRSP'))
        stop("Primary argument much be an object of class 'PRSP' \n")

  if (object$plot) {
    boxtraceplot <- function(object,
                             main, xlab, ylab,
                             toplot,
                             center, scale,
                             col.cov, lty.cov, lwd.cov,
                             col, lty, lwd,
                             cex, add.legend, text.legend, ...) {

        p <- length(toplot)
        varnames <- colnames(object$x)
        ticknames <- paste(varnames[toplot], " -", sep="")
        pointtrace <- c(object$cvfit$cv.trace$mode[2], object$cvfit$cv.trace$mode[-1])
        matchtrace <- pmatch(x=pointtrace, table=toplot, duplicates.ok = TRUE)
        if (missing(col.cov)) {
            col.cov <- 2:(p+1)
        }
        if (missing(lty.cov)) {
            lty.cov <- rep(1,p)
        }
        if (missing(lwd.cov)) {
            lwd.cov <- rep(1,p)
        }

        if (!is.null(main)) {
            par(mfrow=c(2, 1), oma=c(0, 0, 2, 0), mar=c(2.5, 8.0, 2.0, 0.0), mgp=c(1.5, 0.5, 0))
        } else {
            par(mfrow=c(2, 1), oma=c(0, 0, 0, 0), mar=c(2.5, 8.0, 2.0, 0.0), mgp=c(1.5, 0.5, 0))
        }

        boxcut.scaled <- scale(x=object$cvfit$cv.rules$mean[,toplot], center=center, scale=scale)
        plot(x=object$cvfit$cv.stats$mean$cv.support,
             y=boxcut.scaled[,1], type='n',
             xlim=range(0,1),
             ylim=range(boxcut.scaled),
             main="Covariate Importance (average values)", cex.main=cex,
             xlab="",
             ylab="")
        for (j in 1:p) {
            lines(x=object$cvfit$cv.stats$mean$cv.support,
                  y=boxcut.scaled[,j],
                  type='l', col=col.cov[j], lty=lty.cov[j], lwd=lwd.cov[j])
        }
        legend("topleft", inset=0.01, legend=varnames[toplot], col=col.cov, lty=lty.cov, lwd=lwd.cov, cex=cex)
        if (center)
            abline(h=0, lty=2, col=1, lwd=0.3, xpd=FALSE)
        if (add.legend)
            legend("bottom", inset=0.01, legend=text.legend, cex=cex)
        mtext(text=xlab, cex=cex, side=1, line=1, outer=FALSE)
        mtext(text=ylab, cex=cex, side=2, line=2, outer=FALSE)

        plot(x=object$cvfit$cv.stats$mean$cv.support,
             y=matchtrace,
             type='S', yaxt="n", col=col, lty=lty, lwd=lwd,
             xlim=range(0, 1),
             ylim=range(0, p),
             main="Covariate Usage (modal values)", cex.main=cex,
             xlab="",
             ylab="")
        par(mgp=c(1.5, 0, 0))
        axis(side=2, at=1:p, labels=ticknames, tick=FALSE, las=1, line=NA, cex.axis=cex, outer=FALSE)
        if (add.legend)
            legend("bottom", inset=0.01, legend=text.legend, cex=cex)
        mtext(text=xlab, cex=cex, side=1, line=1, outer=FALSE)
        mtext(text="Covariates Used", cex=cex, side=2, line=7, outer=FALSE)
        if (!is.null(main)) {
            mtext(text=main, cex=1, side=3, outer=TRUE)
        }
    }

    if (is.null(device)) {
        dev.new(width=width, height=height, title="Covariate Trace Plots", noRStudioGD = TRUE)
        boxtraceplot(object=object,
                     main=main, xlab=xlab, ylab=ylab,
                     toplot=toplot,
                     center=center, scale=scale,
                     col.cov=col.cov, lty.cov=lty.cov, lwd.cov=lwd.cov,
                     col=col, lty=lty, lwd=lwd,
                     cex=cex, add.legend=add.legend, text.legend=text.legend)
    } else if (device == "PS") {
        path <- normalizePath(path=paste(path, "/", sep=""), winslash="\\", mustWork=FALSE)
        file <- paste(file, ".ps", sep="")
        cat("\nOUTPUT: \n")
        cat("Filename : ", file, "\n")
        cat("Directory: ", path, "\n")
        postscript(file=paste(path, file, sep=""), width=width, height=height, onefile=TRUE, horizontal=horizontal)
        boxtraceplot(object=object,
                     main=main, xlab=xlab, ylab=ylab,
                     toplot=toplot,
                     center=center, scale=scale,
                     col.cov=col.cov, lty.cov=lty.cov, lwd.cov=lwd.cov,
                     col=col, lty=lty, lwd=lwd,
                     cex=cex, add.legend=add.legend, text.legend=text.legend)
        dev.off()
    } else if (device == "PDF") {
        path <- normalizePath(path=paste(path, "/", sep=""), winslash="\\", mustWork=FALSE)
        file <- paste(file, ".pdf", sep="")
        cat("\nOUTPUT: \n")
        cat("Filename : ", file, "\n")
        cat("Directory: ", path, "\n")
        pdf(file=paste(path, file, sep=""), width=width, height=height, onefile=TRUE, paper=ifelse(test=horizontal, yes="USr", no="US"))
        boxtraceplot(object=object,
                     main=main, xlab=xlab, ylab=ylab,
                     toplot=toplot,
                     center=center, scale=scale,
                     col.cov=col.cov, lty.cov=lty.cov, lwd.cov=lwd.cov,
                     col=col, lty=lty, lwd=lwd,
                     cex=cex, add.legend=add.legend, text.legend=text.legend)
        dev.off()
    } else {
        stop("Currently allowed display devices are \"PS\" (Postscript) or \"PDF\" (Portable Document Format) \n")
    }
  } else {
    cat("Either the covariate pre-selection or the Survival Bump Hunting modeling failed for this dataset.\n
        So, there is nothing to plot here.\n")
  }
  invisible()
}
##########################################################################################################################################





##########################################################################################################################################
################
# Usage         :
################
#                    plot_boxkm (object,
#                                main=NULL,
#                                xlab="Time", ylab="Probability",
#                                precision=1e-3, mark=3, col=2, cex=1,
#                                steps=1:object$cvfit$cv.nsteps,
#                                nr=3, nc=4,
#                                device=NULL, file="Survival Plots", path=getwd(),
#                                horizontal=TRUE, width=11.5, height=8.5, ...)
#
################
# Description   :
################
#
################
# Arguments     :
################
#
################
# Values        :
################
#
##########################################################################################################################################

plot_boxkm <- function(object,
                       main=NULL,
                       xlab="Time", ylab="Probability",
                       precision=1e-3, mark=3, col=2, cex=1,
                       steps=1:object$cvfit$cv.nsteps,
                       nr=3, nc=4,
                       device=NULL, file="Survival Plots", path=getwd(),
                       horizontal=TRUE, width=11.5, height=8.5, ...) {

  if (!inherits(object, 'PRSP'))
        stop("Primary argument much be an object of class 'PRSP' \n")

  if (object$plot) {

    boxkmplot <- function(object,
                          main, xlab, ylab,
                          precision, mark, col, cex,
                          steps, nr, nc, ...) {

        if (!is.null(main)) {
            par(mfrow=c(nr, nc), oma=c(0, 0, 3, 0), mar=c(2.5, 2.5, 1.5, 1.5), mgp=c(1.5, 0.5, 0))
        } else {
            par(mfrow=c(nr, nc), oma=c(0, 0, 0, 0), mar=c(2.5, 2.5, 0.0, 1.5), mgp=c(1.5, 0.5, 0))
        }

        times <- object$times
        status <- object$status
        L <- object$cvfit$cv.nsteps
        for (l in steps) {
            boxind <- object$cvfit$cv.boxind[l,]
            ng <- length(unique(boxind[!is.na(boxind)]))
            if (ng == 1) {
                boxind <- 1*boxind
            } else {
                boxind <- 2 - 1*boxind
            }
            surv <- survfit(Surv(times, status) ~ 1 + boxind)
            if (l == 1) {
                plot(surv, main="", conf.int=TRUE, mark.time=FALSE, mark=NA, lty=2, lwd=0.5, col=col, cex=cex, xlab=xlab, ylab=ylab, ...)
                par(new=TRUE)
                plot(surv, main="", conf.int=FALSE, mark.time=TRUE, mark=mark, lty=1, lwd=1, col=col, cex=cex, xlab=xlab, ylab=ylab, ...)
            } else {
                plot(surv, main="", conf.int=TRUE, mark.time=FALSE, mark=NA, lty=c(2,2), lwd=c(0.5,0.5), col=c(col,1), cex=cex, xlab=xlab, ylab=ylab, ...)
                par(new=TRUE)
                plot(surv, main="", conf.int=FALSE, mark.time=TRUE, mark=mark, lty=c(1,1), lwd=c(1,1), col=c(col,1), cex=cex, xlab=xlab, ylab=ylab, ...)
            }
            legend("topright", inset=0.01, legend=c("outbox", "inbox"), lty=c(1,1), lwd=c(1,1), col=c(1,2), cex=0.9*cex)
            if (object$cpv) {
                if (object$cvfit$cv.pval[l] <= precision) {
                    legend("bottom", inset=0.11, col="black", cex=0.9*cex, bty="n",
                           legend=bquote(italic(p) <= .(precision)))
                } else {
                    legend("bottom", inset=0.11, col="black", cex=0.9*cex, bty="n",
                           legend=bquote(italic(p) == .(format(x=object$cvfit$cv.pval[l], scientific=FALSE, digits=4, nsmall=4))))
                }
            }
            legend("bottom", inset=0.01, col="black", cex=0.9*cex, bty="n",
                   legend=substitute(group("", list(paste(italic(LHR) == x, sep="")), ""), list(x=format(x=object$cvfit$cv.stats$mean$cv.lhr[l], digits=3, nsmall=3))))
            legend("bottom", inset=0.06, col="black", cex=0.9*cex, bty="n",
                   legend=substitute(group("", list(paste(italic(LRT) == x, sep="")), ""), list(x=format(x=object$cvfit$cv.stats$mean$cv.lrt[l], digits=3, nsmall=3))))
            legend("bottom", inset=0.16, legend=paste("Step ", l-1, sep=""), col=1, cex=0.9*cex, bty="n")
        }

        if (!is.null(main)) {
            mtext(text=main, cex=1, side=3, outer=TRUE)
        }
    }

    if (is.null(device)) {
        dev.new(width=width, height=height, title="Survival Plots", noRStudioGD = TRUE)
        boxkmplot(object=object,
                  main=main, xlab=xlab, ylab=ylab,
                  precision=precision, mark=mark, col=col, cex=cex,
                  steps=steps,
                  nr=nr, nc=nc)
    } else if (device == "PS") {
        path <- normalizePath(path=paste(path, "/", sep=""), winslash="\\", mustWork=FALSE)
        file <- paste(file, ".ps", sep="")
        cat("\nOUTPUT: \n")
        cat("Filename : ", file, "\n")
        cat("Directory: ", path, "\n")
        postscript(file=paste(path, file, sep=""), width=width, height=height, onefile=TRUE, horizontal=horizontal)
        boxkmplot(object=object,
                  main=main, xlab=xlab, ylab=ylab,
                  precision=precision, mark=mark, col=col, cex=cex,
                  steps=steps,
                  nr=nr, nc=nc)
        dev.off()
    } else if (device == "PDF") {
        path <- normalizePath(path=paste(path, "/", sep=""), winslash="\\", mustWork=FALSE)
        file <- paste(file, ".pdf", sep="")
        cat("\nOUTPUT: \n")
        cat("Filename : ", file, "\n")
        cat("Directory: ", path, "\n")
        pdf(file=paste(path, file, sep=""), width=width, height=height, onefile=TRUE, paper=ifelse(test=horizontal, yes="USr", no="US"))
        boxkmplot(object=object,
                  main=main, xlab=xlab, ylab=ylab,
                  precision=precision, mark=mark, col=col, cex=cex,
                  steps=steps,
                  nr=nr, nc=nc)
        dev.off()
    } else {
        stop("Currently allowed display devices are \"PS\" (Postscript) or \"PDF\" (Portable Document Format) \n")
    }
  } else {
    cat("Either the covariate pre-selection or the Survival Bump Hunting modeling failed for this dataset.\n
        So, there is nothing to plot here.\n")
  }
  invisible()
}
##########################################################################################################################################


