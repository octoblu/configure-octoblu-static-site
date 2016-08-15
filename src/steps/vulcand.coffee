_     = require 'lodash'
async = require 'async'
fs    = require 'fs-extra'
path  = require 'path'
debug = require('debug')('configure-octoblu-static-site')

class Vulcand
  constructor: ({ @subdomain, @projectName, @clusters, @rootDomain }) ->
    throw new Error 'Missing subdomain argument' unless @subdomain
    throw new Error 'Missing projectName argument' unless @projectName
    throw new Error 'Missing rootDomain argument' unless @rootDomain
    throw new Error 'Missing clusters argument' unless @clusters
    @ENV_DIR = "#{process.env.HOME}/Projects/Octoblu/the-stack-env-production"

  configure: (callback) =>
    debug 'creating all vulcand', { @clusters }
    async.eachSeries @clusters, @_createVulcan, callback

  _createVulcan: (cluster, callback) =>
    debug 'creating vulcan', { cluster }
    clusterConfigPath = path.join @ENV_DIR, cluster, 'vulcan'
    fs.stat clusterConfigPath, (error, stats) =>
      return callback null if error?
      return callback null unless stats.isDirectory()
      projectPath = path.join clusterConfigPath, "octoblu-#{@projectName}"
      fs.ensureDir projectPath, (error) =>
        return callback error if error?
        @_createFiles cluster, projectPath, callback

  _createFiles: (cluster, projectPath, callback) =>
    debug 'creating files for', { cluster }
    async.series [
      async.apply @_createBackend, cluster, projectPath
      async.apply @_createFrontend, cluster, projectPath
    ], callback

  _createBackend: (cluster, projectPath, callback) =>
    debug 'creating backend for', { cluster }
    template = "--id octoblu-#{@projectName}"
    fs.writeFile path.join(projectPath, 'backend'), template, callback

  _createFrontend: (cluster, projectPath, callback) =>
    debug 'creating frontend for', { cluster }
    domain = "#{@subdomain}.#{@rootDomain}"
    domain = "#{@subdomain}.#{cluster}.#{@rootDomain}" unless @cluster in ["major", "minor"]
    template = "--id octoblu-#{@projectName}\n--backend octoblu-#{@projectName}\n--route Host(\"#{domain}\")\n--trustForwardHeader"
    fs.writeFile path.join(projectPath, 'frontend'), template, callback

module.exports = Vulcand