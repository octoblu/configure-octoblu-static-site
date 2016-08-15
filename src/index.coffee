async   = require 'async'
AWS     = require 'aws-sdk'
debug   = require('debug')('configure-octoblu-static-site')
SetupS3 = require './setup-s3'

class ConfigureStaticSite
  constructor: ({ @awsConfig, @subdomain, @clusterDomain }) ->
    throw new Error 'Missing subdomain argument' unless @subdomain
    throw new Error 'Missing clusterDomain argument' unless @clusterDomain
    throw new Error 'Missing awsConfig argument' unless @awsConfig

    AWS.config.update @awsConfig

    @setupS3 = new SetupS3 { AWS, @subdomain, @clusterDomain }

  run: (callback) =>
    async.series [
      @setupS3.run,
    ], callback

module.exports = ConfigureStaticSite
