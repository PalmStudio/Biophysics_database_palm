Dict(
    :main => [
        "homepage" => collections["homepage"].pages,
        "welcome" => collections["welcome"].pages,
        "Climate" => collections["climate"].pages,
        "Time-synchronization" => collections["timesync"].pages,
        "CO2 fluxes" => collections["co2"].pages,
        "Thermal camera" => collections["thermal"].pages,
        "Transpiration" => collections["transpiration"].pages,
        "Photosynthesis and stomates" => collections["walz"].pages,
        "SPAD" => collections["spad"].pages,
        "Database" => collections["database"].pages,
        ],
    :about => Dict(
        :authors => [
            (name = "Raphaël Pérez et al.", url = "https://github.com/PalmStudio/Biophysics_database_palm"),
        ],
        :title => "A Comprehensive Database of Leaf Temperature, Water, and CO2 Fluxes",
        :subtitle => "in Young Oil Palm Plants Across Diverse Climate Scenarios for the Evaluation of Functional-Structural Models",
        :term => "July 2024",
        :institution => "CIRAD",
        :institution_url => "http://www.cirad.fr",
        :institution_logo => "palmstudio.png",
        :institution_logo_darkmode => "palmstudio.png"
    )
)