#' ---
#' title: 'dplyr Cheatsheet to DataFrames.jl Page 2'
#' date: 2021-11-13
#' categories: [programming]
#' tags: [julia, R]
#' ---

#' # Continuing Where We Left

#' This post shows how to translate the second page of the `dplyr` cheatsheet to `DataFrames.jl` and Julia commnads.

using RDatasets, RCall, DataFrames, StatsBase, Statistics

R"library(tidyverse)";


#' ## Setting up the data using RCall

mpg = dataset("ggplot2", "mpg");

#' ## Vectorized Functions

#' ### `lag`, `lead`

#+term=true
R"""
mutate(mpg, leadyear = lead(year)) %>% select(year, leadyear) %>% tail
"""
#' In Julia:

#+term=true
transform(mpg, :Year => (x->vcat(x[2:end], missing)) => :leadYear)[
    :, [:Year, :leadYear]] |> x->last(x, 10)

#' Note that one needs to wrap the anonymous function inside parentheses to avoid mixing with the `=>` operator. 

#' ### `cumall`

#' This function returns always false from the first false value it sees. For example:

#+term=true
R"""
x <- c(1, 3, 5, 9, 4, 3, 2, 2)
cumall(x < 6)
"""

#' This is just a commulative product for logical values:

#+term=true
x = [1, 3, 5, 9, 4, 3, 2, 2];
cumprod(x .< 6)'

#' ### `cumany`

#' This one returns true from the first true it sees:

#+term=true
R"""
cumany(x > 6)
"""

#' It would be equivalent to a logical sum:

#+term=true
cumsum(x .> 6)'

#' ### `cummax`

#' This just takes binary comparisons between the present element and its previous element:

#+term=true
R"cummax(x)"

#' It is easy with the more general function `accumulate` in Julia:

#+term=true
accumulate(max, x)'

#' One could have in fact used this function with the previous examples as well by writing the appropriate anonymous function. Other functions such as `mean`, `max` etc. follow the same rule.

#' ### Rank functions

#+term=true
R"cume_dist(x)"

#' It is just the values of the empirical cdf:

#+term=true
ecdf(x)(x)'

#+term=true
R"dense_rank(x)"

#+term=true
denserank(x)'

#+term=true
R"min_rank(x)"

#' Julia equivalent is the `competerank`:

#+term=true
competerank(x)'

#' TODO The `dplyr` `ntile` function seems rather unstandard and so the results differ from Julia:

#+term=true
R"ntile(x, 3)"

#+term=true
searchsortedfirst.(Ref(nquantile(x,2)), x)'

#' As for `percen_rank` it is just a normalization to the 0-1 interval, hence requires subtracting 1 first:

#+term=true
R"percent_rank(x)"

#+term=true
((competerank(x).-1)/(length(x)-1))'

#' As for `row_number` rank:

#+term=true
R"row_number(x)"

#+term=true
ordinalrank(x)'

#' ### `between`

#' Julia simply understands the between notion in a mathematical notation:

#+term=true
R"between(x, 3, 6)"

#+term=true
(3 .<= x .<= 6)'

#' ### `near`

#' Use the approximate notation (or the `isapprox` function):

#+term=true
R"near(2, 1.9999999999)"

#+term=true
2 ≈ 1.9999999999

#' ### `case_when`

#' Julia doesn't have a syntax for cases yet. The shortest equivalent that comes to mind is as follows:

#+term=true
R"""
case_when(x > 3 & x < 5 ~ "medium",
          x <= 3 ~ "small",
          x >= 5 ~ "large",
          TRUE ~ "unknown")
"""

#+term=true
map(x) do x_
    if (3 < x_ < 5) "medium"
    elseif (x_ <= 3) "small"
    elseif (5 <= x_) "large"
    else "unknown"
    end
end

#' ### `coalesce`

#' Both functions are inspired by the SQL command and so work nearly identically:

#+term=true
R"""
y <- c(NA, 2, 5, NA, 6)
z <- c(3, 7, NA, 9, 4)
coalesce(y,z)
"""

#+term=true
y = [missing, 2, 5, missing, 6];
z = [3, 7, missing, 9, 4];
coalesce.(y, z)'

#' It is important to note that vectorizing coalesce (i.e. the dot) is necessary. Otherwise, since the `y` *vector* isn't missing, nothing happens.

#' ### `if_else`

#' The julia equivalent is the vectorized `ifelse`:

#+term=true
R"""
if_else(x > 3, "large", "small")
"""

#+term=true
ifelse.(x .> 3, "large", "small")

#' ### `na_if`

#' Simply use the more general functions in Julia:

#+term=true
R"na_if(x, 9)"

#+term=true
replace(x, 9=>missing)'

#' ### `pmax` and `pmin`

#+term=true
R"pmax(y,z)"

#+term=true
max.(y,z)'

#' ### `recode`

#' Again, simply using the more general function `replace`:

#+term=true
R"""
cvec <- c("a", "b", "a", "c", "b", "a", "c")
recode(cvec, a = "apple")
"""

#+term=true
cvec = ["a", "b", "a", "c", "b", "a", "c"];
replace(cvec, "a"=>"apple")

#' ## Summary Functions

#' Back to dataframes where summary functions are better illustrated.

#' ### `n()`

#+term=true
R"mpg %>% group_by(cyl) %>% summarise(n=n())"

#+term=true
groupby(mpg, :Cyl) |> x->combine(x, nrow)

#' ### `n_distinct`

#+term=true
R"mpg %>% group_by(cyl) %>% summarise(trans=n_distinct(trans))"

#+term=true
groupby(mpg, :Cyl) |> x->combine(x, :Trans => 
    (x_->length(unique(x_))) => :Trans)

#' Alternatively, one could just composition the two inner functions instead (use \circ to write the operator):

#+term=true
groupby(mpg, :Cyl) |> x->combine(x, :Trans => length ∘ unique => :Trans)

#' ### `mean` and `median`

#+term=true
R"mean(x)"

#+term=true
mean(x)

#+term=true
R"median(x)"

#+term=true
median(x)

#' ### `first`, `last`, `nth`

#' The Julia equivalents are also named first and last. As for `nth`, one has to simply use array indexing.

#' ### Rank and Spread functions

#' These are all available in Julia by similar names:

#+term=true
R"c(max(x), min(x), quantile(x, 0.25), IQR(x), mad(x), sd(x), var(x))"

#+term=true
[maximum(x); minimum(x); quantile(x, 0.25); iqr(x); mad(x); std(x); var(x)]'

#' ## Row Names

#' Julia dataframes do not have row names by design so there is nothing to worry about here.

#' ## Combining Tables

#' Combining tables is really easy in Julia and is similar to how it is done in R for the most part (since both are inspired by SQL verbs).

#' ### Column and row binding

#' Binding columns is done with the `hcat` function:

#+term=true
R"""
df1 <- tibble(a = 1:3, b = 4:6)
df2 <- tibble(c = 7:9, d = 10:12)
bind_cols(df1, df2)
"""

#+term=true
df1 = DataFrame(a=1:3, b=4:6);
df2 = DataFrame(c=7:9, d=10:12);
hcat(df1, df2)

#' Binding rows requires vcat:

#+term=true
R"""
df1 <- tibble(a = 1:3, b = 4:6)
df2 <- tibble(a = 7:9, b = 10:12)
bind_rows(df1, df2)
"""

#+term=true
df1 = DataFrame(a=1:3, b=4:6);
df2 = DataFrame(a=7:9, b=10:12);
vcat(df1, df2)

#' ### Joins

#' Example data taken from `DataFrames.jl`:

#+term=true
df1 = DataFrame(City = ["Amsterdam", "London", "London", "New York", "New York"],
                     Job = ["Lawyer", "Lawyer", "Lawyer", "Doctor", "Doctor"],
                     Category = [1, 2, 3, 4, 5]);
df2 = DataFrame(Location = ["Amsterdam", "London", "London", "New York", "New York"],
                     Work = ["Lawyer", "Lawyer", "Lawyer", "Doctor", "Doctor"],
                     Name = ["a", "b", "c", "d", "e"]);
innerjoin(df1, df2, on = [:City => :Location, :Job => :Work])

#' In R, it would be:

#+term=true
R"""
df1 <- tibble(City = c("Amsterdam", "London", "London", "New York", "New York"),
                     Job = c("Lawyer", "Lawyer", "Lawyer", "Doctor", "Doctor"),
                     Category = c(1, 2, 3, 4, 5))
df2 <- tibble(Location = c("Amsterdam", "London", "London", "New York", "New York"),
                     Work = c("Lawyer", "Lawyer", "Lawyer", "Doctor", "Doctor"),
                     Name = c("a", "b", "c", "d", "e"))
inner_join(df1, df2, by = c("City" = "Location", "Job" = "Work"))
"""

#' Set operations in R are somewhat redunant in the presence of join verbs, and so in Julia one needs to rely soley on those join verbs.

#' This concludes the `dplyr` cheatsheet translation to `DataFrames.jl` commands.

#+echo=false
