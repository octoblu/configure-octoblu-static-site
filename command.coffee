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
    env: 'AWS_SECRET_ACCESS_KEY'
    help: 'Specify the aws secret access key'
  }
  {
    names: ['aws-key']
    type: 'string'
    env: 'AWS_ACCESS_KEY_ID'
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
    { project_name } = parser.parse process.argv

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

    awsConfig = {
      accessKeyId: aws_key,
      secretAccessKey: aws_secret,
      region: aws_region,
    }
    return { projectName, awsConfig, subdomain, rootDomain }

  run: =>
    options = @parseOptions()
    debug 'Configuring', options
    configureStaticSite = new ConfigureStaticSite options
    configureStaticSite.run (error) =>
      return @die error if error?
      console.log 'I did some of the hard work, but you still do a few a things'
      console.log "* Commit everything"
      console.log "* Convert the project to use an nginx Dockerfile, and runtime configuration"
      console.log "* Use the configure-octoblu-service project to create the service files"
      console.log "!IMPORTANT: follow the instructions listed after running configure-octoblu-service"

  die: (error) =>
    return process.exit(0) unless error?
    console.error 'ERROR'
    console.error error.stack
    process.exit 1

module.exports = Command
