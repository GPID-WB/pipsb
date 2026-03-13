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
        di as error "pipsb private downloads currently require Windows PowerShell."
        exit 198
    }

    // Build authenticated GitHub API URL for the private data repository
    local data_path "data/`ppp_year'/`filename'.dta"
    local url "https://api.github.com/repos/`repo_owner'/`repo_name'/contents/`data_path'?ref=`repo_ref'"

    // Download to tempfile and load without saving a permanent file on disk
    tempfile tmpdata psscript statusfile
    local token_ps  = subinstr(`"`token'"', "'", "''", .)
    local url_ps    = subinstr(`"`url'"', "'", "''", .)
    local tmpdata_ps = subinstr(`"`tmpdata'"', "'", "''", .)
    local status_ps  = subinstr(`"`statusfile'"', "'", "''", .)
    local dollar = char(36)

    file open ps using "`psscript'", write text replace
    file write ps `"`dollar'ErrorActionPreference = 'Stop'"' _n
    file write ps `"`dollar'headers = @{"' _n
    file write ps `"    Authorization = 'Bearer `token_ps''"' _n
    file write ps `"    Accept = 'application/vnd.github.raw+json'"' _n
    file write ps `"    'X-GitHub-Api-Version' = '2022-11-28'"' _n
    file write ps `"}"' _n
    file write ps `"try {"' _n
    file write ps `"    Invoke-WebRequest -Headers `dollar'headers -Uri '`url_ps'' -OutFile '`tmpdata_ps'' -UseBasicParsing | Out-Null"' _n
    file write ps `"    Set-Content -Path '`status_ps'' -Value '0'"' _n
    file write ps `"    exit 0"' _n
    file write ps `"}"' _n
    file write ps `"catch {"' _n
    file write ps `"    `dollar'statusCode = ''"' _n
    file write ps `"    if (`dollar'_.Exception.Response -and `dollar'_.Exception.Response.StatusCode) {"' _n
    file write ps `"        `dollar'statusCode = [int] `dollar'_.Exception.Response.StatusCode.value__"' _n
    file write ps `"    }"' _n
    file write ps `"    `dollar'message = `dollar'_.Exception.Message"' _n
    file write ps `"    if (`dollar'message) {"' _n
    file write ps `"        `dollar'message = `dollar'message -replace '[\r\n]+', ' '"' _n
    file write ps `"    }"' _n
    file write ps `"    Set-Content -Path '`status_ps'' -Value `dollar'statusCode"' _n
    file write ps `"    Add-Content -Path '`status_ps'' -Value `dollar'message"' _n
    file write ps `"    exit 1"' _n
    file write ps `"}"' _n
    file close ps

    di as text "Downloading `filename'.dta (PPP year `ppp_year') ..."
    capture quietly shell powershell -NoProfile -ExecutionPolicy Bypass -File "`psscript'"

    capture confirm file "`statusfile'"
    if _rc {
        di as error "GitHub download failed before PowerShell returned a status."
        exit 601
    }

    file open status using "`statusfile'", read text
    file read status status_code
    file read status status_message
    file close status

    if "`status_code'" != "0" {
        if inlist("`status_code'", "401", "403") {
            di as error "GitHub authentication failed. Check GPID_GITHUB_TOKEN in profile.do."
        }
        else if "`status_code'" == "404" {
            di as error "Private data file not found: `data_path'"
        }
        else {
            di as error "GitHub download failed."
        }

        if "`status_message'" != "" {
            di as text "PowerShell message: `status_message'"
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
