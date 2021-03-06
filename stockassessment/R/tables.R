##' Table helper 
##' @param fit returned object from sam.fit
##' @param what quoted name of what to extract
##' @param x rownames of table
##' @param trans function to be applied
##' @param ... extra arguments not currently used
##' @details ...
tableit <-function (fit, what, x=fit$data$years, trans=function(x)x,...){
    UseMethod("tableit")
}
##' @rdname tableit
##' @method tableit sam
##' @export
tableit.sam <- function (fit, what, x=fit$data$years, trans=function(x)x,...){
   idx<-names(fit$sdrep$value)==what
   y<-fit$sdrep$value[idx]
   ci<-y+fit$sdrep$sd[idx]%o%c(-2,2)
   ret<-trans(cbind(y,ci))
   rownames(ret)<-x
   colnames(ret)<-c("Estimate","Low","High")
   return(ret)
}

##' SSB table 
##' @param  fit ...
##' @param ... extra arguments not currently used
##' @details ...
##' @export
ssbtable<-function(fit,...){
    UseMethod("ssbtable")
}
##' @rdname ssbtable
##' @method ssbtable default
##' @export
ssbtable.default <- function(fit,...){
   ret<-tableit(fit, "logssb", trans=exp,...)
   return(ret)
}

##' TSB table 
##' @param  fit ... 
##' @param ... extra arguments not currently used
##' @details ...
##' @export
tsbtable<-function(fit,...){
    UseMethod("tsbtable")
}
##' @rdname tsbtable
##' @method tsbtable default
##' @export
tsbtable.default <- function(fit,...){
   ret<-tableit(fit, "logtsb", trans=exp,...)
   return(ret)
}

##' Fbar table 
##' @param  fit ... 
##' @param ... extra arguments not currently used
##' @details ...
##' @export
fbartable<-function(fit,...){
    UseMethod("fbartable")
}
##' @rdname fbartable
##' @method fbartable default
##' @export
fbartable.default <- function(fit,...){
   ret<-tableit(fit, "logfbar", trans=exp)
   return(ret)
}

##' Recruit table 
##' @param  fit ... 
##' @param ... extra arguments not currently used
##' @details ...
##' @export
rectable<-function(fit){
    UseMethod("rectable")
}
##' @rdname rectable
##' @method rectable default
##' @export
rectable.default <- function(fit,...){
   ret<-tableit(fit, "logR", trans=exp)
   return(ret)
}

##' Catch table 
##' @param  fit ...
##' @param obs.show logical add a column with catch sum of product rowsums(C*W)
##' @param ... extra arguments not currently used
##' @details ...
##' @export
catchtable<-function(fit, obs.show=FALSE,...){
    UseMethod("catchtable")
}
##' @rdname catchtable
##' @method catchtable sam
##' @export
catchtable.sam <- function(fit, obs.show=FALSE,...){
   CW <- fit$data$catchMeanWeight 
   xx <- as.integer(rownames(CW))
   ret <- tableit(fit, x=xx, "logCatch", trans=exp)
   if(obs.show){
     aux <- fit$data$aux
     logobs <- fit$data$logobs
     .goget <- function(y,a){
       ret <- exp(logobs[aux[,"fleet"]==1 & aux[,"year"]==y & aux[,"age"]==a])
       ifelse(length(ret)==0,0,ret)
      }
      sop<-rowSums(outer(rownames(CW), colnames(CW), Vectorize(.goget))*CW, na.rm=TRUE)
      ret<-cbind(ret,sop.catch=sop)
   }
   return(ret)
}

##' N table 
##' @param  fit ... 
##' @param ... extra arguments not currently used
##' @details ...
##' @export
ntable <- function(fit,...){
    UseMethod("ntable")
}
##' @rdname ntable
##' @method ntable sam
##' @export
ntable.sam <- function(fit,...){
   ret <- exp(t(fit$pl$logN))
   colnames(ret) <- fit$conf$minAge:fit$conf$maxAge
   rownames(ret) <- fit$data$years
   return(ret)
}

##' F-at-age table 
##' @param  fit ... 
##' @param ... extra arguments not currently used
##' @details ...
##' @export
faytable <- function(fit,...){
    UseMethod("faytable")
}
##' @rdname faytable
##' @method faytable sam
##' @export
faytable.sam <- function(fit,...){
   idx <- fit$conf$keyLogFsta[1,]+2    
   ret <- cbind(NA,exp(t(fit$pl$logF)))[,idx]
   ret[,idx==0] <- 0
   colnames(ret) <- fit$conf$minAge:fit$conf$maxAge
   rownames(ret) <- fit$data$years
   return(ret)
}

##' parameter table 
##' @param  fit ... 
##' @param ... extra arguments not currently used
##' @details ...
##' @export
partable <- function(fit,...){
    UseMethod("partable")
}
##' @rdname partable
##' @method partable sam
##' @export
partable.sam <- function(fit,...){
  param <- coef(fit)
  nam <- names(param)
  dup <- duplicated(nam)
  namadd <- rep(0, length(nam))
  for (i in 2:length(dup)) {
    if(dup[i])namadd[i] <- namadd[i - 1] + 1
  }
  nam <- paste(nam, namadd, sep = "_")
  ret<-cbind(param, attr(param,"sd"))
  ex<-exp(ret[,1])
  lo<-exp(ret[,1]-2*ret[,2])
  hi<-exp(ret[,1]+2*ret[,2])
  ret<-cbind(ret,ex,lo,hi)
  colnames(ret)<-c("par", "sd(par)", "exp(par)", "Low", "High")
  rownames(ret)<-nam
  return(ret)
}

##' model table 
##' @param fits A sam fit as returned from the sam.fit function, or a collection c(fit1, fit2, ...) of such fits  
##' @param ... extra arguments not currently used
##' @details ...
##' @importFrom stats AIC pchisq
##' @export
modeltable <- function(fits,...){
    UseMethod("modeltable")
}
##' @rdname modeltable
##' @method modeltable sam
##' @export
modeltable.sam <- function(fits,...){
    modeltable(c(fits))
}
##' @rdname modeltable
##' @method modeltable samset
##' @export
modeltable.samset <- function(fits,...){
    if(!is.null(attr(fits,"fit"))){
      fits[[length(fits)+1]] <- attr(fits,"fit")
      fits <- fits[c(length(fits),1:(length(fits)-1))]
    }
    fits <- fits[!sapply(fits, is.null)]
    if(is.null(names(fits))){
        nam <- paste("M", 1:length(fits), sep="")
    }else{
        nam <-ifelse(names(fits)=="",paste("M", 1:length(fits), sep=""), names(fits))
    }
    logL <- sapply(fits, logLik)
    npar <- sapply(fits, function(f)attr(logLik(f),"df"))
    aic <- sapply(fits, AIC)
    res <- cbind("log(L)"=logL, "#par"=npar, "AIC"=aic)
    rownames(res) <- nam
    o <- 1:length(fits)
    if(length(fits)==2){
        o <- order(npar, decreasing=TRUE)
        if(npar[o[1]]>npar[o[2]]){
            df <- npar[o[1]]>npar[o[2]]
            D <- 2*(logL[o[1]]-logL[o[2]])
            P <- 1-pchisq(D,df)
            cnam <- paste0("Pval( ",nam[o[1]]," -> ",nam[o[2]], " )")
            res <- cbind(res, c(NA, P)[o])
            colnames(res)[ncol(res)] <- cnam
        }
    }
    return(res[o,,drop=FALSE])
}

##' Yield per recruit calculation
##' @param fit the object returned from sam.fit
##' @param Flimit Upper limit for Fbar
##' @param Fdelta increments on the Fbar axis 
##' @param aveYears Number of years back to use when calculating averages (selection, weights, ...)
##' @param ageLimit Oldest age used (should be high)
##' @param ... extra arguments not currently used
##' @export
ypr<-function(fit, Flimit=2, Fdelta=0.01, aveYears=min(15,length(fit$data$years)), ageLimit=100,...){
    UseMethod("ypr")
}
##' @rdname ypr
##' @method ypr sam
##' @export
ypr.sam <- function(fit, Flimit=2, Fdelta=0.01, aveYears=min(15,length(fit$data$years)), ageLimit=100,...){
  barAges <- do.call(":",as.list(fit$conf$fbarRange))+(1-fit$conf$minAge) 
  last.year.used=max(fit$data$years)
  idxno<-which(fit$data$years==last.year.used)
  #dim<-fit.current$stateDim
  #idxN<-1:ncol(stock.mean.weight) 
  F <- t(faytable(fit))
  F[is.na(F)]<-0
  
  sel<-function(){
    Sa<-rep(0,nrow(F))
    K<-0
    for(i in 0:(aveYears-1)){
      thisF<-F[,idxno-i]
      Sa<-Sa+thisF
      K<-K+fbartable(fit)[idxno-i]
    }
    return(Sa/K)
  }

  extend<-function(x,len=100){
    ret<-numeric(len)
    ret[1:length(x)]<-x
    ret[-c(1:length(x))]<-x[length(x)]
    ret
  }

  ave.sl<-sel()
  ave.sw<-colMeans(fit$data$stockMeanWeight[(idxno-aveYears+1):idxno,,drop=FALSE])
  ave.cw<-colMeans(fit$data$catchMeanWeight[(idxno-aveYears+1):(idxno-1),,drop=FALSE])
  ave.pm<-colMeans(fit$data$propMat[(idxno-aveYears+1):idxno,,drop=FALSE])
  ave.nm<-colMeans(fit$data$natMor[(idxno-aveYears+1):idxno,,drop=FALSE])
  ave.lf<-colMeans(fit$data$landFrac[(idxno-aveYears+1):(idxno-1),,drop=FALSE])
  ave.cw.land<-colMeans(fit$data$landMeanWeight[(idxno-aveYears+1):(idxno-1),,drop=FALSE])

  N<-numeric(ageLimit)
  N[1]<-1.0
  M<-extend(ave.nm)
  sw<-extend(ave.sw)
  cw<-extend(ave.cw.land)
  pm<-extend(ave.pm)
  lf<-extend(ave.lf)
 
  deltafirst <- 0.00001
  delta <- Fdelta
  scales<-c(0, deltafirst, seq(0.01, Flimit, by=delta))
  yields<-numeric(length(scales))
  ssbs<-numeric(length(scales))
  for(i in 1:length(scales)){
    scale<-scales[i]
    F<-extend(ave.sl*scale)
    Z<-M+F
    for(a in 2:length(N)){
      N[a]<-N[a-1]*exp(-Z[a-1])  
    }
    C<-F/Z*(1-exp(-Z))*N*lf  
    Y<-sum(C*cw)
    yields[i]<-Y
    ssbs[i]<-sum(N*pm*sw)
  }

  fmaxidx<-which.max(yields)
  fmax<-scales[fmaxidx]

  deltaY<-diff(yields)
  f01idx<-which.min((deltaY/delta-0.1*deltaY[1]/deltafirst)^2)+1
  f01<-scales[f01idx]

  f35spridx<-which.min((ssbs-0.35*ssbs[1])^2)+1
  f35<-scales[f35spridx]
  
  fbarlab <- substitute(bar(F)[X - Y], list(X = fit$conf$fbarRange[1], Y = fit$conf$fbarRange[2]))
  ret<-list(fbar=scales, ssb=ssbs, yield=yields, fbarlab=fbarlab, f35=f35, f01=f01, fmax=fmax, 
            f35Idx=f35spridx, f01Idx=f01idx, fmaxIdx=fmaxidx)
  class(ret)<-"samypr"
  return(ret)
}
