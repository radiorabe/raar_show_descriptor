class Description

  attr_reader :title, :body

  def initialize(title, body)
    @title = title
    @body = body
  end

  def present?
    !body.to_s.strip.empty?
  end

end
