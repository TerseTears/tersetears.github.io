#' ---
#' title: 'Julia Frustrations and Fixes Part II: Clearing Variables'
#' date: 2021-07-09
#' categories: [programming]
#' tags: [julia]
#' ---

#' # Main Issue

#' Variables kept from previous runs of a script can be the culprit behind all sorts of bugs when developing from the REPL. Consider this simple case:

#' ## Simple example

#' Let's say I define y somewhere in the code:

y = 50

#' Now I define another function that really is supposed to just sum two values, but I forgot to also change the name of the second variable in the function call:

function mysum(x,z)
    x + y
end
mysum(5,6)

#' If at this point, I would have been able to unset the value of y, I would have immediately gotten an error from the compiler. 

#' Now, imagine how REPL (read interactive) development works. That value definition is somewhere at the top of the script. Between the function definition and that value assignment are likely many edited lines. The function itself is quite likely much more complex than a simple sum, and the result, due to lines preceding the function definition, are not always constant. It might even be impossible to notice this bug without restarting Julia in the first place. And restarting Julia, well, is going to mean recompiling all those loaded packages. All in all, not a very REPL-development-friendly situation.  

#' ## Fix for Julia <= 1.6

#' It might be that a solution to this problem will be eventually (re)implemented in Julia. For now, this is how I deal with it:

#' The command `names(Main)` lists all the values used in the current REPL environment:

names(Main)

#' The `Main` module always has the first four elements plus an additional `ans` element that is produced as the return value of any operation that is carried in the REPL. Even in a REPL environment where no other commands have yet been executed, executing the above command alone produces this value. I rarely reference `ans` so for my purposes, keeping only the first four elements of `Main` is a complete cleaning of the environment.

p = 50
q = 50
d = 50;

#' To remove assigned variable value, a bit of metaprogrammming is necessary, since we'd need the left hand side of the assignment as well. 

macro unassign(variables...)
    unassigns = map(x->:($(esc(x)) = nothing), variables) 
    quote $(unassigns...) end
end
@unassign p q

(p,q)

#' To remove all variables from the environment, it is sufficient to notice that the first four elements of `Main` are constant. Moreover, other constant elements of the module (such as macros and functions symbols) cannot be reassigned in Julia. In other words, we can only un-assign variables for non-constant Julia symbols, hence the `setdiff` part.

function clearvars()
    unassignexprs = quote 
        $(map(x->:($(x) = nothing), 
              setdiff(names(Main), 
                      names(Main)[isconst.(Ref(Main), names(Main))]))...) 
    end
    @eval $(unassignexprs)
end
clearvars()

(d,y)

