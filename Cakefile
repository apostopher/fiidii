fs     = require 'fs'
{exec} = require 'child_process'

appFiles  = [
  # omit src/ and .coffee to make the below lines a little shorter
  'bgraph'
  'script'
]
task 'compile', 'Compile individual files debug-friendly', ->
  for file, index in appFiles then do (file, index) ->
    exec "coffee --output lib --compile src/#{file}.coffee", (err, stdout, stderr) ->
      throw err if err
      console.log stdout + stderr

task 'build', 'Build single application file from source files', ->
  appContents = new Array remaining = appFiles.length
  for file, index in appFiles then do (file, index) ->
    fs.readFile "src/#{file}.coffee", 'utf8', (err, fileContents) ->
      throw err if err
      appContents[index] = fileContents
      process() if --remaining is 0
  process = ->
    fs.writeFile 'lib/app.coffee', appContents.join('\n\n'), 'utf8', (err) ->
      throw err if err
      exec 'coffee --compile lib/app.coffee', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
        fs.unlink 'lib/app.coffee', (err) ->
          throw err if err

task 'minify', 'Minify the resulting application file after build', ->
  exec 'java -jar "tools/compiler.jar" --js lib/app.js --js_output_file lib/app.min.js', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task 'publish', 'Build and minify project files. Ready for production', ->
  invoke 'build'
  invoke 'minify'