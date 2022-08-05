#' ---
#' title: 'Short Comparison of Julia Optimization Frameworks'
#' date: 2022-08-05
#' categories: [programming, optimization]
#' tags: [julia, JuMP, Optimization]
#' ---

#' # Introduction

#' This is a short comparison of the mathematical optimization facilities of
#' the Julia language, where I compare
#' [JuMP.jl](https://github.com/jump-dev/JuMP.jl),
#' [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl), and
#' [Optimization.jl](https://github.com/SciML/Optimization.jl) libraries.

using JuMP
using Optim
using Optimization
using OptimizationOptimJL
using OptimizationNLopt
using BenchmarkTools

import Ipopt
import NLopt


# Booth function. The three frameworks require different specifications.
booth(x1, x2)  = (x1 + 2x2 - 7)^2 + (2x1 + x2 -5)^2 
booth_vector(x)  = (x[1] + 2x[2] - 7)^2 + (2x[1] + x[2] -5)^2 
booth_parameters(x, p)  = (x[1] + 2x[2] - 7)^2 + (2x[1] + x[2] -5)^2;

#' # JuMP.jl Implementation

model = Model()
set_silent(model)

@variable(model, x[1:2])

register(model, :booth, 2, booth; autodiff = true)

@NLobjective(model, Min, booth(x[1], x[2]))

#' ## Ipopt.jl

set_optimizer(model, Ipopt.Optimizer)
@benchmark JuMP.optimize!($model)

#' Ipopt really is not a good substitute for the native Julia implementation of
#' Optim.jl. Nevertheless, the same algorithms implemented by Optim.jl can be
#' found in the NLopt.jl package as bindings to implementations in other
#' languages.

#' ## NLopt.jl

set_optimizer(model, NLopt.Optimizer)
set_optimizer_attribute(model, "algorithm", :LD_LBFGS)
@benchmark JuMP.optimize!($model)

#' # Optim.jl

@benchmark Optim.optimize($booth_vector, [0., 0.], LBFGS(); autodiff = :forward)

#' There is an interesting pull request to implement an Optim.jl interface for
#' JuMP [here](https://github.com/JuliaNLSolvers/Optim.jl/pull/929). It would
#' be interesting to compare the benchmarks once Optim becomes accessible from
#' JuMP. For now, the almost 100 times slower speed may be attributed to either
#' slower implementation in NLopt or the huge overhead of JuMP modeling.
#' Alternatively, we can use another wrapper over optimization libraries, the
#' Optimization.jl library.

#' # Optimization.jl

optf = OptimizationFunction(booth_parameters, Optimization.AutoForwardDiff())
prob = OptimizationProblem(optf, [0., 0.])
@benchmark solve($prob, LBFGS())

#' There is clearly an overhead to using Optimization.jl making it more than
#' two times slower than using Optim.jl natively.

#' ## NLopt

@benchmark solve($prob, NLopt.LD_LBFGS())

#' Comparing the result with JuMP, one can conclude that the overheads in JuMP
#' and Optimization.jl seem to be on the same level. The poorer benchmark
#' results can therefore be attributed to NLopt.jl or the packages it wraps.

#' Another great thing about Optimization.jl is that it interfaces with the
#' [ModelingToolkit.jl](https://github.com/SciML/ModelingToolkit.jl)
#' package pretty well as well.


#' # Which Framework to Choose

#' It is true that the Optim.jl may not really be a framework per se.
#' Nevertheless, its raw speed makes it a great choice for embedding it in
#' analyses where optimization may be the bottleneck. Such as calling an
#' optimization routine in a long loop or matching and estimation.

#' On the other hand, a framework such as Optimization.jl, despite the added
#' overhead, provides great convenience especially in situations where the
#' function to be optimized is subject to rapid changes (such as testing
#' modeling approaches), allowing one to quickly switch between different
#' optimization methods with easy syntax.

#' Personally, I think JuMP is best for a single optimization problem, perhaps
#' large-scaled, with many underlying considerations, such as done in the
#' [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl)
#' package. It is just not as easy to prototype a model using
#' JuMP because of the sort of global approach it takes to modeling (a
#' single model that is to be modified using macros). I see the
#' Optimization.jl package as the framework with the greatest flexibility
#' whose syntax does not deviate greatly from Julia Base, despite remaining
#' highly extensible.
