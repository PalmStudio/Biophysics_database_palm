using DataFrames
using Plots
using CSV
using PlantBiophysics
using Dates
constants = Constants()

# Load data 
df = DataFrame(CSV.File("./climate_walz_area.csv"))

uncert = false

# Simulate data
(!uncert) && (df[!, :Tleaf_sim] .= df[!,:E_sim] .= df[!, :λE_sim] .= df[!,:Rn_sim] .= df[!, :H_sim] .= df[!, :A_sim] .= df[!, :GH2O_sim] .= df[!, :ci_sim] .= df[!, :VPD_sim] .= 0.)
(uncert) && (df[!, :Tleaf_sim] .= df[!,:E_sim] .= df[!, :λE_sim] .= df[!,:Rn_sim] .= df[!, :H_sim] .= df[!, :A_sim] .= df[!, :GH2O_sim] .= df[!, :ci_sim] .= df[!, :VPD_sim] .= 0. ± 0.)
for i in 1:size(df,1)
    # Calculate some variables calculated with measurements

    # ue is wind velocity, taken arbitrarily as 20 m/s (uniform law between 20 and 30 if uncertainties are allowed)
    ue = 20.
    (uncert) && (ue = 20 .. 30)

    # Air temperature in °C
    Ta = df[i,"Ta_measurement"] 
    (uncert) && (Ta = Ta ± 0.1)

    # Ambient pressure in kPa
    Pa = 101.325
    (uncert) && (Pa = Pa ± 0.001*Pa)

    # PPFD in μmol/(m²s¹)
    PPFD = df[i,"R_measurement"]
    (uncert) && (PPFD = PPFD ± 0.1*PPFD)

    # Rₛ net shortwave radiation (PAR + NIR) in W/m²
    Rs = (PPFD)/4.57  
    (uncert) && (Rs = Rs ± 0.1*Rs)

    # rh relative humidity 
    rh = df.Rh_measurement[i]/100
    (uncert) && (rh = rh ± 0.01)

    # Cₐ air concentration in CO2 in ppm
    ca = convert(Float64,df[i,"CO2_ppm"])
    (uncert) && (ca = ca ± 1.)

    # Characteristic distance (width) in m
    dist = 0.15 #lets try 15
    (uncert) && (dist = 0.01 .. 0.03)

    # If there is no TPU reference, then TPU is not taken into account (ie TPU >>> VcMax,Jmax)
    TPU = 999999
    if (typeof(df.TPU[i])<:Number)
        TPU = df.TPU[i]
    end

    meteo = Atmosphere(T = Ta, Wind = ue, P = Pa, Rh = rh ,Cₐ= ca)
    leaf = LeafModels(energy = Monteith(aₛₕ=2,aₛᵥ=2,ε=0.98),
                photosynthesis = Fvcb(VcMaxRef=df.Vcmax[i],JMaxRef=df.Jmax[i],RdRef=df.Rd[i],TPURef=TPU),
                stomatal_conductance = Medlyn(df.g0[i]/1.57, df.g1[1]/1.57), # Stomatal conductance to H2O converted to stomatal conductance to CO2
                Rₛ = Rs, skyFraction =1., 
                PPFD = PPFD, d = dist)

    # Computation
    energy_balance!(leaf,meteo)

    # Update simulations columns
    df.GH2O_sim[i] = leaf.status.Gₛ * 1000 * 1.57    # Stomatal conductance to H2O
    df.Tleaf_sim[i] = leaf.status.Tₗ                 # Leaf temperature
    df.E_sim[i] = leaf.status.λE /(meteo.λ * constants.Mₕ₂ₒ) * 1000   # Transpiration
    df.H_sim[i]  = leaf.status.H                     # Sensible heat
    df.A_sim[i]  = leaf.status.A                     # Net assimilation of CO2
    df.ci_sim[i] = leaf.status.Cᵢ                    # Intercellular concentration in CO2
    df.VPD_sim[i] = leaf.status.Dₗ * 1000 / meteo.P  # VPD
    df.Rn_sim[i] = leaf.status.Rn                    # Net radiation
    df.λE_sim[i] = leaf.status.λE                    # Latent heat
end



"""

"""
function filter_df(df::DataFrame,plant::String)
    if length(plant) != 2
        throw(ArgumentError("Invalid plant name (need shape as PX)"))
    end
    return filter(x->occursin(r"^"*plant,x.id_walz),df)
end

function filter_df(df::DataFrame,plant::String, leaf::String)
    if (length(plant) != 2)|(length(leaf) != 2)
        throw(ArgumentError("Invalid plant or leaf names (need shape as PX, FX)"))
    end
    return filter(x->occursin(r"^"*plant*leaf,x.id_walz),df)
end

function filter_df(df::DataFrame,plant::String, leaf::String, paramdate::String)
    if (length(plant) != 2)|(length(leaf) != 2)|(length(paramdate) != 4)
        throw(ArgumentError("Invalid plant, leaf or parameter date names (need shape as PX, FX, XXXX)"))
    end
    return filter(x->occursin(r"^"*plant*leaf*paramdate,x.id_walz),df)
end

function filter_df(df::DataFrame,plant::String, leaf::String, paramdate::String, date::DateTime)
    if (length(plant) != 2)|(length(leaf) != 2)|(length(paramdate) != 4)
        throw(ArgumentError("Invalid plant, leaf or parameter date names (need shape as PX, FX, XXXX)"))
    end
    return filter(x->occursin(r"^"*plant*leaf*paramdate,x.id_walz)&(x.Date==date),df)
end

function filter_df(df::DataFrame,plant::String, leaf::String, paramdate::String, scenario::String)
    if (length(plant) != 2)|(length(leaf) != 2)|(length(paramdate) != 4)
        throw(ArgumentError("Invalid plant, leaf or parameter date names (need shape as PX, FX, XXXX)"))
    end
    return filter(x->occursin(r"^"*plant*leaf*paramdate,x.id_walz)&(x.Scenario==scenario),df)
end

function separate_scenarios_per_leaf(df::DataFrame,leaf::String)
    df_leaf = filter_df(df,leaf[1:2],leaf[3:4],leaf[5:8])
    D = Dict()
    for S in unique(df_leaf.Scenario)
        D[S] = filter(x->x.Scenario==S,df_leaf)
    end
    return D
end



df_day = filter(x->x.Date==DateTime(2021,3,2),df_leaf)

df_400   = filter(x->x.Scenario=="400ppm",df_leaf)
df_cloud = filter(x->x.Scenario=="Cloudy",df_leaf)
df_600   = filter(x->x.Scenario=="600ppm",df_leaf)

D = Dict()
D["o"] = 3



ind = sortperm(df_day.ci_sim)
plot(df_day.ci_sim[ind],df_day.A_sim[ind])


plot(df_400.A_sim,label="400ppm")
plot!(df_cloud.A_sim,label="Cloudy")
plot!(df_600.A_sim,label="600ppm")



