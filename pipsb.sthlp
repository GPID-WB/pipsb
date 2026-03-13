{smcl}
{* 2026-03-12}{...}
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
[{cmd:,} {opt ppp_year(#)} {opt filename(name)}]

{title:Options}

{phang}
{opt ppp_year(#)} specifies the PPP revision year. Must be {bf:2017} or
{bf:2021}. Default is {bf:2021}.

{phang}
{opt filename(name)} specifies the dataset to load. Must be one of:

{p2colset 12 28 30 2}
{p2col:{bf:syears}}Survey-year poverty estimates{p_end}
{p2col:{bf:lyears}}Lineup (gap-filled) poverty estimates{p_end}
{p2col:{bf:aggregates}}Regional aggregates (World Bank regions){p_end}

{phang}
If {opt filename()} is omitted, {cmd:pipsb} lists the available files
and exits without loading any data.

{title:Description}

{p 4 4 2}
{cmd:pipsb} downloads a {bf:.dta} file from a private GitHub repository
and loads it into memory using {cmd:use}. The command authenticates with a
GitHub personal access token stored in the global macro
{cmd:GPID_GITHUB_TOKEN}. No permanent file is saved to disk.

{title:Setup}

{p 4 4 2}
Before using {cmd:pipsb}, define the global macro
{cmd:GPID_GITHUB_TOKEN} in your local {cmd:profile.do}. For example:

{phang2}{cmd:global GPID_GITHUB_TOKEN "<your GitHub token>"}{p_end}

{p 4 4 2}
Each user should store their own token locally. Do not commit tokens to a
repository, shared do-file, or project configuration file.

{p 4 4 2}
The token should be a fine-grained GitHub personal access token with
{bf:Contents: Read} permission on the private data repository.

{p 4 4 2}
This implementation currently uses Windows PowerShell for authenticated
downloads.

{title:Examples}

{phang2}{cmd:. pipsb}{p_end}
{phang2}(lists available filenames for the default PPP year 2021)

{phang2}{cmd:. pipsb, filename(syears)}{p_end}
{phang2}(loads 2021 PPP survey-year estimates)

{phang2}{cmd:. pipsb, ppp_year(2017) filename(aggregates)}{p_end}
{phang2}(loads 2017 PPP regional aggregates)

{title:Repository}

{p 4 4 2}
The Stata package can be distributed separately from the private data
repository.

{title:Installation}

{p 4 4 2}
Requires the {browse "https://github.com/haghish/github":github} package:

{phang2}{cmd:. net install github, from("https://haghish.github.io/github/")}{p_end}
{phang2}{cmd:. github install GPID-WB/pip-sandbox}{p_end}

{title:Author}

{p 4 4 2}
GPID Team, World Bank Group

{hline}
