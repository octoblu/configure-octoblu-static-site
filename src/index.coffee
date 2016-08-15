async      = require 'async'
AWS        = require 'aws-sdk'
S3         = require './steps/s3'
CloudFront = require './steps/cloudfront'
Route53    = require './steps/route53'
debug      = require('debug')('configure-octoblu-static-site')

class ConfigureStaticSite
  constructor: ({ awsConfig, subdomain, clusterDomain }) ->
    throw new Error 'Missing subdomain argument' unless subdomain
    throw new Error 'Missing clusterDomain argument' unless clusterDomain
    throw new Error 'Missing awsConfig argument' unless awsConfig
    bucketName = "#{subdomain}-static.octoblu.com"
    appDomain  = "#{subdomain}.#{clusterDomain}"

    AWS.config.update awsConfig

    @s3 = new S3 { AWS, bucketName }
    @cloudfront = new CloudFront { AWS, bucketName, appDomain }
    @route53 = new Route53 { AWS, bucketName, appDomain, clusterDomain }

  run: (callback) =>
    async.series [
      @s3.configure,
      @cloudfront.configure,
      @route53.configure,
    ], callback

module.exports = ConfigureStaticSite
