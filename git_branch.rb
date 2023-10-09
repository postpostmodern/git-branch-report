class GitBranch
  MERGED_BRANCHES = `git branch --merged`.split("\n").map(&:strip)

  attr_accessor :conflict_check, :info

  def initialize(branch_info, conflict_check = false)
    @info = branch_info.match(/^(?<current>\* )?(?<name>[^\s]+)\s+(?<commit>[a-f0-9]{10})(?<remote>\s\[[^\]]+\])?\s(?<message>.*)$/).named_captures
    @conflict_check = conflict_check
    check_for_conflicts
  end

  def current?
    !!info['current']
  end

  def name
    info['name']
  end

  def message
    info['message']
  end

  def commit
    info['commit']
  end

  def remote
    info['remote']
  end

  def remote_status
    if remote.nil?
      { key: :local, string: 'Local', icon: ' ' }
    elsif remote.match?(/: gone\]/)
      { key: :gone, string: 'Gone', icon: '' }
    else
      { key: :remote, string: 'Remote', icon: '' }
    end
  end

  def merge_status
    if merged?
      { key: :merged, string: 'Merged', icon: '' }
    elsif conflict?
      { key: :conflict, string: 'Conflict', icon: '' }
    else
      { key: :unmerged, string: 'Unmerged', icon: '' }
    end
  end

  def merged?
    MERGED_BRANCHES.include?(name)
  end

  def unmerged?
    !merged? && !conflict?
  end

  def conflict?
    check_for_conflicts
  end

  def check_for_conflicts
    return false unless conflict_check

    return @conflict unless @conflict.nil?

    system "git checkout -q #{name}"
    @conflict = `git merge main --no-ff --no-commit`.match?(/CONFLICT/)
    system 'git merge --abort'
    system 'git checkout -q main'
    @conflict
  end

  def gone?
    remote_status[:key] == :gone
  end

  def local?
    remote_status[:key] == :local
  end

  def remote?
    remote_status[:key] == :remote
  end

  def age
    `git show -s --pretty=format:"%cr" #{commit}`.blue
  end

  def date
    Time.parse(`git show -s --pretty=format:"%cD" #{commit}`)
  end
end
