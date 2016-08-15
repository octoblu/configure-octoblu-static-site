_            = require 'lodash'
async        = require 'async'
distroConfig = require '../assets/cloudfront-distro.cson'
debug        = require('debug')('configure-octoblu-static-site')

class CloudFront
  constructor: ({ AWS, @bucketName, @appDomain }) ->
    throw new Error 'Missing AWS argument' unless AWS
    throw new Error 'Missing bucketName argument' unless @bucketName
    throw new Error 'Missing appDomain argument' unless @appDomain
    @cloudfront = new AWS.CloudFront

  configure: (callback) =>
    @_init (error) =>
      return callback error if error?
      callback null

  _exists: (callback) =>
    @cloudfront.listDistributions (error, result) =>
      return callback error if error?
      exists = _.some result.Items, (item) =>
        return @bucketName in item.Aliases.Items
      debug 'cloudfront distro exists' if exists
      debug 'cloudfront distro doesn\'t exist' unless exists
      callback null, exists

  _init: (callback) =>
    @_exists (error, exists) =>
      return callback error if error?
      return callback null if exists
      @_create callback

  _create: (callback) =>
    debug 'creating distro'
    _distroConfig = _.cloneDeep distroConfig
    originId = "S3-#{@bucketName}"
    _distroConfig.DistributionConfig.Origins.Items[0].Id = originId
    _distroConfig.DistributionConfig.Origins.Items[0].DomainName = "#{@bucketName}.s3.amazonaws.com"
    _distroConfig.DistributionConfig.DefaultCacheBehavior.TargetOriginId = originId
    _distroConfig.DistributionConfig.Aliases.Items = [ @bucketName ]
    _distroConfig.DistributionConfig.CallerReference = "#{Date.now()}"
    @cloudfront.createDistribution _distroConfig, callback

module.exports = CloudFront
