#' # Introduction 

#' With the release of v1.0 of the `DataFrames.jl` package, it would seem appropriate to introduce a rather comprehensive cheatsheet of it. One that is of special use to people who come from `tidyverse` (arguably, the best data transformation syntax there is for combined expressiveness and brevity). 

#' The order of topics is the same as `dplyr` cheatsheet.

using RDatasets, RCall, DataFrames, StatsBase, InteractiveErrors

R"library(dplyr)"

#' ## Setting up the data using RCall

data = dataset("datasets", "iris")

@rput data;


#' ## Summarize Cases

#' ### `summarize`

R"summarize(data, avSL = mean(SepalLength), avSW = mean(SepalWidth))"

combine(data, [:SepalLength, :SepalWidth] .=> mean .=> [:avSL, :avSW])

#' There are two important things to note. Firstly, broadcasting is mandatory. Secondly, the syntax allows for one factoring of the function in the middle. 

#' Now let us summarize by different functions:

combine(data, [:SepalLength, :SepalWidth] .=> [maximum, minimum] .=>
        [:maxSL, :minSW])

#' And with anonymous functions:

combine(data, [:SepalLength, :SepalWidth] .=> 
        [x->sum(x./100), x->sum(sqrt.(x))] .=> [:x1, :x2])

#' The r equivalent would be:

R"""
summarize(data, x1=sum(SepalLength/100), x2=sum(sqrt(SepalWidth)))
"""

#' The reason that r is often-times nicer is quotation. With DataFrames.jl on the other hand, the idea is to simply pass the actual data and data identifiers around. This means greater flexibility but slightly more verbose syntax.

#' For instance, consider summarizing by matching column names:

combine(data, filter(x->occursin.("Sepal", x), names(data)) .=> mean)

#' In R, one needs to explicitly use other function to escape the quoting procedure:

R"""
summarize(data, across(contains("Sepal"), mean))
"""

#' Both have their ups and downs. Basically, the field of nonstandard evaluation will require its own functions, whereas, by avoiding that, one can rely on existing functions or at least only slightly modified functions (based on multiple dispatch for instance) to arrive at the desired results.

#' ### `count`

data = dataset("ggplot2", "mpg")

@rput data;

#+echo=false
#' ##

R"""
count(data, Cyl, Drv)
"""

#' Any function that operates on (sub)dataframes can be used immediately (nrow here):

combine(groupby(data, [:Cyl, :Drv], sort = true), nrow)

#' This was a proper interlude to the next topic, grouping.

#' ## Group Cases

#' ### Ungroup

#' The general grouping operation in DataFrames.jl is as above, whereby a "sub" dataframe is recognized, perhaps not overly different from views in arrays.

#' Ungrouping is done rather automatically. The default value of `ungroup` in the transformation functions is `true`.

df = groupby(data, [:Cyl, :Drv], sort = true) 

df2 = combine(df, :)

#' It is important to note that presently, grouping changes the row order.

#' In r, use of the `ungroup` function is needed.

#' ### Row-wise operation

#' Row-wise is, conceptually, setting each row as its own group. Nevertheless, oftentimes we do not need to think this way.

#' Say you want to know the minimum between 1.5 times the city miles per gallon and highway miles per galon for each model. In r, it would require this:

R"""
data %>% rowwise() %>% mutate(maxy = max(1.5*Cty, Hwy)) %>% 
    select(maxy, everything())
"""

#' In Julia, it is simply a matter of specifying the operation itself to rowwise:

transform(data, [:Cty, :Hwy] => ByRow((x,y)->max(1.5*x,y)) => :maxy) |> 
x->x[:, Cols([:maxy], :)]

#' ## Manipulate Cases

#' ### Filter

#' Filtering essentially uses the same principles as applied to any other Julia data structure, and can even use the conventional `filter` function for this purpose:

filter(:Cty => x->(x>20), data)[:, Cols(:Cty,:)]

#' Julia data collection functions usually take a function as the first argument in order to facilitate the use of `do` blocks. This doesn't look nice when using piping. Therefore, my suggestion is to stick with the `subset` function. Besides, apparently, `filter` doesn't work on data groups.

subset(data, :Cty => x->(x.>20))[:, Cols(:Cty,:)] 

#' ### Distinct

unique(data, [:Cyl, :Drv])

R"""
distinct(data, Cyl, Drv)
"""

#' ### Slice

#' The point of a function such as `slice` is to be used in pipes really. Otherwise one can simply do this:

R"""
data[4:10,]
"""

#' Same with julia:

data[4:10,:]

#' ### Slice-sample

#' The StatsBase module can be used here.

data[rand(1:nrow(data), 10),:]

#' ### Slice min and max

#' This is just a convenience function:

data[data.Cty .>= quantile(data.Cty, 0.75),:]

#' The R code:

R"""
slice_max(data, Cty, prop = 0.25)
"""

#' ### Slice head and tail

#' again, mostly meaningful for pipes. Nevertheless:

data[end-5:end,:]

#' ### Arrange

#' Instead of arrange, `sort` is used. The syntax is very clear:

sort(data, [order(:Year, rev=true), :Displ])

R"""
arrange(data, desc(Year), Displ)
"""

#' One can in fact use any kind of sorting. See the sorting section in DataFrames.jl.

#' ### Adding row at position

#' Again, this is just a convenience function. Let's add a duplicate row for instance:

vcat(data, DataFrame(data[5,:]))

#' The issue is that specifying the position at which to insert the row can take extra work. See also `append!` and `push!` with the catch being modification of the original dataframe. 

#' ## Extract variables

#' Conventional indexing can be used:

#' ### pull

#' One can just use the fact that the dataframe is a collection of vectors in a dictionary-like relation:

data.Hwy

R"pull(data, Hwy)"

#' ### select

data[:, [:Hwy, :Cty]]

#' Note that when selecting only a single column, it is no different than the dot syntax and the return structure is not dataframe:

data[:, :Hwy]

#' Of course, wrapping in vector the column symbol gives the desired result:

data[:, [:Hwy]]

#' ### relocate

#' Just use `Cols` as before. For instance, to put columns starting with m at front:

data[:, Cols(filter(x->occursin(r"^[mM].*", x), names(data)),
    :Year, :Class, :)]

#' To put Model after Year:

data[:, Cols( setdiff(propertynames(data), [:Model]) |> x->insert!(x,
    findfirst(x .== :Year) + 1, :Model))]

R"""
relocate(data, Model, .after = Year)
"""

#' Currently, there aren't any helper functions for selection, though the general procedure isn't that verbose in base Julia either.

#' ## Across function

#' As mentioned in the beginning, Julia provides quite flexible ways of combining data, and there is no need for extra across functions, mainly due to the employment of the broadcasting concept. 

#' ## Making new variables

#' ### mutate, and transmutate

#' The mutate equivalent is transform. The select function is the transmutate equivalent, which only selects the specifided columns, and after applying the specified functions, returns only said columns.  

#' ### rename

rename(data, [:Model, :Year] .=> [:type, :date])

#' ## Vectorized Functions
