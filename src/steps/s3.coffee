_            = require 'lodash'
async        = require 'async'
corsConfig   = require '../../assets/s3-bucket-cors.cson'
policyConfig = require '../../assets/s3-bucket-policy.cson'
debug        = require('debug')('configure-octoblu-static-site')

class S3
  constructor: ({ AWS, @bucketName, @appDomain }) ->
    throw new Error 'Missing AWS argument' unless AWS
    throw new Error 'Missing bucketName argument' unless @bucketName
    throw new Error 'Missing appDomain argument' unless @appDomain
    @s3         = new AWS.S3 { region: 'us-west-2' }
    @bucket     = new AWS.S3 { region: 'us-west-2', params: { Bucket: @bucketName }}

  configure: (callback) =>
    @_init (error) =>
      return callback error if error?
      async.series [
        @_policyify,
        @_corsify,
      ], (error) =>
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

  _corsify: (callback) =>
    @bucket.putBucketCors corsConfig, callback

  _policyify: (callback) =>
    _policyConfig =  _.cloneDeep policyConfig
    _policyConfig.Statement[0].Resource = "arn:aws:s3:::#{@bucketName}/*"
    params =
      Policy: JSON.stringify _policyConfig
    @bucket.putBucketPolicy params, callback

  _details: (callback) =>
    @bucket.getBucketWebsite (error) =>

module.exports = S3
