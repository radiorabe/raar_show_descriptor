class DirectusShow

  attr_reader :name, :description

  def initialize(json)
    @name = json['name']
    @description = extract_description(json)
  end

  def description?
    !description.to_s.strip.empty?
  end

  private

  def extract_description(json)
    json['content']['content'].map do |c|
      next unless c['content']
      "<p>#{c['content'].map { |d| d['text'] }.join}</p>"
    end.join
  end
end
