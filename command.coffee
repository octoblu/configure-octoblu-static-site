_                   = require 'lodash'
colors              = require 'colors'
dashdash            = require 'dashdash'
ConfigureStaticSite = require './src'
packageJSON         = require './package.json'
debug               = require('debug')('configure-octoblu-static-site')

OPTIONS = [
  {
    names: ['root-domain', 'r']
    type: 'string'
    env: 'ROOT_DOMAIN'
    help: 'Specify the root domain to add the service to'
    default: 'octoblu.com'
  }
  {
    names: ['clusters', 'c']
    type: 'string'
    env: 'CLUSTERS'
    help: 'Specify the clusters to add, separated by a ","'
  }
  {
    names: ['project-name', 'p']
    type: 'string'
    env: 'PROJECT_NAME'
    help: 'Specify the name of the Project, or Service. It should be dasherized.'
  }
  {
    names: ['subdomain', 's']
    type: 'string'
    env: 'SUBDOMAIN'
    help: 'Specify the subdomain of the static site. For example, "connector-factory"'
  }
  {
    names: ['aws-secret']
    type: 'string'
    env: 'AWS_SECRET'
    help: 'Specify the aws secret access key'
  }
  {
    names: ['aws-key']
    type: 'string'
    env: 'AWS_KEY'
    help: 'Specify the aws access key'
  }
  {
    names: ['aws-region']
    type: 'string'
    env: 'AWS_REGION'
    help: 'Specify the aws region to create the service in. This will not effect the s3 bucket region.'
    default: 'us-west-2'
  }
  {
    names: ['help', 'h']
    type: 'bool'
    help: 'Print this help and exit.'
  }
  {
    names: ['version', 'v']
    type: 'bool'
    help: 'Print the version and exit.'
  }
]

class Command
  constructor: ->
    process.on 'uncaughtException', @die

  parseOptions: =>
    parser = dashdash.createParser { options: OPTIONS }
    { help, version } = parser.parse process.argv
    { subdomain, root_domain } = parser.parse process.argv
    { aws_key, aws_secret, aws_region } = parser.parse process.argv
    { project_name, clusters } = parser.parse process.argv

    if help
      console.log "usage: configure-octoblu-static-site [OPTIONS]\noptions:\n#{parser.help({includeEnv: true})}"
      process.exit 0

    if version
      console.log packageJSON.version
      process.exit 0

    unless subdomain
      console.error "usage: configure-octoblu-static-site [OPTIONS]\noptions:\n#{parser.help({includeEnv: true})}"
      console.error colors.red 'Missing required parameter --subdomain, -s, or env: SUBDOMAIN'
      process.exit 1

    unless project_name
      console.error "usage: configure-octoblu-static-site [OPTIONS]\noptions:\n#{parser.help({includeEnv: true})}"
      console.error colors.red 'Missing required parameter --project-name, -p, or env: PROJECT_NAME'
      process.exit 1

    unless aws_key
      console.error "usage: configure-octoblu-static-site [OPTIONS]\noptions:\n#{parser.help({includeEnv: true})}"
      console.error colors.red 'Missing required parameter --aws-key, or env: AWS_KEY'
      process.exit 1

    unless aws_secret
      console.error "usage: configure-octoblu-static-site [OPTIONS]\noptions:\n#{parser.help({includeEnv: true})}"
      console.error colors.red 'Missing required parameter --aws-secret, or env: AWS_SECRET'
      process.exit 1

    unless aws_region
      console.error "usage: configure-octoblu-static-site [OPTIONS]\noptions:\n#{parser.help({includeEnv: true})}"
      console.error colors.red 'Missing required parameter --aws-region, or env: AWS_REGION'
      process.exit 1

    if subdomain.indexOf('octoblu.com') > -1
      console.error "usage: configure-octoblu-static-site [OPTIONS]\noptions:\n#{parser.help({includeEnv: true})}"
      console.error colors.red 'Subdomain must not include octoblu.com'
      process.exit 1

    if subdomain.indexOf('-static') > -1
      console.error "usage: configure-octoblu-static-site [OPTIONS]\noptions:\n#{parser.help({includeEnv: true})}"
      console.error colors.red 'Subdomain must not include "-static"'
      process.exit 1

    rootDomain = root_domain.replace /^\./, ''
    projectName = project_name
    clustersArray = _.compact _.map clusters?.split(','), (cluster) => return cluster?.trim()
    clustersArray = ['major', 'minor', 'hpe'] if _.isEmpty clustersArray

    awsConfig = {
      accessKeyId: aws_key,
      secretAccessKey: aws_secret,
      region: aws_region,
    }
    return { clusters: clustersArray, projectName, awsConfig, subdomain, rootDomain }

  run: =>
    options = @parseOptions()
    debug 'Configuring', options
    configureStaticSite = new ConfigureStaticSite options
    configureStaticSite.run (error) =>
      return @die error if error?
      console.log 'I did some of the hard work, but you still do a few a things'
      console.log "* Commit everything"
      console.log "* Convert the project to use an nginx Dockerfile, and runtime configuration"
      console.log "* Setup the repo in Quay"
      console.log "  - `cd #{process.env.HOME}/Projects/Octoblu/#{options.projectName}`"
      console.log "  - `quayify`"
      console.log '* Make sure to update your tools'
      console.log '  - `npm install --global deployinate-configurator`'
      console.log '  - `brew update && brew upgrade majorsync minorsync hpesync vulcansync hpevulcansync`'
      console.log '* Sync etcd:'
      console.log "  - `majorsync load #{options.projectName}`"
      console.log "  - `minorsync load #{options.projectName}`"
      console.log "  - `hpesync load #{options.projectName}`"
      console.log '* Sync vulcan:'
      console.log "  - `hpevulcansync load octoblu-#{options.projectName}`"
      console.log "  - `vulcansync load octoblu-#{options.projectName}`"
      console.log '* Create services:'
      console.log "  - `cd #{process.env.HOME}/Projects/Octoblu/the-stack-services/services.d"
      console.log "  - `dplcfg service -d #{options.projectName} #{options.projectName}`"
      console.log " # in new tab"
      console.log "  - `fleetmux`"
      console.log "  - Create 2 instances when prompted"
      console.log "  - `cd #{process.env.HOME}/Projects/Octoblu/the-stack-services"
      console.log "  - `./scripts/run-on-services.sh 'submit,start' '*#{options.projectName}*'`"
      console.log "  - `minormux`"
      console.log " # in new tab"
      console.log "  - Create 1 instance when prompted"
      console.log "  - `cd #{process.env.HOME}/Projects/Octoblu/the-stack-services"
      console.log "  - `./scripts/run-on-services.sh 'submit,start' '*#{options.projectName}*'`"
      console.log " # in new tab"
      console.log "  - `hpemux`"
      console.log "  - Create 2 instances when prompted"
      console.log "  - `cd #{process.env.HOME}/Projects/Octoblu/the-stack-services"
      console.log "  - `./scripts/run-on-services.sh 'submit,start' '*#{options.projectName}*'`"
      console.log "* Once it is all setup, point the domains to their respective clusters in Route53. (I am too scared to do it automatically)"


  die: (error) =>
    return process.exit(0) unless error?
    console.error 'ERROR'
    console.error error.stack
    process.exit 1

module.exports = Command
