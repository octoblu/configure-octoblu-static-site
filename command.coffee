colors              = require 'colors'
dashdash            = require 'dashdash'
ConfigureStaticSite = require './src'
packageJSON         = require './package.json'

OPTIONS = [
  {
    names: ['cluster-domain', 'c']
    type: 'string'
    env: 'CLUSTER_DOMAIN'
    help: 'Specify the cluster domain to add the service to'
    default: 'octoblu.com'
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
    { @awsConfig, @subdomain, @clusterDomain } = @parseOptions()

  parseOptions: =>
    parser = dashdash.createParser { options: OPTIONS }
    { help, version } = parser.parse process.argv
    { subdomain, cluster_domain } = parser.parse process.argv
    { aws_key, aws_secret, aws_region } = parser.parse process.argv

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

    clusterDomain = cluster_domain.replace /^\./, ''

    awsConfig = {
      accessKeyId: aws_key,
      secretAccessKey: aws_secret,
      region: aws_region,
    }
    return { awsConfig, subdomain, clusterDomain }

  run: =>
    console.log "Configuring #{@subdomain}.#{@clusterDomain}"
    configureStaticSite = new ConfigureStaticSite { @awsConfig, @subdomain, @clusterDomain }
    configureStaticSite.run @die

  die: (error) =>
    return process.exit(0) unless error?
    console.error 'ERROR'
    console.error error.stack
    process.exit 1

module.exports = Command
