class RemoteRepo
  attr_reader :path

  def initialize(project_path, path)
    @project_path = project_path
    @path = path

    Git.init path, bare: true
  end
end
