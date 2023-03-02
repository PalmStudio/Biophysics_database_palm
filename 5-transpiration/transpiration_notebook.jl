### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ 6685ea8b-7a27-4e62-9ce8-82955a06fd58
begin
	using Dates
	using CSV, DataFrames
	using CodecBzip2, Tar # For the compression of the resulting CSV
end

# ╔═╡ 6b8526e4-b297-11ed-1c66-470f26a581c7
md"""
# Plant transpiration

The weight of the potted plant inside the measurement chamber (`mic3`) was continuously monitored using a connected precision scale. The pot and soil were isolated using a plastic bag, so any change in the pot weight was due to the plant transpiration (+/- the saturation inside the bag).

The transpiration was measured in five phases due to changes in the measurement setup: 

- phase 0, from 09/03/2021 to 10/03/2021, logged in the file `Weights_1.txt`. In this phase we used a regular computer with a script that read the data from the scale (1000C-3000D) for one minute, and logged its average onto the computer. The DateTime is in UTC+1.
- phase 1, from 2021-03-10T15:08:23 to 2021-03-15T14:49:06, file `weightsPhase1.txt`. We changed computers to use one from the Ecotron, which was arounbd UTC-4min.
- phase 2, from 2021-03-15T15:46:13 to 2021-03-27T01:19:27, file `weightsPhase2.txt`. In this measurement phase, we changed the script to log the data every second, without any averaging as we decided it is better to log the raw data and make the average afterward. The DateTime should be close to UTC. This data collection end the day before the day-time change. Data is lost for the weekend (after 2021-03-27T01:19:27) because the weight of the plant was above the maximum capacity of the scale. 
- phase 3, from 2021-03-30T09:45:01 to 2021-04-08T07:03:59, file `weightsPhase3.txt`. This phase is the same as phase 3, there is just a data gap because we were investigating why data logging was not working anymore (we didn't see any error on the scale).
- phase 4, from 2021-04-07T10:46:19 to 2021-05-02T06:49:33, file `weightsPhase4.txt`. We received the new precision scale (XB3200C) that we just bought (we borrowed the first one). So in this phase we changed the scale, and also installed a Raspberry Pi to log the data. The Raspberry Pi is connected to the scale via USB, and the data is logged every second. We measured a lag in the DateTime of around 1 day, 47 minutes and 12 seconds compared to UTC (Raspberry: 2021-04-12T13:02:43 ; Thermal camera: 20210413_144827_R.jpg, with a delay of 3512s, so 2021-04-13T13:49:55 UTC)

To be sure to get the same time for all the data, we used the time of the thermal camera, which we know have a constant delay of 3512s compared to UTC. The method was to use the thermal images to see when there is a change of plant, because its weight goes down near 0.0 at this time, with a maximum error of 60s, because the images where taken each minute.

We use the `time_synchronization.csv` file to synchronize correctly the timestamps.

## Imports

### Dependencies
"""

# ╔═╡ a7b313b8-2f6f-43c1-a39b-ada77982a31e
md"""
Reading the time correction file.
"""

# ╔═╡ 7027478e-8ba6-4b17-9448-628114d73816
time_correction = CSV.read(
	"../2-time-synchronization/time_synchronization.csv", 
	DataFrame
)

# ╔═╡ d631a6a0-4842-4d28-b6ad-f82093fe8581
md"""
### Data

#### Decompressing the archive
"""

# ╔═╡ c8f60ef9-2caa-46de-ab51-11de279a678b
open(Bzip2DecompressorStream, "../0-data/scale_weight/weights.tar.bz2") do io
    Tar.extract(io, "../0-data/scale_weight/weight")
end

# ╔═╡ 39fbd542-3f1b-4327-b8fb-ab56f8af1682
md"""
#### Phase 0
"""

# ╔═╡ 3ff85909-c02b-471c-b649-fa51c2df7b12
md"""
Reading phase 0 data. We know this one is at UTC+1 because it was connected to Rémi's computer, with a well synchrnoized clock. Note that we don't have the possibility to double-check this one with the camera as there is no data close to 0 (it starts when the plant is on, and end before removing it0.)
"""

# ╔═╡ c41298a7-108a-4a30-927c-359d4eb10b01
df_phase_0 = let
	df = CSV.read("../0-data/scale_weight/weight/weights_1.txt", DataFrame, header=["DateTime", "weight"])
	df.DateTime = df.DateTime - Dates.Hour(1)
	df
end

# ╔═╡ 8ddc6990-6c42-4ba8-9363-9726dc695db0
md"""
#### Phase 1

Starting from phase 1 until phase 4 measurements, we double-checked the delays between the scale data logging and UTC using the thermal camera and the time of door opening and closing, which is the reference because it is synchronized to UTC with all other equipments from the Ecotron.
"""

# ╔═╡ fe844dad-d2d5-4cb9-97be-6277c405ed86
df_phase_1 = let
	df = CSV.read("../0-data/scale_weight/weight/weightsPhase1.txt", DataFrame, header=["DateTime", "weight"])
	# Phase 0 is at UTC+1, so we need to correct the time:
	delay = filter(x -> x.type == "scale" && x.phase == "phase1", time_correction).delay_seconds[1]
	df.DateTime .+= Dates.Second(delay)
	df
end

# ╔═╡ 6b81d83c-e139-46b4-bc4f-2110cdaa42f0
md"""
#### Phase 2
"""

# ╔═╡ 6056cd3b-6277-4c88-9481-76a6b1efdb75
df_phase_2 = let
	df = CSV.read("../0-data/scale_weight/weight/weightsPhase2.txt", DataFrame, header=["DateTime", "weight"])
	# Phase 0 is at UTC+1, so we need to correct the time:
	delay = filter(x -> x.type == "scale" && x.phase == "phase2", time_correction).delay_seconds[1]
	df.DateTime .+= Dates.Second(delay)
	df
end

# ╔═╡ a83879cd-1fd5-4306-9bf7-49074229f842
md"""
#### Phase 3
"""

# ╔═╡ e4ee7511-75c9-4a0e-9c75-f11516eaaafa
df_phase_3 = let
	df = CSV.read("../0-data/scale_weight/weight/weightsPhase3.txt", DataFrame, header=["DateTime", "weight"])
	# Phase 0 is at UTC+1, so we need to correct the time:
	delay = filter(x -> x.type == "scale" && x.phase == "phase3", time_correction).delay_seconds[1]
	df.DateTime .+= Dates.Second(delay)
	df
end

# ╔═╡ 6f1549b9-4bf9-4d09-9ce9-b36aa92ac9f1
md"""
#### Phase 4
"""

# ╔═╡ d9bca3d6-6076-45c6-8f90-cf1d4fb9cb56
df_phase_4 = let
	df = CSV.read("../0-data/scale_weight/weight/weightsPhase4.txt", DataFrame, header=["DateTime", "weight"])
	# Phase 0 is at UTC+1, so we need to correct the time:
	delay = filter(x -> x.type == "scale" && x.phase == "phase4", time_correction).delay_seconds[1]
	df.DateTime .+= Dates.Second(delay)
	df
end

# ╔═╡ 3ec8ee51-c26f-4771-95ef-f24e1698ea5f
md"""
## Merging the data

Now that we imported the data and corrected the delays to match UTC, we can merge the data into one single dataframe.
"""

# ╔═╡ 3fb32c18-bdd2-44bb-a635-ebb5682a5956
transpiration_df = vcat(df_phase_0, df_phase_1, df_phase_2, df_phase_3, df_phase_4)

# ╔═╡ 8948f7cf-1105-4c8d-a5e5-3dbc5dbd0c60
md"""
## Saving

Save the data to disk, and compressing it to save disk space.
"""

# ╔═╡ 9caab45e-f33b-4b54-a7de-7f7035144f0e
open(Bzip2CompressorStream, "transpiration.csv.bz2", "w") do stream
    CSV.write(stream, transpiration_df)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
CodecBzip2 = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
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
project_hash = "51c6d4e2e1d2b0ffff6ace64990942e120b30cb2"

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
# ╟─6b8526e4-b297-11ed-1c66-470f26a581c7
# ╠═6685ea8b-7a27-4e62-9ce8-82955a06fd58
# ╟─a7b313b8-2f6f-43c1-a39b-ada77982a31e
# ╠═7027478e-8ba6-4b17-9448-628114d73816
# ╟─d631a6a0-4842-4d28-b6ad-f82093fe8581
# ╠═c8f60ef9-2caa-46de-ab51-11de279a678b
# ╟─39fbd542-3f1b-4327-b8fb-ab56f8af1682
# ╟─3ff85909-c02b-471c-b649-fa51c2df7b12
# ╠═c41298a7-108a-4a30-927c-359d4eb10b01
# ╟─8ddc6990-6c42-4ba8-9363-9726dc695db0
# ╠═fe844dad-d2d5-4cb9-97be-6277c405ed86
# ╟─6b81d83c-e139-46b4-bc4f-2110cdaa42f0
# ╠═6056cd3b-6277-4c88-9481-76a6b1efdb75
# ╟─a83879cd-1fd5-4306-9bf7-49074229f842
# ╠═e4ee7511-75c9-4a0e-9c75-f11516eaaafa
# ╟─6f1549b9-4bf9-4d09-9ce9-b36aa92ac9f1
# ╠═d9bca3d6-6076-45c6-8f90-cf1d4fb9cb56
# ╟─3ec8ee51-c26f-4771-95ef-f24e1698ea5f
# ╠═3fb32c18-bdd2-44bb-a635-ebb5682a5956
# ╟─8948f7cf-1105-4c8d-a5e5-3dbc5dbd0c60
# ╠═9caab45e-f33b-4b54-a7de-7f7035144f0e
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
