fs     = require 'fs'
{exec} = require 'child_process'

appFiles  = [
  # omit src/ and .coffee to make the below lines a little shorter
  'bgraph'
  'script'
]
libFiles  = [
  'lib/popup.js'
  'lib/raphael-2.0.0.min.js'
  'lib/underscore-1.2.0.min.js'
]
task 'compile', 'Compile individual files debug-friendly', ->
  for file, index in appFiles then do (file, index) ->
    exec "coffee --output lib --compile src/#{file}.coffee", (err, stdout, stderr) ->
      throw err if err
      console.log stdout + stderr

task 'build', 'Build single application file from source files', ->
  appContents = new Array remaining = appFiles.length
  for file, index in appFiles then do (file, index) ->
    appContents[index] = fs.readFileSync "src/#{file}.coffee", 'utf8'
      
  fs.writeFileSync 'lib/app.coffee', appContents.join('\n\n'), 'utf8'
  exec 'coffee --compile lib/app.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
    fs.unlink 'lib/app.coffee', (err) ->
      throw err if err

task 'buildlib', 'Builds a single lib file from all lib files', ->
  libContents = new Array remaining = libFiles.length
  for file, index in libFiles then do (file, index) ->
    libContents[index] = fs.readFileSync file, 'utf8'
   
  fs.writeFileSync 'lib/lib.js', libContents.join('\n\n'), 'utf8'

task 'buildall', 'Builds single application file from all js files including libraries', ->
  invoke 'build'
  invoke 'buildlib'
  allContent = new Array
  allContent.push fs.readFileSync 'lib/app.js', 'utf8'
  allContent.push fs.readFileSync 'lib/lib.js', 'utf8'
  
  fs.writeFileSync 'lib/app-all.js', allContent.join('\n\n'), 'utf8'

task 'minify', 'Minify the resulting application file after build', ->
  exec 'java -jar "tools/compiler.jar" --js lib/app.js --js_output_file lib/app.min.js', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task 'minifyXtreme', 'Minify maximum possible using ADVANCED_OPTIMIZATIONS', ->
  exec 'java -jar "tools/compiler.jar" --js lib/app-all.js --compilation_level ADVANCED_OPTIMIZATIONS --js_output_file lib/app-all.min.js', (err, stdout, stderr) ->
    throw err if err

task 'publish', 'Build and minify project files. Ready for production', ->
  invoke 'build'
  invoke 'minify'

task 'px', 'Publish Xtreme', ->
  invoke 'buildall'
  invoke 'minifyXtreme'