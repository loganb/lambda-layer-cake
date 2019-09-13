# LambdaLayerCake

LambdaLayerCake provides a set of rake tasks to produce two zip files for deploying Rails projects to AWS Lambda. One zip file (`layer.zip`) is of gems and any necessary system-level shared libraries, the second (`app.zip`) is of the Rails code itself. By splitting the project into two pieces, the inline lambda code editor can be used to edit most Rails projects. 

I wrote this code to bridge the best aspects of Ruby on Jets and Lamby. Jets is great, but I didn't want to migrate off Rails onto a framework where the APIs potentially different (or are unimplemented). Lamby is also solid, but I wanted to package my dependencies indepentently and I didn't want to use AWS SAM to manage deployment of my app. I also wanted a clear, automated mechanism to include extra system packages in the Lambda environment. 

This gem does just the packaging of the app and leaves deployment as an exercise for the user. 

## Usage

1. Include Lamby and this gem in your Rails app's Gemfile.
1. Create an `app.rb` in the root of your project per Lamby instructions to implement a Lambda handler. 
1. If you need extra system packages (such as `postgresql-libs` for the `pg` gem), create a file called `system-packages.txt` in the root of your Rails project and include package names, one per line. 
1. When you are ready to deploy your app, use `rake .layer_cake/layer.zip` and `rake .layer_cake/app.zip` to build files suitable for deployment to Lambda. 
1. Use the the demployment tools of your choice to deploy the app. 


## How It Works

LambdaLayerCake uses three input files to build `layer.zip`: `Gemfile`, `Gemfile.lock`, and `system-packages.txt`. The layer is built using the `lambci/lambda:build-ruby2.5` Docker image and any packages you specify in `system-packages.txt` are installed prior to building and installing gems. The packages themselves are not copied into the Lambda layer. LambdaLayerCake, however, walks all shared libraries built during gem installing, uses `ldd` to find dependent libraries that are not in the standard Lambda image, and copies them into the layer. 

LambdaLayerCake simply bundles the Rails directory into app.zip, excluding files that begin with `.` and several directories that are not needed outside of development. 

## Contributing

This is my first attempt at publishing a complete gem and Rails plugin. I took it as an opportunity to learn and write idiomatic Rakefiles, automate usage of Docker, etc. Suggestions on how to improve the structure of any of the moving pieces is most welcome, pull requests are even better. Please open an issue. 

## TODO

Contributions on the following items is particularly appreciated: 

* Modifying the Docker build environment to probe the host system's cache of gemfiles to more gracefully handle private and unreleased gems
* A `clean` Rake task

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
