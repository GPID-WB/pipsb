{smcl}
{* 2026-03-13}{...}
{hline}
Help for {bf:pipsb}
{hline}

{title:Title}

{p 4 4 2}
{bf:pipsb} {hline 2} Download PIP sandbox test data into Stata memory

{title:Warning}

{p 4 4 2}
{err:TESTING PURPOSES ONLY.} All data is {bf:fake} and does {bf:not} reflect
any official estimates by the World Bank Group or its members. Do not cite,
reference, or use for any analytical or policy purpose.

{title:Syntax}

{p 8 16 2}
{cmd:pipsb}
[{cmd:,} {opt ppp_year(#)} {opt filename(name)} {opt release(tag)} {opt listreleases}]

{title:Options}

{phang}
{opt ppp_year(#)} specifies the PPP revision year. Must be {bf:2017} or
{bf:2021}. Default is {bf:2021}.

{phang}
{opt filename(name)} specifies the dataset to load. Must be one of:

{p 8 8 2}
The available values are read from {bf:data_catalog.csv} in the private data
repository for the selected release and filtered to {bf:extension = dta} and
the requested {opt ppp_year()}. If {opt filename()} is omitted, {cmd:pipsb}
lists the available files for that PPP year and exits without loading data.

{phang}
{opt release(tag)} specifies the data release tag to use. If omitted,
{cmd:pipsb} uses the {bf:latest} GitHub release from the private data
repository.

{phang}
{opt listreleases} lists all available release tags from the private data
repository and exits without loading data.

{title:Description}

{p 4 4 2}
{cmd:pipsb} downloads a {bf:.dta} file from the private data repository
{bf:GPID-WB/pip-sandbox} and loads it into memory using {cmd:use}. The
command first resolves a release tag, downloads {bf:data_catalog.csv} from the
root of that release, filters the catalog to the requested {opt ppp_year()} and
Stata files, and then downloads the requested dataset. The command
authenticates with a GitHub personal access token stored in the global macro
{cmd:GPID_GITHUB_TOKEN}. No permanent file is saved to disk.

{title:Setup}

{p 4 4 2}
Before using {cmd:pipsb}, define the global macro
{cmd:GPID_GITHUB_TOKEN} in your local {cmd:profile.do}. For example:

{phang2}{cmd:global GPID_GITHUB_TOKEN "<your GitHub token>"}{p_end}

{p 4 4 2}
Each user should create and store their own token locally. Do not commit
tokens to a repository, shared do-file, or project configuration file.

{p 4 4 2}
The token should be a fine-grained GitHub personal access token with
{bf:Contents: Read} permission on the private data repository
{bf:GPID-WB/pip-sandbox}. Depending on organization settings, SSO
authorization or admin approval may also be required.

{p 4 4 2}
After updating {cmd:profile.do}, restart Stata and verify the token with
{cmd:display "$GPID_GITHUB_TOKEN"}.

{p 4 4 2}
This implementation currently supports Windows and uses {cmd:curl.exe} for
authenticated downloads.

{title:Examples}

{phang2}{cmd:. pipsb}{p_end}
{phang2}(lists available .dta files for PPP year 2021 in the latest release)

{phang2}{cmd:. pipsb, listreleases}{p_end}
{phang2}(lists all available release tags)

{phang2}{cmd:. pipsb, filename(syears)}{p_end}
{phang2}(loads 2021 PPP survey-year estimates from the latest release)

{phang2}{cmd:. pipsb, ppp_year(2017) filename(aggregates) release(202603131536)}{p_end}
{phang2}(loads 2017 PPP regional aggregates from a specific release)

{title:Repository}

{p 4 4 2}
The Stata package repository is {bf:GPID-WB/pipsb}. Runtime data downloads are
served from the separate private data repository {bf:GPID-WB/pip-sandbox}.

{title:Installation}

{p 4 4 2}
Requires the {browse "https://github.com/haghish/github":github} package:

{phang2}{cmd:. net install github, from("https://haghish.github.io/github/")}{p_end}
{phang2}{cmd:. github install GPID-WB/pipsb}{p_end}

{marker authors}{...}
{title:Authors}

{p 4 4 4}R.Andres Castaneda, Data Group, Department of Development Economics, The World Bank{p_end}
{p 6 6 4}Email: {browse "mailto: acastanedaa@worldbank.org":  acastanedaa@worldbank.org}{p_end}
{p 6 6 4}GitHub:{browse "https://github.com/randrescastaneda": randrescastaneda }{p_end}


{p 4 4 2}
GPID Team, World Bank Group

{hline}
