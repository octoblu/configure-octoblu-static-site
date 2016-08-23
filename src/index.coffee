async      = require 'async'
AWS        = require 'aws-sdk'
S3         = require './steps/s3'
CloudFront = require './steps/cloudfront'
Route53    = require './steps/route53'
Etcd       = require './steps/etcd'
Vulcand    = require './steps/vulcand'
Services   = require './steps/services'
debug      = require('debug')('configure-octoblu-static-site')

class ConfigureStaticSite
  constructor: ({ clusters, projectName, awsConfig, subdomain, rootDomain }) ->
    throw new Error 'Missing projectName argument' unless projectName
    throw new Error 'Missing clusters argument' unless clusters
    throw new Error 'Missing subdomain argument' unless subdomain
    throw new Error 'Missing rootDomain argument' unless rootDomain
    throw new Error 'Missing awsConfig argument' unless awsConfig
    bucketName = "#{subdomain}-static.octoblu.com"
    debug 'bucket name', { bucketName }

    AWS.config.update awsConfig

    @s3 = new S3 { AWS, bucketName }
    @cloudfront = new CloudFront { AWS, bucketName }
    @route53 = new Route53 { AWS, bucketName, rootDomain }
    @etcd = new Etcd { clusters, projectName }
    @services = new Services { projectName }
    @vulcand = new Vulcand { subdomain, rootDomain, clusters, projectName }

  run: (callback) =>
    async.series [
      @s3.configure,
      @cloudfront.configure,
      @route53.configure,
      @etcd.configure,
      @services.configure,
      @vulcand.configure,
    ], callback

module.exports = ConfigureStaticSite
