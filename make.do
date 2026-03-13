// the 'make.do' file is automatically created by 'github' package.
// execute the code below to generate the package installation files.
// DO NOT FORGET to update the version of the package, if changed!
// for more information visit http://github.com/haghish/github

*##s

cap program drop getfiles
program define getfiles, rclass

    args mask excl

    local f2add: dir . files "`mask'", respectcase

    foreach a of local f2add {
        local as "`as' `a'"
    }
    local as = trim("`as'")

    // exclude files
    if ("`excl'" != "") {
        local as: list as - excl
    }

    local as: subinstr local as " " ";", all

    return local files = "`as'"

end

if ("`c(username)'" == "wb384996") {
    cd "C:\Users\wb384996\OneDrive - WBG\ado\myados\pipsb"
}

getfiles "*.ado" "run_tests.ado"
local as = "`r(files)'"
disp `"`as'"'


getfiles "*.sthlp"
local hs = "`r(files)'"

getfiles "*.mata"
local ms = "`r(files)'"


getfiles "*.dlg"
local ds = "`r(files)'"

getfiles "*.dta"
local dtas = "`r(files)'"


local toins  "`as';`hs';`ms';`ds';`dtas'"
disp "`toins'"


make pipsb, replace toc pkg                            ///  readme
	version(0.0.1)                                   ///
    license("MIT")                                         ///
   author(`"R.Andres Castaneda"')                ///
    affiliation(`"The World Bank"')                ///
    email(`"acastanedaa@worldbank.org"')                     ///
    url("")                                                ///
    title("Download PIP sandbox test data into Stata memory") ///
    description("TESTING PURPOSES ONLY. Data is fake and does not reflect any official estimates by the World Bank Group or its members.") ///
    install("`toins'")                                     ///
    ancillary("")                                                         

*##e
