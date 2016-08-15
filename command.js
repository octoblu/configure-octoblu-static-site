#!/usr/bin/env node

require('coffee-script/register');
require('fs-cson/register');
var Command = require('./command.coffee');
var command = new Command(process.argv);
command.run();
