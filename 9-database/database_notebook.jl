### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ 947be178-0b89-46b6-aa74-383e38bf903e
begin
	using CSV, DataFrames
	using CodecBzip2, Tar
	using Dates
	using Statistics
end

# ╔═╡ e85f0778-b384-11ed-304a-891e802cbdae
md"""
# Database

In this notebook, we join all the data from the different sensors into one single database.

## Import

### Dependencies
"""

# ╔═╡ 0f1b5962-390c-4462-bb7d-c17554742a4f
md"""
### Data
"""

# ╔═╡ 1cf0304b-4b67-42de-ac69-6957cc54c27a
md"""
Climatic conditions inside the chamber, at 5 min time-step resolution, only for the 5 minute long output flux measurement by the Picarro, not when it is measuring the input flux to the chamber.
"""

# ╔═╡ 86632c33-1ad9-428e-a5a2-8da77166f515
climate_5min = CSV.read("../1-climate/climate_mic3_5min.csv", DataFrame)

# ╔═╡ 9311888e-7235-4149-9265-809337086f23
climate_10min = CSV.read("../1-climate/climate_mic3_10min.csv", DataFrame)

# ╔═╡ 3013d612-b8ff-45be-b159-aaadc19fa86f
md"""
Leaf temperature measured by the thermal camera, at one-minute time-scale, for each visible leaf of the plants.
"""

# ╔═╡ 3025bd11-bcbf-4fa5-b67a-73be7bb6db07
leaf_temperature = open(Bzip2DecompressorStream, "../4-thermal_camera_measurements/leaf_temperature.csv.bz2") do io
    df_ = CSV.read(io, DataFrame)
	select!(df_, Not(:mask))
	df_
end

# ╔═╡ b67defe6-42cf-4bf6-b2ed-714d1b14f6ec
md"""
Weight of the plant and sealed pot, measured every minute.
"""

# ╔═╡ aa63bf29-146c-4363-85a1-d692848cd540
transpiration = open(Bzip2DecompressorStream, "../5-transpiration/transpiration.csv.bz2") do io
    CSV.read(io, DataFrame)
end

# ╔═╡ 148e7021-e46d-497a-8891-b45729b4fa48
md"""
CO2 fluxes, measured every 10 minutes for 5 minutes. The other five minutes are used for measuring the input flux.
"""

# ╔═╡ 4158de69-29ff-4402-873b-7287e7e74b48
CO2 = let
	df_ = CSV.read("../3-CO2/CO2_fluxes.csv", DataFrame)
	rename!(df_, :DateTime => :DateTime_start)
end

# ╔═╡ 6afe8250-5a8a-4253-b9d3-10d45423c600
sequence = let 
	df_ = CSV.read("../0-data/scenario_sequence/SequencePlanteMicro3.csv", DataFrame)
	transform!(
	    df_,
	    :hour_start => ByRow(x -> DateTime(x[1:end-1], dateformat"dd/mm/yyyy HH:MM:SS")) => :hour_start,
	    :hour_end => ByRow(x -> DateTime(x[1:end-1], dateformat"dd/mm/yyyy HH:MM:SS")) => :hour_end,
	)
	df_
end

# ╔═╡ c9e24f32-ef5f-48d8-951e-0996f166f41f
md"""
## Computing

In this section, all databases are modified to match the one with the coarser time-scale, which is the CO2 database. This database provides measurements for CO2 every 10 minutes, but with actual measurements only for 5 minutes, and then measuring the input flux for 5 minutes. Here we modify the databases to match only the window of 5-minutes measurement. We also compute a database with the average for the 10-minute window to get a continous database.
"""

# ╔═╡ 635d16bd-86f1-45c6-af81-6d4566671068
md"""
### Leaf temperature
"""

# ╔═╡ 58810c5f-a090-4896-a039-fe32e04c3b40
md"""
We start by computing four new columns inside the one-minute time-scale dataframe: the start and end datetime for every 5 minute window where we have a measurement of the output for the CO2 flux, and the same for every 10-minute window (input and output).

!!! note 
	The time-windows are taken from the `CO2` dataframe.
"""

# ╔═╡ ee3738bb-afcc-4f22-86ed-6326b67acb9f
md"""
#### 5-minute time-scale

Based on the previous dataframe, we can now keep only the first 5 minutes of every 10 minutes window, and average the values within those 5 minutes. The results are available in `leaf_temperature_first_5min`.
"""

# ╔═╡ 67086a6b-4629-4996-99ba-284ba2f6a783
md"""
#### 10-minute time-scale

We can also perform a similar computation, but keeping all data in the 10-minute window for our average.
"""

# ╔═╡ 524194a3-ba2c-47ed-a1bf-2eac7618b885
md"""
### Transpiration

Transpiration was measured every minute at the begining, and then every second. The data is noisy, but integrating the values over the 5 min or 10 min time-window of the CO2 fluxes measurements helps denoizing it.
"""

# ╔═╡ 8f7b5aee-71ac-4d78-abd6-d9bf4ceffa70
md"""
#### 5-min transpiration
"""

# ╔═╡ a3d9dbfb-16b0-46ce-a077-d7d193362638
md"""
To compute the transpiration of the first 5 minutes of each 10-minute window, we filter the data to take only the odd groups in `group_5min`.

Then we compute the transpiration inside this 5-minute time window as the slope of the weight~duration relationship. We could also compute it as the difference in weight between the first and last value(s), but this method is less integrative of what really happens inside the timestep, and is more sensitive to measurement error.
"""

# ╔═╡ c620c06f-06ec-4702-a85a-56a6270903fd
md"""
#### 10-min transpiration
"""

# ╔═╡ 326b71c6-00b2-4046-9ac2-962a42ceaa69
md"""
## Join

Joining the databases into one single database.
"""

# ╔═╡ e92c7421-c8e6-47ff-81ae-9e8e25818e99
md"""
### 5-minute database
"""

# ╔═╡ 2547928f-9569-4a1f-a636-7e8ecda893de
md"""
### 10-minute database
"""

# ╔═╡ 4407340e-12f9-429a-ba76-c8479f5d9c4a
md"""
# Saving

Saving both databases to disk:
"""

# ╔═╡ 7a00a634-6c9d-4f4c-95fc-489d0e77a2d1
md"""
# References
"""

# ╔═╡ 6d1223de-d6f3-4dab-a5c0-9d1289a7401e
"""
	duration(x)

Computes the duration between each element starting from the first one to the second until the end. The last value has a duration of `zero(x[2] - x[1])`.
"""
function duration(x)
	len = length(x)
	d = fill(zero(x[2] - x[1]), len)
	for i in eachindex(x)
		i == len && continue
		d[i] = x[i+1] - x[i] 
	end

	return d
end

# ╔═╡ 4befe24a-fc2a-4ed1-99ef-ccda6c7eaeda
"""
	group_timesteps(x, threshold = Minute(10))

Group time steps by a duration given by `threshold`.
"""
function group_timesteps(x, threshold = Minute(10))
	durations = duration(x)
	x_group = zeros(Int64, length(x))
	group = 0
	current_duration = zero(typeof(durations[1]))
	for i in eachindex(x)
		current_duration += durations[i]
		if current_duration > threshold 
			group = group + 1
			current_duration = zero(typeof(durations[1]))
		end
		x_group[i] = group
	end

	return x_group
end

# ╔═╡ 3e2d4f92-bb9b-4c45-9038-2d064ed58808
"""
	dates_between(x, start_dates, end_dates)

Computes all dates in x that are in-between start_dates and end_dates.
"""
function dates_between(x, start_dates, end_dates)
	@assert length(start_dates) == length(end_dates)
	
	DateTime_start = Vector{Union{DateTime,Missing}}(undef, length(x))
	DateTime_end = Vector{Union{DateTime,Missing}}(undef, length(x))

	for i in eachindex(start_dates)
		timestamps_within = findall(start_dates[i] .<= x .<= end_dates[1])
		
		if length(timestamps_within) > 0
			DateTime_start[timestamps_within] .= DateTime_start
			DateTime_end[timestamps_within] .= DateTime_end
		end
	end

	return (DateTime_start, DateTime_end)
end

# ╔═╡ 7d350e62-c035-49df-8827-66e044c562e3
"""
	add_timeperiod(x,y)

Add DateTime_start_5min, DateTime_end_5min, DateTime_start_10min and DateTime_end_10min on a copy of dataframe `x` using the `DateTime_start` and `DateTime_end` periods on dataframe `y`, and matching with the `DateTime` column in `x`.
"""
function add_timeperiod(x,y)
	df_ = copy(x)
	df_.DateTime_start_5min = Vector{Union{DateTime,Missing}}(undef, nrow(df_))
	df_.DateTime_start_10min = Vector{Union{DateTime,Missing}}(undef, nrow(df_))
	df_.DateTime_end_5min = Vector{Union{DateTime,Missing}}(undef, nrow(df_))
	df_.DateTime_end_10min = Vector{Union{DateTime,Missing}}(undef, nrow(df_))

	y_nrows = nrow(y)
	for (i, row) in enumerate(eachrow(y))

		# 5-min time window:
		ismissing(row.DateTime_start) || ismissing(row.DateTime_end) && continue
		timestamps_within = findall(row.DateTime_start .<= df_.DateTime .<= row.DateTime_end)
		
		if length(timestamps_within) > 0
			df_.DateTime_start_5min[timestamps_within] .= row.DateTime_start
			df_.DateTime_end_5min[timestamps_within] .= row.DateTime_end
		end

		# 10-min time window:
		i == y_nrows && continue
		next_date = y.DateTime_start[i+1]
		ismissing(next_date) && continue
		timestamps_within = findall(row.DateTime_start .<= df_.DateTime .< next_date)
		
		if length(timestamps_within) > 0
			df_.DateTime_start_10min[timestamps_within] .= row.DateTime_start
			df_.DateTime_end_10min[timestamps_within] .= next_date
		end
		
	end
	return df_
end

# ╔═╡ efd26e33-9f6f-41b9-8f74-09f457028078
leaf_temperature_df = let
	df_ = add_timeperiod(leaf_temperature, CO2)
	select!(
		df_,
		:plant,
		:leaf,
		:DateTime,
		:DateTime_start_5min,
		:DateTime_end_5min,
		:DateTime_start_10min,
		:DateTime_end_10min,
		:Tl_mean, :Tl_min, :Tl_max, :Tl_std
	)
	df_
end

# ╔═╡ 6d54867d-3cad-4699-85cd-fc2af74d7753
leaf_temperature_first_5min = let
	df_ = filter!(x-> !ismissing(x.DateTime_start_5min), leaf_temperature_df)
	df_ = combine(
		groupby(df_, [:plant, :leaf, :DateTime_start_5min]),
		:DateTime_end_5min => (x -> unique(x)) => :DateTime_end,
		names(leaf_temperature_df, Float64) .=> mean,
		#nrow;
		renamecols = false
	)
	rename!(df_, :DateTime_start_5min => :DateTime_start)

	select!(
		df_,
		[:plant, :leaf, :DateTime_start, :DateTime_end, :Tl_mean, :Tl_min, :Tl_max, :Tl_std]
	)
	df_
end

# ╔═╡ ab3424f1-8999-411a-9816-0e4d30b9b376
leaf_temperature_10min = let
	df_ = filter!(x-> !ismissing(x.DateTime_start_10min), leaf_temperature_df)
	df_ = combine(
		groupby(df_, [:plant, :leaf, :DateTime_start_10min]),
		:DateTime_end_10min => (x -> unique(x)) => :DateTime_end,
		names(leaf_temperature_df, Float64) .=> mean,
		#nrow;
		renamecols = false
	)
	rename!(df_, :DateTime_start_10min => :DateTime_start)

	select!(
		df_,
		[:plant, :leaf, :DateTime_start, :DateTime_end, :Tl_mean, :Tl_min, :Tl_max, :Tl_std]
	)
	df_
end

# ╔═╡ b8c31856-6754-41d5-8688-242f532c455e
transpiration_df = add_timeperiod(transpiration,CO2)

# ╔═╡ 9691ccc9-6123-4320-8031-f0fc7a080f66
transpi_first_5min = let
	df_ = filter!(x-> !ismissing(x.DateTime_start_5min), transpiration_df)
	# Compute the cumulated duration over each 5-min window:
	df_ = transform(
		groupby(df_, :DateTime_start_5min), 
		:DateTime => (x-> cumsum(duration(x))) => :duration
	)
	# Compute transpiration as the slope of the linear weight~duration relationship: 
	df_ = combine(
		groupby(df_, :DateTime_start_5min),
		:DateTime_end_5min => unique => :DateTime_end,
		[:weight, :duration] => ((y,x) -> begin
		x=[i.value for i in Second.(x)]
		(x'*x)\x'*(y[1] .- y)
		end
		) => :transpiration_g_s, # grammes s-1
		# To compute as the weight difference between first last time-step(s):
		# [:weight, :duration] => ((x,y) -> (median(first(x, 1)) - median(last(x, 1))) / Second(last(y)).value) => :transpiration_diff,
		:duration => (x -> canonicalize(maximum(x))) => :period_computation,
		nrow
	)
	rename!(df_, :DateTime_start_5min => :DateTime_start)
	# Keep only the time-steps where we have 3 minutes of data to compute Tr:
	filter!(x -> x.nrow > 3, df_)
	df_	
end

# ╔═╡ 42bcf804-8ed0-4573-8201-1fd79bc0a140
db_5min = let
	db_ = outerjoin(CO2, climate_5min, on = :DateTime_start, makeunique = true)
	db_ = outerjoin(db_, transpi_first_5min, on = :DateTime_start, makeunique = true)
	db_ = outerjoin(db_, leaf_temperature_first_5min, on = :DateTime_start, makeunique = true)

	select!(
		db_,
		"plant",
		"leaf",
		:DateTime_start,
		:DateTime_end_1 => :DateTime_end,
		:DateTime_end => :DateTime_end_CO2_in,
		#:DateTime_end_CO2_in,
		:flux_umol_s => :CO2_outflux_umol_s,
		:CO2_dry_MPV1,
		:CO2_dry_MPV2,
		"Ta_instruction",
		"Ta_measurement",
		"Rh_instruction",
		"Rh_measurement",
		"R_instruction",
		"R_measurement",
		"CO2_ppm",
		"CO2_flux" => "CO2_influx",
		"CO2_instruction",
		"transpiration_g_s",
		"Tl_mean",
		"Tl_min",
		"Tl_max",
		"Tl_std",
		"period_computation",
		"nrow" => :n_datapoints,
	)
	db_
end

# ╔═╡ eaed2c19-60a9-4fe2-8788-6143df1062d2
open(Bzip2CompressorStream, "database_5min.csv.bz2", "w") do stream
    CSV.write(stream, db_5min)
end

# ╔═╡ ac377725-f287-4f17-9373-fc3bfea6e5f2
transpi_10min = let
	df_ = filter!(x-> !ismissing(x.DateTime_start_10min), transpiration_df)
	# Compute the cumulated duration over each 10-min window:
	df_ = transform(
		groupby(df_, :DateTime_start_10min), 
		:DateTime => (x-> cumsum(duration(x))) => :duration
	)
	# Compute transpiration as the slope of the linear weight~duration relationship: 
	df_ = combine(
		groupby(df_, :DateTime_start_10min),
		:DateTime_end_10min => unique => :DateTime_end,
		[:weight, :duration] => ((y,x) -> begin
		x=[i.value for i in Second.(x)]
		(x'*x)\x'*(y[1] .- y)
		end
		) => :transpiration_g_s, # grammes s-1
		:duration => (x -> canonicalize(maximum(x))) => :period_computation,
		nrow
	)
	rename!(df_, :DateTime_start_10min => :DateTime_start)
	# Keep only the time-steps where we have 3 minutes of data to compute Tr:
	filter!(x -> x.nrow > 3, df_)
	df_	
end

# ╔═╡ 415a440a-8aea-4f38-893f-d22d0114a16e
db_10min = let
	db_ = outerjoin(CO2, climate_10min, on = :DateTime_start, makeunique = true)
	db_ = outerjoin(db_, transpi_10min, on = :DateTime_start, makeunique = true)
	db_ = outerjoin(db_, leaf_temperature_10min, on = :DateTime_start, makeunique = true)

	select!(
		db_,
		"plant",
		"leaf",
		:DateTime_start,
		:DateTime_end_1 => :DateTime_end,
		:DateTime_end => :DateTime_end_CO2_in,
		#:DateTime_end_CO2_in,
		:flux_umol_s => :CO2_outflux_umol_s,
		:CO2_dry_MPV1,
		:CO2_dry_MPV2,
		"Ta_instruction",
		"Ta_measurement",
		"Rh_instruction",
		"Rh_measurement",
		"R_instruction",
		"R_measurement",
		"CO2_ppm",
		"CO2_flux" => "CO2_influx",
		"CO2_instruction",
		"transpiration_g_s",
		"Tl_mean",
		"Tl_min",
		"Tl_max",
		"Tl_std",
		"period_computation",
		"nrow" => :n_datapoints,
	)
end

# ╔═╡ 168c5c96-9252-4a5a-85d2-613b2246cd63
open(Bzip2CompressorStream, "database_10min.csv.bz2", "w") do stream
    CSV.write(stream, db_10min)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
CodecBzip2 = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
Tar = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[compat]
CSV = "~0.10.9"
CodecBzip2 = "~0.7.2"
DataFrames = "~1.5.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.2"
manifest_format = "2.0"
project_hash = "7f599990116ef5fa83746d6e3afd541cb84e715f"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "SnoopPrecompile", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "c700cce799b51c9045473de751e9319bdd1c6e94"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.9"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "2e62a725210ce3c3c2e1a3080190e7ca491f18d7"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.7.2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "9c209fb7536406834aa938fb149964b985de6c83"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.1"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "61fdd77467a5c3ad071ef8277ac6bd6af7dd4c04"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.6.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SnoopPrecompile", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "aa51303df86f8626a962fccb878430cdb0a97eee"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.5.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "e27c4ebe80e8699540f2d6c805cc12203b614f12"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.20"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "82aec7a3dd64f4d9584659dc0b62ef7db2ef3e19"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.2.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "6f4fbcd1ad45905a5dee3f4256fabb49aa2110c6"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.7"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "LaTeXStrings", "Markdown", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "96f6db03ab535bdb901300f88335257b0018689d"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "77d3c4726515dca71f6d80fbb5e251088defe305"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.18"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "c79322d36826aa2f4fd8ecfa96ddb47b174ac78d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "94f38103c984f89cf77c402f2a68dbd870f8165f"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.11"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─e85f0778-b384-11ed-304a-891e802cbdae
# ╠═947be178-0b89-46b6-aa74-383e38bf903e
# ╟─0f1b5962-390c-4462-bb7d-c17554742a4f
# ╟─1cf0304b-4b67-42de-ac69-6957cc54c27a
# ╠═86632c33-1ad9-428e-a5a2-8da77166f515
# ╠═9311888e-7235-4149-9265-809337086f23
# ╟─3013d612-b8ff-45be-b159-aaadc19fa86f
# ╠═3025bd11-bcbf-4fa5-b67a-73be7bb6db07
# ╟─b67defe6-42cf-4bf6-b2ed-714d1b14f6ec
# ╠═aa63bf29-146c-4363-85a1-d692848cd540
# ╟─148e7021-e46d-497a-8891-b45729b4fa48
# ╠═4158de69-29ff-4402-873b-7287e7e74b48
# ╠═6afe8250-5a8a-4253-b9d3-10d45423c600
# ╟─c9e24f32-ef5f-48d8-951e-0996f166f41f
# ╟─635d16bd-86f1-45c6-af81-6d4566671068
# ╟─58810c5f-a090-4896-a039-fe32e04c3b40
# ╠═efd26e33-9f6f-41b9-8f74-09f457028078
# ╟─ee3738bb-afcc-4f22-86ed-6326b67acb9f
# ╠═6d54867d-3cad-4699-85cd-fc2af74d7753
# ╟─67086a6b-4629-4996-99ba-284ba2f6a783
# ╠═ab3424f1-8999-411a-9816-0e4d30b9b376
# ╟─524194a3-ba2c-47ed-a1bf-2eac7618b885
# ╠═b8c31856-6754-41d5-8688-242f532c455e
# ╟─8f7b5aee-71ac-4d78-abd6-d9bf4ceffa70
# ╟─a3d9dbfb-16b0-46ce-a077-d7d193362638
# ╠═9691ccc9-6123-4320-8031-f0fc7a080f66
# ╟─c620c06f-06ec-4702-a85a-56a6270903fd
# ╠═ac377725-f287-4f17-9373-fc3bfea6e5f2
# ╟─326b71c6-00b2-4046-9ac2-962a42ceaa69
# ╟─e92c7421-c8e6-47ff-81ae-9e8e25818e99
# ╠═42bcf804-8ed0-4573-8201-1fd79bc0a140
# ╟─2547928f-9569-4a1f-a636-7e8ecda893de
# ╠═415a440a-8aea-4f38-893f-d22d0114a16e
# ╟─4407340e-12f9-429a-ba76-c8479f5d9c4a
# ╠═168c5c96-9252-4a5a-85d2-613b2246cd63
# ╠═eaed2c19-60a9-4fe2-8788-6143df1062d2
# ╟─7a00a634-6c9d-4f4c-95fc-489d0e77a2d1
# ╟─6d1223de-d6f3-4dab-a5c0-9d1289a7401e
# ╟─4befe24a-fc2a-4ed1-99ef-ccda6c7eaeda
# ╟─3e2d4f92-bb9b-4c45-9038-2d064ed58808
# ╟─7d350e62-c035-49df-8827-66e044c562e3
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
