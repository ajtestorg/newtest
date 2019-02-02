#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'

Bundler.require

require 'github_api'
require 'csv'
require 'pp'
require 'pry'

#---------------------------------------------------------------------------------------------------
REPO = ARGV[0] or raise "need a repo"
START_CUTOFF = Time.parse("2018-10-01 00:00:00")
END_CUTOFF = Time.parse("2019-2-3 23:59:59")

github = Github.new(
  oauth_token: ENV['GITHUB_TOKEN'],
  org: 'ajtestorg',
  auto_pagination: false
)

puts [ "repository", "PR", "title", "author", "PR type", "JIRA", "created_at", "merged_at" ].to_csv
response = github.pull_requests.list('newtest', REPO, state: 'closed')
finished = false

loop do
  response.each do |pr|
    # Skip closed PRs (not merged)
    next unless pr.merged_at

    # Skip PRs against non-master branches
    next unless pr.base.ref == 'master'

    # Skip PRs after the end of the observation period
    next if Time.parse(pr.created_at) > END_CUTOFF

    # We have reached the oldest PR, stop now
    if Time.parse(pr.created_at) < START_CUTOFF
      finished = true
      break
    end

    puts [
      REPO,
      pr.html_url,
      pr.title,
      pr.user.login,
      pr_type(pr),
      pr_jira(pr),
      Time.parse(pr.created_at),
      Time.parse(pr.merged_at),
    ].to_csv
  end

  break if finished
  response = response.next_page
  break unless response.has_next_page?
end
