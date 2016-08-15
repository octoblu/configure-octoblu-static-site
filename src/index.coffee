async      = require 'async'
AWS        = require 'aws-sdk'
S3         = require './steps/s3'
CloudFront = require './steps/cloudfront'
debug      = require('debug')('configure-octoblu-static-site')

class ConfigureStaticSite
  constructor: ({ awsConfig, subdomain, clusterDomain }) ->
    throw new Error 'Missing subdomain argument' unless subdomain
    throw new Error 'Missing clusterDomain argument' unless clusterDomain
    throw new Error 'Missing awsConfig argument' unless awsConfig
    bucketName = "#{subdomain}-static.octoblu.com"
    appDomain  = "#{subdomain}.#{clusterDomain}"

    AWS.config.update awsConfig

    @s3 = new S3 { AWS, bucketName, appDomain }
    @cloudfront = new CloudFront { AWS, bucketName, appDomain }

  run: (callback) =>
    async.series [
      @s3.configure,
      @cloudfront.configure,
    ], callback

module.exports = ConfigureStaticSite
