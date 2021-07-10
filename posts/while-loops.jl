#' ---
#' title: 'Julia Frustrations and Fixes Part III: Do-While Loops'
#' date: 2021-07-10
#' categories: [programming]
#' tags: [julia]
#' ---

#' # Simple Iterations

#' The goal is to solve the below expression iteratively for f(x):

#' $$
#' f(x) = β\left(f(x)+x\right)
#' $$

#' Of course, we know what the answer is already, for comparison:

β = 0.8
f(x) = 1/(1-β)*β*x

x = 0.1:0.1:10;

#' ## The original way

#' Using a while loop can be ugly, since there isn't a do-while syntax in Julia. One needs to specify a `true` case first and check convergence later:

fcomp, iter = let v_ = zeros(length(x)), i = 0
    while true 
        v = β*(v_+x)
        i=i+1
        maximum(abs.(v-v_)) < 1e-6 && break
        v_ = v
    end
    (v_,i)
end

[f.(x) fcomp]
#+
iter

#' ## Without while loop

#' As a solution, we can adopt a more functional approach to the recursive problem. Below code is more clear on what it's supposed to do, with the default case mentioned first, and what needs to be done otherwise, later. As for initialization, the function takes care of this task itself in the last line:

function viterate(x, v0)
    viterate(v, v_, iter) = maximum(abs.(v-v_)) < 1e-6 ? (v, iter) :
    let v_ = v, v = β*(v_+x)
        viterate(v, v_, iter+1)
    end
    viterate(β*(v0+x), v0, 1)
end
fcomp2, iter2 = viterate(x, zeros(length(x)))

[f.(x) fcomp2]
#+
iter2
