program define pipsb
    version 14.0
    syntax [, ppp_year(integer 2021) filename(string) release(string) listreleases]

    local token `"$GPID_GITHUB_TOKEN"'
    local repo_owner "GPID-WB"
    local repo_name  "pip-sandbox"

    if "`release'" == "" {
        local release "latest"
    }

    _pipsb_validate_environment, token("`token'")

    if "`listreleases'" != "" {
        _pipsb_list_releases, token("`token'") repoowner("`repo_owner'") reponame("`repo_name'")
        exit
    }

    if !inlist(`ppp_year', 2017, 2021) {
        di as error "ppp_year() must be 2017 or 2021"
        exit 198
    }

    _pipsb_resolve_release, token("`token'") repoowner("`repo_owner'") reponame("`repo_name'") release("`release'")
    local repo_ref `"`s(release)'"'

    tempfile catalog
    _pipsb_get_catalog, token("`token'") repoowner("`repo_owner'") reponame("`repo_name'") release("`repo_ref'") target("`catalog'")

    if "`filename'" == "" {
        _pipsb_list_files, catalog("`catalog'") pppyear(`ppp_year') release("`repo_ref'")
        exit
    }

    _pipsb_validate_filename, catalog("`catalog'") pppyear(`ppp_year') filename("`filename'")

    local data_path "data/`ppp_year'/`filename'.dta"
    local url "https://api.github.com/repos/`repo_owner'/`repo_name'/contents/`data_path'?ref=`repo_ref'"
    tempfile tmpdata

    di as text "Downloading `filename'.dta (PPP year `ppp_year', release `repo_ref') ..."
    _pipsb_fetch_github, ///
        url("`url'") ///
        token("`token'") ///
        accept("application/vnd.github.raw+json") ///
        target("`tmpdata'") ///
        resource("data file `data_path'")

    capture use "`tmpdata'", clear
    if _rc {
        local use_rc = _rc
        di as error "Downloaded file could not be opened as a Stata dataset."
        exit `use_rc'
    }

    di as text "Loaded: {bf:`filename'} | PPP year: {bf:`ppp_year'} | release: {bf:`repo_ref'}"
    di as res  _newline "(TESTING DATA ONLY - not official World Bank estimates)"
end

program define _pipsb_validate_environment
    version 14.0
    syntax , TOKEN(string)

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
end

program define _pipsb_fetch_github
    version 14.0
    syntax , URL(string) TOKEN(string) ACCEPT(string) TARGET(string) RESOURCE(string)

    tempfile statusfile errmsgfile

    capture quietly shell cmd /c curl.exe -L -sS -H "Authorization: Bearer `token'" -H "Accept: `accept'" -H "X-GitHub-Api-Version: 2022-11-28" -o "`target'" -w "%{http_code}" "`url'" > "`statusfile'" 2> "`errmsgfile'"
    local shell_rc = _rc

    capture confirm file "`statusfile'"
    if _rc {
        if `shell_rc' {
            di as error "curl exited before writing a status file (shell rc=`shell_rc')."
        }
        else {
            di as error "GitHub download failed before a status code was returned."
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
            di as error "GitHub could not find `resource'."
        }
        else {
            di as error "GitHub download failed for `resource' (HTTP `status_code')."
        }

        if "`status_message'" != "" {
            di as text "curl message: `status_message'"
        }
        exit 601
    }

    capture confirm file "`target'"
    if _rc {
        di as error "GitHub returned success for `resource', but no file was created."
        exit 601
    }
end

program define _pipsb_resolve_release, sclass
    version 14.0
    syntax , TOKEN(string) REPOOWNER(string) REPONAME(string) RELEASE(string)

    if lower("`release'") != "latest" {
        sreturn local release "`release'"
        exit
    }

    local url "https://api.github.com/repos/`repoowner'/`reponame'/releases/latest"
    tempfile releasejson

    _pipsb_fetch_github, ///
        url("`url'") ///
        token("`token'") ///
        accept("application/vnd.github+json") ///
        target("`releasejson'") ///
        resource("latest release metadata")

    file open releasefh using "`releasejson'", read text
    local response ""
    file read releasefh line
    while r(eof) == 0 {
        local response `"`response'`line'"'
        file read releasefh line
    }
    file close releasefh

    if !regexm(`"`response'"', `""tag_name"[ ]*:[ ]*"([^"]+)""') {
        di as error "Could not determine the latest release tag from GitHub."
        exit 498
    }

    sreturn local release `"`=regexs(1)'"'
end

program define _pipsb_list_releases
    version 14.0
    syntax , TOKEN(string) REPOOWNER(string) REPONAME(string)

    local url "https://api.github.com/repos/`repoowner'/`reponame'/releases"
    tempfile releasesjson

    di as text "Retrieving available releases ..."
    _pipsb_fetch_github, ///
        url("`url'") ///
        token("`token'") ///
        accept("application/vnd.github+json") ///
        target("`releasesjson'") ///
        resource("release list")

    file open releasefh using "`releasesjson'", read text
    local response ""
    file read releasefh line
    while r(eof) == 0 {
        local response `"`response'`line'"'
        file read releasefh line
    }
    file close releasefh

    local remaining `"`response'"'
    local shown 0

    di as text _newline "{bf:Available releases from `repoowner'/`reponame':}"
    while regexm(`"`remaining'"', `""tag_name"[ ]*:[ ]*"([^"]+)""') {
        local ++shown
        local tag `"`=regexs(1)'"'
        local match `"`=regexs(0)'"'
        di as text "  `shown'. {bf:`tag'}"
        local remaining = subinstr(`"`remaining'"', `"`match'"', "", 1)
    }

    if !`shown' {
        di as text "  No releases found."
    }

    di as text _newline "Use {cmd:pipsb, release(<tag>) filename(syears)} to load a specific release."
end

program define _pipsb_get_catalog, sclass
    version 14.0
    syntax , TOKEN(string) REPOOWNER(string) REPONAME(string) RELEASE(string) TARGET(string)

    local catalog_path "data_catalog.csv"
    local url "https://api.github.com/repos/`repoowner'/`reponame'/contents/`catalog_path'?ref=`release'"

    _pipsb_fetch_github, ///
        url("`url'") ///
        token("`token'") ///
        accept("application/vnd.github.raw+json") ///
        target("`target'") ///
        resource("catalog file `catalog_path' for release `release'")
end

program define _pipsb_list_files
    version 14.0
    syntax , CATALOG(string) PPPYEAR(integer) RELEASE(string)

    preserve
    quietly import delimited using "`catalog'", clear varnames(1) stringcols(_all)

    capture confirm variable file_name
    if _rc {
        restore
        di as error "The downloaded catalog is missing the file_name column."
        exit 498
    }

    capture confirm variable label
    if _rc {
        restore
        di as error "The downloaded catalog is missing the label column."
        exit 498
    }

    local extvar ""
    capture confirm variable extension
    if !_rc {
        local extvar "extension"
    }
    else {
        capture confirm variable ext
        if !_rc {
            local extvar "ext"
        }
    }

    if "`extvar'" == "" {
        restore
        di as error "The downloaded catalog is missing the extension column."
        exit 498
    }

    quietly keep if lower(trim(`extvar')) == "dta"
    quietly keep if trim(ppp_year) == "`pppyear'"
    quietly sort file_name

    if _N == 0 {
        restore
        di as error "No .dta files were found in the catalog for PPP year `pppyear' and release `release'."
        exit 498
    }

    di as text _newline "{bf:Available .dta files for PPP year `pppyear' | release `release':}"
    capture confirm variable last_modified
    if !_rc {
        list file_name label last_modified, noobs clean sep(0) abbreviate(32)
    }
    else {
        list file_name label, noobs clean sep(0) abbreviate(32)
    }
    di as text _newline `"Specify one, e.g.: {cmd:pipsb, ppp_year(`pppyear') filename(syears) release(`release')}"'
    restore
end

program define _pipsb_validate_filename, sclass
    version 14.0
    syntax , CATALOG(string) PPPYEAR(integer) FILENAME(string)

    preserve
    quietly import delimited using "`catalog'", clear varnames(1) stringcols(_all)

    local extvar ""
    capture confirm variable extension
    if !_rc {
        local extvar "extension"
    }
    else {
        capture confirm variable ext
        if !_rc {
            local extvar "ext"
        }
    }

    if "`extvar'" == "" {
        restore
        di as error "The downloaded catalog is missing the extension column."
        exit 498
    }

    quietly keep if lower(trim(`extvar')) == "dta"
    quietly keep if trim(ppp_year) == "`pppyear'"

    capture confirm variable file_name
    if _rc {
        restore
        di as error "The downloaded catalog is missing the file_name column."
        exit 498
    }

    quietly levelsof file_name, local(valid_files) clean
    quietly count if trim(file_name) == "`filename'"
    if r(N) == 0 {
        restore
        di as error "filename() must match one of the catalog entries for PPP year `pppyear': `valid_files'"
        exit 198
    }

    capture confirm variable label
    if !_rc {
        quietly levelsof label if trim(file_name) == "`filename'", local(file_label) clean
        sreturn local label `"`file_label'"'
    }

    restore
end
