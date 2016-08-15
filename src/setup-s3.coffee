_     = require 'lodash'
debug = require('debug')('configure-octoblu-static-site')

class SetupS3
  constructor: ({ @AWS, @subdomain, @clusterDomain }) ->
    throw new Error 'Missing AWS argument' unless @AWS
    throw new Error 'Missing subdomain argument' unless @subdomain
    throw new Error 'Missing clusterDomain argument' unless @clusterDomain
    @bucketName = "#{@subdomain}-static.#{@clusterDomain}"
    @s3         = new @AWS.S3
    @bucket     = new @AWS.S3 { params: { Bucket: @bucketName }}

  run: (callback) =>
    @_init (error) =>
      return callback error if error?
      callback null

  _bucketExists: (callback) =>
    @s3.listBuckets (error, result) =>
      return callback error if error?
      exists = _.some result.Buckets, { Name: @bucketName }
      debug 'bucket exists' if exists
      debug 'bucket doesn\'t exist' unless exists
      callback null, exists

  _init: (callback) =>
    @_bucketExists (error, exists) =>
      return callback error if error?
      return callback null if exists
      debug 'creating bucket'
      @bucket.createBucket callback

module.exports = SetupS3
