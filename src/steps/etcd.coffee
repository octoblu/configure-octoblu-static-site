_            = require 'lodash'
async        = require 'async'
fs           = require 'fs-extra'
path         = require 'path'
debug        = require('debug')('configure-octoblu-static-site')

class Etcd
  constructor: ({ @projectName, @clusters }) ->
    throw new Error 'Missing projectName argument' unless @projectName
    throw new Error 'Missing clusters argument' unless @clusters
    @ENV_DIR = "#{process.env.HOME}/Projects/Octoblu/the-stack-env-production"

  configure: (callback) =>
    async.eachSeries @clusters, @_createEnv, callback

  _createEnv: (cluster, callback) =>
    debug 'creating env', { cluster }
    clusterConfigPath = path.join @ENV_DIR, cluster
    fs.stat clusterConfigPath, (error, stats) =>
      return callback error if error?
      return callback new Error("No configuration for #{cluster}") unless stats.isDirectory()
      projectPath = path.join clusterConfigPath, 'etcd', 'octoblu', @projectName
      debug 'projectPath', projectPath
      fs.ensureDir path.join(projectPath, 'env'), (error) =>
        return callback error if error?
        @_writeFiles projectPath, callback

  _writeFiles: (projectPath, callback) =>
    fs.writeFile path.join(projectPath, 'docker_url'), "quay.io/octoblu/#{@projectName}", (error) =>
      return callback error if error?
      fs.writeFile path.join(projectPath, 'env', 'DEBUG'), 'nothing', callback

module.exports = Etcd
