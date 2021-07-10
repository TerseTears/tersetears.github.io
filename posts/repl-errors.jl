#' ---
#' title: 'Julia Frustrations and Fixes Part I: REPL Errors'
#' date: 2021-07-07
#' categories: [programming]
#' tags: [julia]
#' ---

#' # Main issue

#' An issue with the REPL workflow is that When sending a script (or any chunks) to the REPL, lines that produce error simply output that error and the REPL simply continues to execute the following lines. This can be quite problematic since we may not know why something isn't working. Consider this example:

#' ## Error output

y = 5
y = y^x
# ERROR: UndefVarError: x not defined

#+
map(x->x, 1:100) 

#+
z = y

#' ## Interactive errors

#' The way to solve this issue is to use the `InteractiveErrors` package, which halts the REPL until further action is taken:

using InteractiveErrors

y = y^x
# REPL halts at above, waiting for user input

#+
# ...
# once input is received, it continues
z = y;

