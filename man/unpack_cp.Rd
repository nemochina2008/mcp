% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_segment_table.R
\encoding{UTF-8}
\name{unpack_cp}
\alias{unpack_cp}
\title{Takes a cp formula (as a string) and returns its properties}
\usage{
unpack_cp(form_cp, i)
}
\arguments{
\item{form_cp}{Segment formula as string.}

\item{i}{The segment number (integer)}
}
\value{
A one-row tibble with columns:
\itemize{
\item \code{cp_int}: bool. Whether there is an intercept change in the change point.
\item \code{cp_in_rel}: bool. Is this intercept change relative?
\item \code{cp_ran_int}: bool or NA. Is there a random intercept on the change point?
\item \code{cp_group_col}: char or NA. Which column in data define the random intercept?
}
}
\description{
Takes a cp formula (as a string) and returns its properties
}
\author{
Jonas Kristoffer Lindeløv \email{jonas@lindeloev.dk}
}
\keyword{internal}
