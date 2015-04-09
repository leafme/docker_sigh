require "docker_sigh/version"

require "erber/templater"

require "fileutils"
require "logger"

require "rake"
require "rake/file_utils"

module DockerSigh
  LOGGER = Logger.new($stderr)
  LOGGER.level = Logger.const_get((ENV["DOCKERSIGH_VERBOSITY"] || "INFO").upcase)

  def self.load_tasks(opts)
    extend Rake::DSL
    dockerfile_template = Util::template_url(opts)
    dockerfile = dockerfile_template.gsub("Dockerfile.template.erb", "Dockerfile")

    namespace :ds do
      task :template do
        Util::validate_opts(opts)
        Util::validate_repo(opts)
        LOGGER.debug "Beginning 'template' task."

        template = Erber::Templater.new(IO.read(dockerfile_template), DockerfileMash)
        IO.write(dockerfile, template.render(Util::generate_template_args(opts)))

        LOGGER.debug "Ending 'template' task."
      end
      
      task :build do
        Util::validate_opts(opts)
        Util::validate_repo(opts)
        LOGGER.debug "Beginning 'build' task."
        Dir.chdir(opts[:repository_root]) do
          name = opts[:container_name]

          ret = sh "docker build -t '#{name}:working' ."
          raise "failed to build" unless ret

          [ Util::repo_current_commit(opts),
              Util::tag_from_branch_name(opts),
              Util::repo_current_tags(opts) ].flatten.each do |tag|
            ret = sh "docker tag --force #{name}:working #{name}:#{tag}"
            raise "failed to tag with '#{tag}'" unless ret
          end

          ret = sh "docker rmi #{name}:working"
          raise "failed to rmi working tag" unless ret
        end
        LOGGER.debug "Ending 'build' task."
      end

      task :clean do
        Util::validate_opts(opts)
        LOGGER.debug "Beginning 'clean' task."

        LOGGER.debug "Deleting '#{dockerfile}'."
        FileUtils.rm_f dockerfile

        LOGGER.debug "Ending 'clean' task."
      end

      task :push do
        LOGGER.debug "Beginning 'push' task."
        Dir.chdir(opts[:repository_root]) do
          name = opts[:container_name]
          hash = Util::repo_current_commit(opts)
          branch = Util::tag_from_branch_name(opts)

          ret = sh "docker push #{name}:#{branch}"
          raise "failed to push with branch tag" unless ret
          ret = sh "docker push #{name}:#{hash}"
          raise "failed to push with hash tag" unless ret

        end
        LOGGER.debug "Ending 'push' task."
      end

      task :go => [ :template, :build, :clean ]  { }
    end
  end
  

  module Util
    CONTAINER_NAME_REGEX = /[a-z0-9_]\/[a-zA-Z0-9\-_.]/

    def self.validate_opts(opts)
      LOGGER.debug "Validating options: #{opts.inspect}"

      raise ":container_name must be set." unless opts[:container_name]
      raise ":container_name must match regex '#{CONTAINER_NAME_REGEX.to_s}'." \
        unless opts[:container_name] =~ CONTAINER_NAME_REGEX

      raise "If set, :default_host must be a valid hostname." \
        unless !opts[:default_host] || Util::valid_hostname?(opts[:default_host])

      raise "If set, the DOCKER_REMOTE env var must be a valid hostname." \
        unless !ENV["DOCKER_REMOTE"] || Util::valid_hostname?(ENV["DOCKER_REMOTE"])

      opts[:host] = ENV["DOCKER_REMOTE"] || opts[:default_host]

      raise ":repository_root must be set." unless opts[:repository_root]
      raise ":repository_root must exist and be a non-bare Git root." \
        unless Dir.exist?(File.join(opts[:repository_root], ".git"))

      LOGGER.debug "Options successfully validated."
    end

    def self.validate_repo(opts)
      dockerfile_template = template_url(opts)
      raise "'#{dockerfile_template}' must exist." unless File.exist?(dockerfile_template)

      gitignore = File.join(opts[:repository_root], ".gitignore")
      raise "'#{gitignore}' must exist." unless File.exist?(gitignore)
      system "grep -e 'Dockerfile\|/Dockerfile' #{gitignore}"
      raise "The repo's .gitignore must ignore the Dockerfile." unless $?

      raise "The repo must be clean (no outstanding changes)." unless clean_git_root?(opts)
    end

    def self.template_url(opts)
      File.join(opts[:repository_root], "Dockerfile.template.erb")
    end

    def self.generate_template_args(opts)
      {
        :host => opts[:host],
        :parent_tag => from_directive_parent_tag(opts)
      }
    end

    def self.repo_branch(opts)
      Dir.chdir(opts[:repository_root]) do
        name = `git symbolic-ref --short HEAD`.strip
        raise "git failed to find branch" unless $? == 0
        name
      end
    end

    def self.tag_from_branch_name(opts)
      repo_branch(opts).gsub("/", "-")
    end

    def self.repo_current_commit(opts)
      hash = `git rev-parse --verify HEAD`.strip
      raise "git failed to get hash" unless $? == 0
      hash
    end
    def self.repo_current_tags(opts)
      LOGGER.warn "Tags are not currently replicated into the Docker repository. Be advised when using release tags."
      []
    end

    def self.from_directive_parent_tag(opts)
      # TODO: parse .git/config and un-hardcode the git-flow prefixes

      branch = repo_branch(opts)
      case branch
      when "develop"
        "develop"
      when "master"
        "master"
      else
        if branch.start_with?("feature/")
          "develop"
        elsif branch.start_with("release/") || branch.start_with("hotfix/")
          "master"
        else
          logger.warn "Unrecognized branch; can't figure out a parent tag. Assuming 'develop'."
          "develop"
        end
      end
    end

    # originally from http://www.dzone.com/snippets/simple-hostname-validation
    def self.valid_hostname?(hostname)
      return false unless hostname
      return false if hostname.length > 255 or hostname.scan('..').any?
      hostname = hostname[0 ... -1] if hostname.index('.', -1)
      return hostname.split('.').collect { |i|
        i.size <= 63 and not (i.rindex('-', 0) or i.index('-', -1) or i.scan(/[^a-z\d-]/i).any?)
      }.all?
    end

    def self.clean_git_root?(opts)
      Dir.chdir opts[:repository_root] do
        `git status | grep 'nothing to commit, working directory clean'`
        $? == 0
      end
    end
  end

  class DockerfileMash < Hashie::Mash
    def from_directive(parent_container_name)
      if host
        raise "host not supported yet"
      else
        "FROM #{parent_container_name}:#{parent_tag}"
      end
    end
  end
end
