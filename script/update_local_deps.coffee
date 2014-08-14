#!/usr/bin/env coffee

###
Update locally served deps
###

{ exec } = require('child_process')
path     = require('path')
fs       = require('fs')


# HubSpot Static Config File
HOME = process.env.HOME
CONFIG = path.join(HOME, '.hubspot/config.yaml')
REMOTE = 'origin'


fs.exists CONFIG, (exists) ->
  if exists
    console.log "[#{CONFIG}] exists"
    readFile(CONFIG)
  else
    process.exit(1)


readFile = (file) ->
  fs.readFile file, (err, buffer) ->
    throw err if err
    parseFile buffer.toString()


parseFile = (content) ->
  matches = []
  REGEX = new RegExp('^\\s*-\\s*(.*)$', 'ig')
  lines = content.split('\n')
  for line in lines
    match = line.match REGEX
    matches.push(match[0]) if match
  sanitizeMatches(matches)


sanitizeMatches = (matches) ->
  paths = []
  REGEX1 = [ new RegExp('^\\s*-\\s*', 'g'), '' ]
  REGEX2 = [ new RegExp('^~', 'g'), HOME ]
  REGEX3 = [ new RegExp('[/\]?[\*]$', 'g'), '' ]
  for match in matches
    paths.push sequentialReplace(match, REGEX1, REGEX2, REGEX3)
  console.log 'Not ready yet...'
  # updateDeps(paths)


sequentialReplace = (str, regexes...) ->
  for regex in regexes
    str = str.replace(regex[0], regex[1])
  str


updateDeps = (paths) ->
  for dep in paths
    OPTS = { cwd: dep }

    CMDS1 = [
      "git branch --all"
    ].join(' && ')

    CMDS2 = [
      'git stash'
      'git fetch -p --all'
    ].join(' && ')

    CMDS3 = [
      'git stash pop'
    ].join(' && ')

    exec CMDS1, OPTS, (err, stdout, stderr) ->
      throw err if err
      allBranches = parseBranches(stdout.split('\n'))
      branches = getSyncedBranches(allBranches)

      exec CMDS2, OPTS, (err, stdout, stderr) ->
        throw err if err
        PULLCMD = createPullCommand(branches)

        exec PULLCMD, OPTS, (err, stdout, stderr) ->
          throw err if err

          exec CMDS3, OPTS, (err, stdout, stderr) ->
            throw err if err
            projectName = path.basename(dep)
            console.log "Branches in #{projectName} update to date"


parseBranches = (branches) ->
  sanitizedBranches = []
  REGEX = /^\*\s*(.*)$/
  for branch in branches when branch.trim().length
    if match = branch.match(REGEX)
      currentBranch = match[1].trim()
    else
      sanitizedBranches.push branch.trim()
  sanitizedBranches.push currentBranch
  sanitizedBranches


getSyncedBranches = (branches) ->
  goodBranches = []
  localBranches = []
  remoteBranches = []
  REGEX = new RegExp("^remotes\/#{REMOTE}\/([^ ]+)")
  for branch in branches
    if match = branch.match(REGEX)
      remoteBranches.push match[1]
    else
      localBranches.push branch
  for branch in localBranches
    if branch in remoteBranches
      goodBranches.push branch
  goodBranches


createPullCommand = (branches) ->
  cmds = []
  for branch in branches
    cmds.push "git checkout #{branch} && git pull"
  cmds.join(' && ')


# # Colors
# red='\e[0;31m'
# green='\e[0;32m'
# yellow='\e[0;33m'
# blue='\e[0;34m'
# reset='\e[0m'

# # Start
# printf "${blue}=========================================================${reset}\n"
# printf "${yellow}                 Updating Git Submodules                ${reset}\n"
# printf "${blue}=========================================================${reset}\n"

# # Cache location of directory
# if [[ "$1" = "" ]]; then
#     dir=$DOT/vim/bundle  # vim-plugin dir
# else
#     dir="$1"
# fi

# # Cache original location
# original_location=$(pwd)

# # Change to the vim-plugins directory
# printf "\nChanging to the ${red}vim bundles${reset} directory ...\n"
# cd $dir

# # gather plugins
# files=(`ls`)    # get list of bundles
# ignores=()      # list of dir to ignore
# edgecases=($DOT/terminal/flat-terminal $DOT/zsh-plugins/zsh-syntax-highlighting)  # edge case submodules

# # Filter out ignores and add edgecases
# for ignore in "${ignores[@]}"; do
#     files=(${files[@]//*$ignore*})
# done
# for edgecase in "${edgecases[@]}"; do
#     files+=($edgecase)
# done

# # Update submodules
# for file in "${files[@]}"; do
#     cd $file
#     printf "\n\nUpdating ${red}%-30s${reset}\r" "{$(basename $file)}"
#     git checkout -q master
#     git pull --rebase 2>&1 | grep -q "up to date." && UTD="" || UTD="*"
#     if [[ "$UTD" = "*" ]]; then
#         printf "Updating ${red}%-38.38s${reset}${yellow}%10s${reset}" "{$(basename $file)}" '[Updated]'
#     else
#         printf "Updating ${red}%-35.35s${reset}${green}%13s${reset}" "{$(basename $file)}" '[Up to date]'
#     fi
#     cd $dir
# done

# # Return to original location
# cd $original_location

# # notify finish
# printf "${green}\n\nPlugin updating completed.${reset}\n"

