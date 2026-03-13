program define pipsb
    version 14.0
    syntax [, ppp_year(integer 2021) filename(string)]

    local token `"$GPID_GITHUB_TOKEN"'
    local repo_owner "GPID-WB"
    local repo_name  "pip-sandbox"
    local repo_ref   "main"

    // If no filename given, list available files and exit
    if "`filename'" == "" {
        di as text _newline "{bf:Available files for PPP year `ppp_year':}"
        di as text "  {bf:syears}      Survey-year poverty estimates"
        di as text "  {bf:lyears}      Lineup (gap-filled) poverty estimates"
        di as text "  {bf:aggregates}  Regional aggregates (by World Bank region)"
        di as text _newline "Specify one, e.g.:"
        di as text `"  {cmd:pipsb, ppp_year(`ppp_year') filename(syears)}"'
        exit
    }

    // Validate ppp_year
    if !inlist(`ppp_year', 2017, 2021) {
        di as error "ppp_year() must be 2017 or 2021"
        exit 198
    }

    // Validate filename
    if !inlist("`filename'", "syears", "lyears", "aggregates") {
        di as error "filename() must be one of: syears, lyears, aggregates"
        exit 198
    }

    if "`token'" == "" {
        di as error "Global macro GPID_GITHUB_TOKEN is not set."
        di as text  "Add it to profile.do, for example:"
        di as text  `"  {cmd:global GPID_GITHUB_TOKEN \"<your GitHub token>\"}"'
        exit 198
    }

    if c(os) != "Windows" {
        di as error "pipsb private downloads currently require Windows."
        exit 198
    }

    // Build authenticated GitHub API URL for the private data repository
    local data_path "data/`ppp_year'/`filename'.dta"
    local url "https://api.github.com/repos/`repo_owner'/`repo_name'/contents/`data_path'?ref=`repo_ref'"

    // Download to tempfile and load without saving a permanent file on disk
    tempfile tmpdata statusfile errmsgfile

    di as text "Downloading `filename'.dta (PPP year `ppp_year') ..."
    capture quietly shell cmd /c curl.exe -L -sS -H "Authorization: Bearer `token'" -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2022-11-28" -o "`tmpdata'" -w "%{http_code}" "`url'" > "`statusfile'" 2> "`errmsgfile'"
    local shell_rc = _rc

    capture confirm file "`statusfile'"
    if _rc {
        if `shell_rc' {
            di as error "curl exited before writing a status file (shell rc=`shell_rc')."
        }
        else {
            di as error "GitHub download failed before PowerShell returned a status."
        }
        exit 601
    }

    file open status using "`statusfile'", read text
    file read status status_code
    file close status

    local status_message ""
    capture confirm file "`errmsgfile'"
    if !_rc {
        file open err using "`errmsgfile'", read text
        file read err status_message
        file close err
    }

    if "`status_code'" != "200" {
        if inlist("`status_code'", "401", "403") {
            di as error "GitHub authentication failed. Check GPID_GITHUB_TOKEN in profile.do."
        }
        else if "`status_code'" == "404" {
            di as error "Private data file not found: `data_path'"
        }
        else {
            di as error "GitHub download failed (HTTP `status_code')."
        }

        if "`status_message'" != "" {
            di as text "curl message: `status_message'"
        }
        exit 601
    }

    capture confirm file "`tmpdata'"
    if _rc {
        di as error "Download completed without creating a Stata data file."
        exit 601
    }

    capture use "`tmpdata'", clear
    if _rc {
        local use_rc = _rc
        di as error "Downloaded file could not be opened as a Stata dataset."
        exit `use_rc'
    }

    di as text "Loaded: {bf:`filename'} | PPP year: {bf:`ppp_year'}"
    di as res  _newline "(TESTING DATA ONLY - not official World Bank estimates)"
end
