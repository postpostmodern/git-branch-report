#!/usr/bin/env ruby

require 'colorize'
require 'time'
require_relative 'git_branch'

current_branch = `git rev-parse --abbrev-ref HEAD`.strip

if current_branch != 'main'
  print "You are not on main. Branch merges will be compared to #{current_branch}. Continue? [yN] ".yellow
  if $stdin.gets.chomp.downcase != "y"
    exit
  end
end

def branches
  `git branch -vv`.split("\n").map(&:strip).map do |branch|
    GitBranch.new(branch)
  end
end

def print_merged_and_gone
  puts "These branches have been merged into main and deleted from origin:".green
  puts branches.filter { |branch| branch.gone? && branch.merged? }.map(&:name).join(" ")
end

def print_report
  branches.sort_by(&:date).each do |branch|
    next if branch.name == 'main'

    remote_icon_color = if branch.gone?
                          { color: :red }
                        else
                          { color: :green }
                        end

    merge_icon_color = if branch.merged?
                         { color: :green }
                       elsif branch.conflict?
                         { color: :red }
                       else
                         {}
                       end

    branch_name_color = if branch.gone? && branch.merged?
                          { background: :red, color: :white }
                        elsif branch.gone? && branch.unmerged?
                          { color: :red }
                        elsif branch.remote? && branch.merged?
                          { color: :green }
                        else
                          {}
                        end

    print branch.remote_status[:icon].ljust(4).colorize(remote_icon_color)
    print branch.merge_status[:icon].ljust(4).colorize(merge_icon_color)
    print branch.name.ljust(50).colorize(branch_name_color)
    puts branch.age.rjust(46)
  end
end

if ARGV[0] == "-d"
  print_merged_and_gone
else
  print_report
end
