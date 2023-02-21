### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ 4b871515-5f38-4b6a-a9c1-00f40160041e
begin
	using CSV
	using DataFrames
	using ZipFile
	using Dates
	using Statistics
end

# ╔═╡ 1a8b0e04-b1c7-11ed-2dba-758bc57db4b4
md"""
# Chamber climate

Two chambers were used for the experiment in the Ecotron: the microcosm 3 (mic3) and microcosm 4 (mic4).

The climate inside the two chambers was finely controlled during the whole experiment. `mic4` was used to store the plants following the reference scenario, and `mic3` for measuring response of one plant to specific conditions.

The data was exported regularly, resulting in several files for each chamber.

The aim of this notebook is to make one single file for each chamber.

## Imports

### Loading the dependencies
"""

# ╔═╡ d12c1da3-ab15-46db-82c0-307a303f3a2f
md"""
### Read the data

Read the data from the zip archive, without uncompressing all files:
"""

# ╔═╡ b1ab6d25-6fa7-4d58-9515-c1910d999224
begin
	r = ZipFile.Reader("../0-data/climate/climate.zip");
 	mic4_files = []
 	mic3_files = []
 	for f in r.files
		startswith(f.name, "Mic4") && push!(mic4_files, CSV.read(f, DataFrame))
 		startswith(f.name, "Mic3") && push!(mic3_files, CSV.read(f, DataFrame))
 	end
	close(r)

	mic3 = vcat(mic3_files...)
	mic4 = vcat(mic4_files...)

	select!(mic3, Not(:Column1))
	select!(mic4, Not(:Column1))
	nothing
end

# ╔═╡ 5774b396-cece-4252-b1f2-c969d80a8b04
md"""
## Data cleaning
"""

# ╔═╡ df4e3ebd-8355-4674-9546-51feace7cfb3
md"""
Some data is duplicated in the files (they are overlapping), so we need to make the rows unique in the dataframes. We also need to rename the variables into more sensible names, adapted to programming tasks, *i.e.* not using empty spaces, or unusal characters.
"""

# ╔═╡ 21fb221b-e3ef-4515-ac83-73daf9c6721d
mic3_df = 
	select(
		unique(mic3),
		"DateTime" => (x -> DateTime.(x, dateformat"yyy-mm-dd HH:MM:SS")) => "DateTime",
		"consigne T\xb0C" => :Ta_instruction,
		"mesure T\xb0C" => :Ta_measurement,
		"consigne HR" => :Rh_instruction,
		"mesure HR" => :Rh_measurement,
		"consigne Rayo" => :R_instruction,
		"mesure Rayo" => :R_measurement,
		"mesures [CO2]" => :CO2_ppm,
		"mesure debit CO2" => :CO2_flux,
		"Mic"
)

# ╔═╡ c3a421e1-2edc-4974-83b5-652f40519735
mic4_df = 
	select(
		unique(mic4),
		"DateTime" => (x -> DateTime.(x, dateformat"yyy-mm-dd HH:MM:SS")) => "DateTime",
		"consigne T\xb0C" => :Ta_instruction,
		"mesure T\xb0C" => :Ta_measurement,
		"consigne HR" => :Rh_instruction,
		"mesure HR" => :Rh_measurement,
		"consigne Rayo" => :R_instruction,
		"mesure Rayo" => :R_measurement,
		"mesures [CO2]" => :CO2_ppm,
		"Mic"
)

# ╔═╡ 40a4a501-68fc-4d63-9b9c-93f6dd177020
md"""
## 5 minute time-step Mic3

The climate files are at a 30s time-step, but the CO2 fluxes are measured
for 5 minutes every 10 minutes (5min input / 5min output), so we need the 
climate data integrated at 5min time-step when there is a measurement of CO2
flux.

First, we add a new column for the CO2 instructions in the chamber, which will be less noisy that the measurement (`CO2_ppm`), because it will be defined more as a factorial variable. To do so, we use the CO2 flux because it is more reliable than the CO2 concentration measurement.
"""

# ╔═╡ 50bfe460-7fd6-4374-9b9f-a7c6b05c3cb6
md"""
Second, we import the data of the CO2 fluxes measurements in the chamber, which gives us the start and end time of each measurement session. The input CO2 is measured for 5 minutes, and then the output is measured for 5 minutes. The input CO2 correspond to the instruction in input to get the chamber to a given CO2 concentration in the air, and the output CO2 is the air from the chamber, that is measured to compute the CO2 fluxes from the plant (*i.e.* respiration and photosynthesis).
"""

# ╔═╡ 5e72d148-855e-48b4-8e4f-921569aeee4c
needed_period_df = 
	let
		df_ = CSV.read("../0-data/picarro_flux/data_mean_flux.csv", DataFrame)
		 transform!(
		 	df_,
			:MPV1_time => (x -> DateTime.(x, dateformat"dd/mm/yyy HH:MM")) => :DateTime_start,
			 :MPV2_time => (x -> DateTime.(x, dateformat"dd/mm/yyy HH:MM")) => :DateTime_end
		)

		df_
	end

# ╔═╡ 22bbbf62-96a3-4f58-9e97-ac7f066f1cff
md"""
Now that we have the time windows of measurement, we can use it to compute the average conditions inside these windows.

We make two different tables, on that averages only the conditions inside a measurement session (just for the 5 min of CO2 output), and another that uses the 10 minute average, starting with the input CO2 and then the output CO2 for each 10 minute time-step.
"""

# ╔═╡ 890a6507-c87a-4cc3-afa5-80ce5723ab5c
md"""
## Saving

Lastly, we write the new dataframes to disk:
"""

# ╔═╡ 0fafa057-4fba-488f-8d03-f8b238f825b8
CSV.write("climate_mic3.csv", mic3_df)

# ╔═╡ a5b99f51-75a3-4fc8-a98d-e156cc8b1c03
CSV.write("climate_mic4.csv", mic4_df)

# ╔═╡ 6355f700-2c6d-4537-9072-aa99918d7b73
md"""
# References
"""

# ╔═╡ b96fe1f5-32ff-4bd7-944d-d7a02d0b8c40
"""
	is_change(x)

Looks when there is a change in the sequence of values. Returns a vector of string, with the value "no_change" if the current value is the same as the previous one, or "change" if it is different.

# Examples

```julia
is_change([1,1,1,2,2,2])
```
"""
function is_change(x)
	change = fill("no_change", length(x))
	for i in eachindex(change)
		if i > 1 && x[i] != x[i-1]
			change[i] = "change"
		end
	end
	return change
end

# ╔═╡ 261b93fd-a903-40b2-a0fc-a5b745ed56c7
mic3_2 = 
	let 
		df_ = transform(
			mic3_df,
			:CO2_flux => ByRow(x -> begin
					if 30 <= x <= 45 
						return 400.0
					elseif 45 <= x <= 55
						return 600.0
					elseif x >= 55
						return 800.0
					else 
						return 0.0
					end
				end
			) => :CO2_instruction,
		)
		transform!(df_,
			:CO2_instruction => is_change => :CO2_change,
		)
		
		df_
	end

# ╔═╡ 8ea7c9cd-3755-4d48-a3e6-399fd0d932e1
"""
	propagate_around(x, val, before, after)

Propagate the value `val` in the vector `x` around it to `before` values before the values equal to `val`, and `after` values after it.

# Arguments

- `x`: a vector of values
- `val`: a value to find and propagate inside `x`
- `before`: number of values to propagate before `x[x.==val]`
- `after`: number of values to propagate after `x[x.==val]`

# Examples

```julia
julia> propagate_around([1,1,1,0,1,1,1,1], 0, 1, 3)
[1,1,0,0,0,0,0,1]
```
"""
function propagate_around(x, val, before, after)
		x2 = copy(x)
	
		# Find any value in x that matches val:
		val_in_x = findall(x .== val)
		length(val_in_x) == 0 && return
	
		 #For each index that matches `val`, set the value around it
		# (`before` and `after`) to `val`:
		for i in val_in_x
			x2[max(1, i-before) : min(end, i+after)] .= val
		end
	
		return x2
end

# ╔═╡ 60914f72-ee28-46f0-9ce0-1c608dd01193
mic3_5min = let
	mic3_ = copy(mic3_2)
	mic3_.DateTime_start = Vector{Union{DateTime,Missing}}(undef, nrow(mic3_))
	mic3_.DateTime_end = Vector{Union{DateTime,Missing}}(undef, nrow(mic3_))

	for row in eachrow(needed_period_df)
		timestamps_within = findall(row.DateTime_start .<= mic3_.DateTime .<= row.DateTime_end)
		
		if length(timestamps_within) > 0
			mic3_.DateTime_start[timestamps_within] .= row.DateTime_start
			mic3_.DateTime_end[timestamps_within] .= row.DateTime_end
		end
	end
	filter!(x-> !ismissing(x.DateTime_start), mic3_)

	mic3_c = combine(
		groupby(mic3_, :DateTime_start),
		:DateTime_end => unique => :DateTime_end,
		names(mic3_, Number) .=> mean .=> names(mic3_, Number),
		:CO2_change => (x -> any(x .== "change") ? "change" : "no_change") => :CO2_change
	)

	# Add "CO2_change_around" column that flags values at "change" for all values 
	# around a change (1 before and 5 after a change):
	transform!(
		mic3_c,
		:CO2_change => (x -> propagate_around(x, "change", 1, 5)) => :CO2_change_around
	)

	mic3_c
end

# ╔═╡ c4675a60-1951-4e7c-aa00-00d1efa1a430
CSV.write("climate_mic3_5min.csv", mic3_5min)

# ╔═╡ af847638-1dbf-4ae6-b88b-9f58bd5974f3
mic3_10min = let
	mic3_ = copy(mic3_2)
	mic3_.DateTime_start = Vector{Union{DateTime,Missing}}(undef, nrow(mic3_))
	mic3_.DateTime_end = Vector{Union{DateTime,Missing}}(undef, nrow(mic3_))

	nrows_df = nrow(needed_period_df)

	for i in 1:nrows_df
		if i == nrows_df
			continue
		end
		
		this_row = needed_period_df[i,:]
		next_row = needed_period_df[i+1,:]
		
		timestamps_within = findall(this_row.DateTime_start .<= mic3_.DateTime .< next_row.DateTime_start)
		
		if length(timestamps_within) > 0
			mic3_.DateTime_start[timestamps_within] .= this_row.DateTime_start
			mic3_.DateTime_end[timestamps_within] .= next_row.DateTime_start
		end
	end
	
	filter!(x-> !ismissing(x.DateTime_start), mic3_)

	mic3_c = combine(
		groupby(mic3_, :DateTime_start),
		:DateTime_end => unique => :DateTime_end,
		names(mic3_, Number) .=> mean .=> names(mic3_, Number),
		:CO2_change => (x -> any(x .== "change") ? "change" : "no_change") => :CO2_change
	)

	# Add "CO2_change_around" column that flags values at "change" for all values 
	# around a change (1 before and 5 after a change):
	transform!(
		mic3_c,
		:CO2_change => (x -> propagate_around(x, "change", 1, 5)) => :CO2_change_around
	)

	mic3_c
end

# ╔═╡ 877f55bd-69dc-408f-9f5c-33ab345a1e01
CSV.write("climate_mic3_10min.csv", mic3_10min)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
ZipFile = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"

[compat]
CSV = "~0.10.9"
DataFrames = "~1.5.0"
ZipFile = "~0.10.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.2"
manifest_format = "2.0"
project_hash = "53ee8cb37d6b38a5faf4f63d6d77fd070a9cb99d"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "SnoopPrecompile", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "c700cce799b51c9045473de751e9319bdd1c6e94"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.9"

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

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "e27c4ebe80e8699540f2d6c805cc12203b614f12"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.20"

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

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

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

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

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
git-tree-sha1 = "c02bd3c9c3fc8463d3591a62a378f90d2d8ab0f3"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.17"

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

[[deps.ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "f492b7fe1698e623024e873244f10d89c95c340a"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.10.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"
"""

# ╔═╡ Cell order:
# ╟─1a8b0e04-b1c7-11ed-2dba-758bc57db4b4
# ╠═4b871515-5f38-4b6a-a9c1-00f40160041e
# ╟─d12c1da3-ab15-46db-82c0-307a303f3a2f
# ╠═b1ab6d25-6fa7-4d58-9515-c1910d999224
# ╟─5774b396-cece-4252-b1f2-c969d80a8b04
# ╟─df4e3ebd-8355-4674-9546-51feace7cfb3
# ╠═21fb221b-e3ef-4515-ac83-73daf9c6721d
# ╠═c3a421e1-2edc-4974-83b5-652f40519735
# ╟─40a4a501-68fc-4d63-9b9c-93f6dd177020
# ╠═261b93fd-a903-40b2-a0fc-a5b745ed56c7
# ╟─50bfe460-7fd6-4374-9b9f-a7c6b05c3cb6
# ╠═5e72d148-855e-48b4-8e4f-921569aeee4c
# ╟─22bbbf62-96a3-4f58-9e97-ac7f066f1cff
# ╠═60914f72-ee28-46f0-9ce0-1c608dd01193
# ╠═af847638-1dbf-4ae6-b88b-9f58bd5974f3
# ╟─890a6507-c87a-4cc3-afa5-80ce5723ab5c
# ╠═0fafa057-4fba-488f-8d03-f8b238f825b8
# ╠═c4675a60-1951-4e7c-aa00-00d1efa1a430
# ╠═877f55bd-69dc-408f-9f5c-33ab345a1e01
# ╠═a5b99f51-75a3-4fc8-a98d-e156cc8b1c03
# ╟─6355f700-2c6d-4537-9072-aa99918d7b73
# ╟─b96fe1f5-32ff-4bd7-944d-d7a02d0b8c40
# ╟─8ea7c9cd-3755-4d48-a3e6-399fd0d932e1
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
