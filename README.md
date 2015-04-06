# `docker_sigh` #
`docker_sigh` is an (opinionated) way of wrangling Docker containers across multiple repositories. It expects a `git-flow` environment and is designed to operate against it.

## Installation ##
Add this line to your application's Gemfile:

```ruby
gem 'docker_sigh'
```

## Usage ##
Add `docker_sigh` to your Rakefile:

```ruby
require "docker_sigh"
DockerSigh::load_tasks \
    repository_root: File.expand_path(File.dirname(__FILE__)),
    container_name: "YOURUSERNAME/YOURCONTAINERNAME"
```

And then invoke it:

    $ rake sighs:dockerize

## Development ##

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing ##

1. Fork it ( https://github.com/eropple/docker_sigh/fork )
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request
