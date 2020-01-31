export TERM="xterm-256color"
export TF_VAR_ssh_pub_key=/Users/yurix/.ssh/id_rsa.pub

ZSH_THEME="powerlevel9k/powerlevel9k"
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/yurix/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh
source $HOME/.cargo/env
source $ZSH/asp.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform

alias tf=terraform
alias g=git

  aws-profiles() {
    cat ~/.aws/credentials | grep '\[' | grep -v '#' | tr -d '[' | tr -d ']'
  }

  set-aws-profile() {
    local aws_profile=$1
    set -x
    export AWS_PROFILE=${aws_profile}
    set +x
  }

  set-aws-keys() {
    local aws_profile=$1
    profile_data=$(cat ~/.aws/credentials | grep "\[$aws_profile\]" -A4)
    AWS_ACCESS_KEY_ID="$(echo $profile_data | grep aws_access_key_id | cut -f2 -d'=' | tr -d ' ')"
    AWS_SECRET_ACCESS_KEY="$(echo $profile_data | grep aws_secret_access_key | cut -f2 -d'=' | tr -d ' ')"
    set -x
    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
    set +x
  }

export PATH="/usr/local/opt/llvm/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/llvm/lib"
export CPPFLAGS="-I/usr/local/opt/llvm/include"

# GENERATED ALIASES FOR BASH-MY-AWS

alias __bma_error='~/.bash-my-aws/bin/bma __bma_error'
alias __bma_read_filters='~/.bash-my-aws/bin/bma __bma_read_filters'
alias __bma_read_inputs='~/.bash-my-aws/bin/bma __bma_read_inputs'
alias __bma_read_stdin='~/.bash-my-aws/bin/bma __bma_read_stdin'
alias __bma_usage='~/.bash-my-aws/bin/bma __bma_usage'
alias _bma_derive_params_from_stack_and_template='~/.bash-my-aws/bin/bma _bma_derive_params_from_stack_and_template'
alias _bma_derive_params_from_template='~/.bash-my-aws/bin/bma _bma_derive_params_from_template'
alias _bma_derive_stack_from_params='~/.bash-my-aws/bin/bma _bma_derive_stack_from_params'
alias _bma_derive_stack_from_template='~/.bash-my-aws/bin/bma _bma_derive_stack_from_template'
alias _bma_derive_template_from_params='~/.bash-my-aws/bin/bma _bma_derive_template_from_params'
alias _bma_derive_template_from_stack='~/.bash-my-aws/bin/bma _bma_derive_template_from_stack'
alias _bma_stack_args='~/.bash-my-aws/bin/bma _bma_stack_args'
alias _bma_stack_capabilities='~/.bash-my-aws/bin/bma _bma_stack_capabilities'
alias _bma_stack_diff_params='~/.bash-my-aws/bin/bma _bma_stack_diff_params'
alias _bma_stack_diff_template='~/.bash-my-aws/bin/bma _bma_stack_diff_template'
alias _bma_stack_name_arg='~/.bash-my-aws/bin/bma _bma_stack_name_arg'
alias _bma_stack_params_arg='~/.bash-my-aws/bin/bma _bma_stack_params_arg'
alias _bma_stack_template_arg='~/.bash-my-aws/bin/bma _bma_stack_template_arg'
alias asg-capacity='~/.bash-my-aws/bin/bma asg-capacity'
alias asg-desired-size-set='~/.bash-my-aws/bin/bma asg-desired-size-set'
alias asg-instances='~/.bash-my-aws/bin/bma asg-instances'
alias asg-launch-configuration='~/.bash-my-aws/bin/bma asg-launch-configuration'
alias asg-max-size-set='~/.bash-my-aws/bin/bma asg-max-size-set'
alias asg-min-size-set='~/.bash-my-aws/bin/bma asg-min-size-set'
alias asg-processes_suspended='~/.bash-my-aws/bin/bma asg-processes_suspended'
alias asg-resume='~/.bash-my-aws/bin/bma asg-resume'
alias asg-scaling-activities='~/.bash-my-aws/bin/bma asg-scaling-activities'
alias asg-stack='~/.bash-my-aws/bin/bma asg-stack'
alias asg-suspend='~/.bash-my-aws/bin/bma asg-suspend'
alias asgs='~/.bash-my-aws/bin/bma asgs'
alias aws-account-alias='~/.bash-my-aws/bin/bma aws-account-alias'
alias aws-account-cost-explorer='~/.bash-my-aws/bin/bma aws-account-cost-explorer'
alias aws-account-cost-recommendations='~/.bash-my-aws/bin/bma aws-account-cost-recommendations'
alias aws-account-each='~/.bash-my-aws/bin/bma aws-account-each'
alias aws-account-id='~/.bash-my-aws/bin/bma aws-account-id'
alias aws-panopticon='~/.bash-my-aws/bin/bma aws-panopticon'
alias bucket-acls='~/.bash-my-aws/bin/bma bucket-acls'
alias bucket-remove='~/.bash-my-aws/bin/bma bucket-remove'
alias bucket-remove-force='~/.bash-my-aws/bin/bma bucket-remove-force'
alias buckets='~/.bash-my-aws/bin/bma buckets'
alias cert-delete='~/.bash-my-aws/bin/bma cert-delete'
alias cert-users='~/.bash-my-aws/bin/bma cert-users'
alias certs='~/.bash-my-aws/bin/bma certs'
alias certs-arn='~/.bash-my-aws/bin/bma certs-arn'
alias cloudtrail-status='~/.bash-my-aws/bin/bma cloudtrail-status'
alias cloudtrails='~/.bash-my-aws/bin/bma cloudtrails'
alias columnise='~/.bash-my-aws/bin/bma columnise'
alias ecr-repositories='~/.bash-my-aws/bin/bma ecr-repositories'
alias ecr-repository-images='~/.bash-my-aws/bin/bma ecr-repository-images'
alias elb-dnsname='~/.bash-my-aws/bin/bma elb-dnsname'
alias elb-instances='~/.bash-my-aws/bin/bma elb-instances'
alias elb-stack='~/.bash-my-aws/bin/bma elb-stack'
alias elbs='~/.bash-my-aws/bin/bma elbs'
alias hosted-zones='~/.bash-my-aws/bin/bma hosted-zones'
alias iam-role-principal='~/.bash-my-aws/bin/bma iam-role-principal'
alias iam-roles='~/.bash-my-aws/bin/bma iam-roles'
alias image-deregister='~/.bash-my-aws/bin/bma image-deregister'
alias images='~/.bash-my-aws/bin/bma images'
alias instance-asg='~/.bash-my-aws/bin/bma instance-asg'
alias instance-az='~/.bash-my-aws/bin/bma instance-az'
alias instance-console='~/.bash-my-aws/bin/bma instance-console'
alias instance-dns='~/.bash-my-aws/bin/bma instance-dns'
alias instance-health-set-unhealthy='~/.bash-my-aws/bin/bma instance-health-set-unhealthy'
alias instance-iam-profile='~/.bash-my-aws/bin/bma instance-iam-profile'
alias instance-ip='~/.bash-my-aws/bin/bma instance-ip'
alias instance-ssh='~/.bash-my-aws/bin/bma instance-ssh'
alias instance-ssh-details='~/.bash-my-aws/bin/bma instance-ssh-details'
alias instance-stack='~/.bash-my-aws/bin/bma instance-stack'
alias instance-start='~/.bash-my-aws/bin/bma instance-start'
alias instance-state='~/.bash-my-aws/bin/bma instance-state'
alias instance-stop='~/.bash-my-aws/bin/bma instance-stop'
alias instance-tags='~/.bash-my-aws/bin/bma instance-tags'
alias instance-terminate='~/.bash-my-aws/bin/bma instance-terminate'
alias instance-termination-protection='~/.bash-my-aws/bin/bma instance-termination-protection'
alias instance-termination-protection-disable='~/.bash-my-aws/bin/bma instance-termination-protection-disable'
alias instance-termination-protection-enable='~/.bash-my-aws/bin/bma instance-termination-protection-enable'
alias instance-type='~/.bash-my-aws/bin/bma instance-type'
alias instance-userdata='~/.bash-my-aws/bin/bma instance-userdata'
alias instance-volumes='~/.bash-my-aws/bin/bma instance-volumes'
alias instance-vpc='~/.bash-my-aws/bin/bma instance-vpc'
alias instances='~/.bash-my-aws/bin/bma instances'
alias keypair-create='~/.bash-my-aws/bin/bma keypair-create'
alias keypair-delete='~/.bash-my-aws/bin/bma keypair-delete'
alias keypairs='~/.bash-my-aws/bin/bma keypairs'
alias kms-alias-create='~/.bash-my-aws/bin/bma kms-alias-create'
alias kms-alias-delete='~/.bash-my-aws/bin/bma kms-alias-delete'
alias kms-aliases='~/.bash-my-aws/bin/bma kms-aliases'
alias kms-decrypt='~/.bash-my-aws/bin/bma kms-decrypt'
alias kms-encrypt='~/.bash-my-aws/bin/bma kms-encrypt'
alias kms-key-create='~/.bash-my-aws/bin/bma kms-key-create'
alias kms-key-details='~/.bash-my-aws/bin/bma kms-key-details'
alias kms-key-schedule-deletion='~/.bash-my-aws/bin/bma kms-key-schedule-deletion'
alias kms-keys='~/.bash-my-aws/bin/bma kms-keys'
alias lambda-function-memory='~/.bash-my-aws/bin/bma lambda-function-memory'
alias lambda-function-memory-set='~/.bash-my-aws/bin/bma lambda-function-memory-set'
alias lambda-function-memory-step='~/.bash-my-aws/bin/bma lambda-function-memory-step'
alias lambda-functions='~/.bash-my-aws/bin/bma lambda-functions'
alias launch-configuration-asgs='~/.bash-my-aws/bin/bma launch-configuration-asgs'
alias launch-configurations='~/.bash-my-aws/bin/bma launch-configurations'
alias log-groups='~/.bash-my-aws/bin/bma log-groups'
alias pcxs='~/.bash-my-aws/bin/bma pcxs'
alias rds-db-instances='~/.bash-my-aws/bin/bma rds-db-instances'
alias region-each='~/.bash-my-aws/bin/bma region-each'
alias regions='~/.bash-my-aws/bin/bma regions'
alias stack-arn='~/.bash-my-aws/bin/bma stack-arn'
alias stack-asg-instances='~/.bash-my-aws/bin/bma stack-asg-instances'
alias stack-asgs='~/.bash-my-aws/bin/bma stack-asgs'
alias stack-cancel-update='~/.bash-my-aws/bin/bma stack-cancel-update'
alias stack-create='~/.bash-my-aws/bin/bma stack-create'
alias stack-delete='~/.bash-my-aws/bin/bma stack-delete'
alias stack-diff='~/.bash-my-aws/bin/bma stack-diff'
alias stack-elbs='~/.bash-my-aws/bin/bma stack-elbs'
alias stack-events='~/.bash-my-aws/bin/bma stack-events'
alias stack-exports='~/.bash-my-aws/bin/bma stack-exports'
alias stack-failure='~/.bash-my-aws/bin/bma stack-failure'
alias stack-instances='~/.bash-my-aws/bin/bma stack-instances'
alias stack-outputs='~/.bash-my-aws/bin/bma stack-outputs'
alias stack-parameters='~/.bash-my-aws/bin/bma stack-parameters'
alias stack-recreate='~/.bash-my-aws/bin/bma stack-recreate'
alias stack-resources='~/.bash-my-aws/bin/bma stack-resources'
alias stack-status='~/.bash-my-aws/bin/bma stack-status'
alias stack-tag='~/.bash-my-aws/bin/bma stack-tag'
alias stack-tag-apply='~/.bash-my-aws/bin/bma stack-tag-apply'
alias stack-tag-delete='~/.bash-my-aws/bin/bma stack-tag-delete'
alias stack-tags='~/.bash-my-aws/bin/bma stack-tags'
alias stack-tags-text='~/.bash-my-aws/bin/bma stack-tags-text'
alias stack-tail='~/.bash-my-aws/bin/bma stack-tail'
alias stack-template='~/.bash-my-aws/bin/bma stack-template'
alias stack-update='~/.bash-my-aws/bin/bma stack-update'
alias stack-validate='~/.bash-my-aws/bin/bma stack-validate'
alias stacks='~/.bash-my-aws/bin/bma stacks'
alias sts-assume-role='~/.bash-my-aws/bin/bma sts-assume-role'
alias subnets='~/.bash-my-aws/bin/bma subnets'
alias vpc-az-count='~/.bash-my-aws/bin/bma vpc-az-count'
alias vpc-azs='~/.bash-my-aws/bin/bma vpc-azs'
alias vpc-default-delete='~/.bash-my-aws/bin/bma vpc-default-delete'
alias vpc-dhcp-options-ntp='~/.bash-my-aws/bin/bma vpc-dhcp-options-ntp'
alias vpc-endpoint-services='~/.bash-my-aws/bin/bma vpc-endpoint-services'
alias vpc-endpoints='~/.bash-my-aws/bin/bma vpc-endpoints'
alias vpc-igw='~/.bash-my-aws/bin/bma vpc-igw'
alias vpc-lambda-functions='~/.bash-my-aws/bin/bma vpc-lambda-functions'
alias vpc-nat-gateways='~/.bash-my-aws/bin/bma vpc-nat-gateways'
alias vpc-network-acls='~/.bash-my-aws/bin/bma vpc-network-acls'
alias vpc-rds='~/.bash-my-aws/bin/bma vpc-rds'
alias vpc-route-tables='~/.bash-my-aws/bin/bma vpc-route-tables'
alias vpc-subnets='~/.bash-my-aws/bin/bma vpc-subnets'
alias vpcs='~/.bash-my-aws/bin/bma vpcs'

source /Users/yurix/Library/Preferences/org.dystroy.broot/launcher/bash/br
export HOMEBREW_GITHUB_API_TOKEN=
