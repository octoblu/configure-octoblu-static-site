async      = require 'async'
AWS        = require 'aws-sdk'
S3         = require './steps/s3'
CloudFront = require './steps/cloudfront'
Route53    = require './steps/route53'
debug      = require('debug')('configure-octoblu-static-site')

class ConfigureStaticSite
  constructor: ({ projectName, awsConfig, subdomain, rootDomain }) ->
    throw new Error 'Missing projectName argument' unless projectName
    throw new Error 'Missing subdomain argument' unless subdomain
    throw new Error 'Missing rootDomain argument' unless rootDomain
    throw new Error 'Missing awsConfig argument' unless awsConfig
    bucketName = "#{subdomain}-static.octoblu.com"
    debug 'bucket name', { bucketName }

    AWS.config.update awsConfig

    @s3 = new S3 { AWS, bucketName }
    @cloudfront = new CloudFront { AWS, bucketName }
    @route53 = new Route53 { AWS, bucketName, rootDomain }

  run: (callback) =>
    async.series [
      @s3.configure,
      @cloudfront.configure,
      @route53.configure,
    ], callback

module.exports = ConfigureStaticSite
