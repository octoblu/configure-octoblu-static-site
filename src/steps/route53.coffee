_            = require 'lodash'
async        = require 'async'
debug        = require('debug')('configure-octoblu-static-site')

class Route53
  constructor: ({ AWS, @clusterDomain, @bucketName, @appDomain }) ->
    throw new Error 'Missing AWS argument' unless AWS
    throw new Error 'Missing bucketName argument' unless @bucketName
    throw new Error 'Missing appDomain argument' unless @appDomain
    throw new Error 'Missing clusterDomain argument' unless @clusterDomain
    @route53 = new AWS.Route53
    @cloudfront = new AWS.CloudFront

  configure: (callback) =>
    @_init callback

  _exists: (callback) =>
    @_getZoneId (error, hostedZoneId) =>
      return callback error if error?
      @route53.listResourceRecordSets {
        HostedZoneId: hostedZoneId
        MaxItems: '1000'
      }, (error, result) =>
        return callback error if error?
        exists = _.some result.ResourceRecordSets, (item) =>
          return item.Name.indexOf(@bucketName) == 0
        debug 'route exists' if exists
        debug 'route does not exist' unless exists
        callback null, exists

  _getZoneId: (callback) =>
    return callback null, @hostedZoneId if @hostedZoneId
    @hostedZoneId = null
    @route53.listHostedZones (error, result) =>
      return callback error if error?
      hostedZone = _.find result.HostedZones, (item) =>
        return item.Name.indexOf(@clusterDomain) == 0
      return callback new Error "Missing hosted zone for #{@clusterDomain}" unless hostedZone
      @hostedZoneId = hostedZone.Id.replace('/hostedzone/', '')
      callback null, @hostedZoneId

  _getCloudFrontDistro: (callback) =>
    @cloudfront.listDistributions (error, result) =>
      return callback error if error?
      distro = _.find result.Items, (item) =>
        return @bucketName in item.Aliases.Items
      callback null, distro

  _init: (callback) =>
    @_exists (error, exists) =>
      return callback error if error?
      return callback null if exists
      @_create callback

  _create: (callback) =>
    debug 'creating route'
    @_getZoneId (error, hostedZoneId) =>
      return callback error if error?
      @_getCloudFrontDistro (error, distro) =>
        return callback error if error?
        createRoute =
          ChangeBatch:
            Comment: "Static site changes for #{@bucketName}"
            Changes: [
              Action: 'CREATE'
              ResourceRecordSet:
                Name: @bucketName
                Type: 'A'
                AliasTarget:
                  DNSName: distro.DomainName
                  HostedZoneId: "Z2FDTNDATAQYW2"
                  EvaluateTargetHealth: false
            ]
          HostedZoneId: hostedZoneId
        @route53.changeResourceRecordSets createRoute, callback

module.exports = Route53
