### A Pluto.jl notebook ###
# v0.19.43

using Markdown
using InteractiveUtils

# ╔═╡ 4b871515-5f38-4b6a-a9c1-00f40160041e
begin
    using CSV
    using DataFrames
    using ZipFile
    using Dates
    using Statistics
    using PlutoUI
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
    r = ZipFile.Reader("../00-data/climate/climate.zip")
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

First, we add a new column for the CO2 instructions in the chamber, which will be less noisy than the measurement (`CO2_ppm`), because it will be defined more as a factorial variable. To do so, we use the CO2 flux because it is more reliable than the CO2 concentration measurement.
"""

# ╔═╡ 50bfe460-7fd6-4374-9b9f-a7c6b05c3cb6
md"""
Second, we import the data of the CO2 fluxes measurements in the chamber, which gives us the start and end time of each measurement session. The input CO2 is measured for 5 minutes, and then the output is measured for 5 minutes. The input CO2 correspond to the instruction in input to get the chamber to a given CO2 concentration in the air, and the output CO2 is the air from the chamber, that is measured to compute the CO2 fluxes from the plant (*i.e.* respiration and photosynthesis).
"""

# ╔═╡ 5e72d148-855e-48b4-8e4f-921569aeee4c
needed_period_df =
    let
        df_ = CSV.read("../00-data/picarro_flux/data_mean_flux.csv", DataFrame)
        transform!(
            df_,
            :MPV1_time => (x -> DateTime.(x, dateformat"dd/mm/yyy HH:MM")) => :MPV1_time,
            :MPV2_time => (x -> DateTime.(x, dateformat"dd/mm/yyy HH:MM")) => :MPV2_time
        )

        transform!(
            df_,
            :MPV1_time => (x -> x .- Second(150)) => :DateTime_start_input,
            :MPV1_time => (x -> x .+ Second(150)) => :DateTime_end_input,
            :MPV2_time => (x -> x .- Second(150)) => :DateTime_start_output,
            :MPV2_time => (x -> x .+ Second(150)) => :DateTime_end_output
        )

        df_
    end

# ╔═╡ fc40172d-2c75-4376-9b8a-94b24a9597a6
md"""
!!! note
	We remove/add 150 seconds to the DateTime because it is given as the average time between a valve opening and closing, and we want the time of valve opening and closing.
"""

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

# ╔═╡ 60914f72-ee28-46f0-9ce0-1c608dd01193
mic3_5min = let
    mic3_ = copy(mic3_2)
    mic3_.DateTime_start = Vector{Union{DateTime,Missing}}(undef, nrow(mic3_))
    mic3_.DateTime_end = Vector{Union{DateTime,Missing}}(undef, nrow(mic3_))

    for row in eachrow(needed_period_df)
        timestamps_within = findall(row.DateTime_start_output .<= mic3_.DateTime .<= row.DateTime_end_output)

        if length(timestamps_within) > 0
            mic3_.DateTime_start[timestamps_within] .= row.DateTime_start_output
            mic3_.DateTime_end[timestamps_within] .= row.DateTime_end_output
        end
    end
    filter!(x -> !ismissing(x.DateTime_start), mic3_)

    mic3_c = combine(
        groupby(mic3_, :DateTime_start),
        :DateTime_end => unique => :DateTime_end,
        names(mic3_, Number) .=> mean .=> names(mic3_, Number),
        :CO2_change => (x -> any(x .== "change") ? "change" : "no_change") => :CO2_change
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

    for row in eachrow(needed_period_df)
        timestamps_within = findall(row.DateTime_start_input .<= mic3_.DateTime .< row.DateTime_end_output)

        if length(timestamps_within) > 0
            mic3_.DateTime_start[timestamps_within] .= row.DateTime_start_input
            mic3_.DateTime_end[timestamps_within] .= row.DateTime_end_output
        end
    end

    filter!(x -> !ismissing(x.DateTime_start), mic3_)

    mic3_c = combine(
        groupby(mic3_, :DateTime_start),
        :DateTime_end => unique => :DateTime_end,
        names(mic3_, Number) .=> mean .=> names(mic3_, Number),
        :CO2_change => (x -> any(x .== "change") ? "change" : "no_change") => :CO2_change
    )

    mic3_c
end

# ╔═╡ 877f55bd-69dc-408f-9f5c-33ab345a1e01
CSV.write("climate_mic3_10min.csv", mic3_10min)

# ╔═╡ 131d19dc-7bba-48ca-94ae-f63c167d3747
TableOfContents(title="📚 Table of Contents", indent=true, depth=4, aside=true)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
ZipFile = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"

[compat]
CSV = "~0.10.14"
DataFrames = "~1.6.1"
PlutoUI = "~0.7.59"
ZipFile = "~0.10.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.3"
manifest_format = "2.0"
project_hash = "90e8f43abb26ae0ba6e3488dffdfce9f24dcd88a"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "6c834533dc1fabd820c1db03c839bf97e45a3fab"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.14"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "b8fe8546d52ca154ac556809e10c75e6e7430ac8"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.5"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "b1c55339b7c6c350ee89f2c1604299660525b248"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.15.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "04c738083f29f86e62c8afc341f0967d8717bdb8"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.6.1"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

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
git-tree-sha1 = "9f00e42f8d99fdde64d40c8ea5d14269a2e2c1aa"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.21"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "86356004f30f8e737eff143d57d41bd580e437aa"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.1"

    [deps.InlineStrings.extensions]
    ArrowTypesExt = "ArrowTypes"

    [deps.InlineStrings.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "ab55ee1510ad2af0ff674dbcced5e94921f867a9"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.59"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "66b20dd35966a748321d3b2537c4584cf40387c7"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.3.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
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
git-tree-sha1 = "ff11acffdb082493657550959d4feb4b6149e73a"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.5"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a04cabe79c5f01f4d723cc6704070ada0b9d46d5"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.4"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "cb76cf677714c095e535e3501ac7954732aeea2d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.11.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
git-tree-sha1 = "60df3f8126263c0d6b357b9a1017bb94f53e3582"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.0"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

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
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
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
# ╟─fc40172d-2c75-4376-9b8a-94b24a9597a6
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
# ╠═131d19dc-7bba-48ca-94ae-f63c167d3747
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
