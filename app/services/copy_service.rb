class CopyService
  # Make ActionView helpers available in copy files when renderings
  include ActionView::Helpers

  def initialize(interaction_name, hash)
    @interaction_name = interaction_name
    @context = hash_to_binding hash
  end

  def get_copy(key)
    copy = recursive_render(yaml_from_key(key))

    copy.is_a?(Hash) ? HashWithIndifferentAccess.new(copy) : copy
  end

  def recursive_render(to_render)
    if to_render.is_a? String
      ERB.new(to_render).result(@context)
    elsif to_render.is_a? Hash
      to_render.each { |k, v| to_render[k] = recursive_render v }
      to_render
    elsif to_render.is_a? Array
      to_render.map { |x|  recursive_render x }
    end
  end

  def yaml_from_key(key)
    yaml_path = File.join(Rails.root, 'lib', 'data', 'copy',
                          "#{@interaction_name}.yml")
    copy = YAML.load File.read(yaml_path)

    key.split('.').each do |s|
      copy = (copy.is_a?(Hash) && copy.key?(s) ? copy = copy[s] : nil)
    end

    # If we get an array of strings, choose one element at random.
    array_of_strings?(copy) ? copy.sample : copy
  end

  private

  def array_of_strings?(arr)
    return unless arr.is_a? Array

    all_strings = true
    arr.each do |a|
      next if a.is_a? String

      all_strings = false
      break
    end

    all_strings
  end

  def hash_to_binding(hash)
    bind = binding

    hash.each { |k, v| bind.local_variable_set(k, v) }

    bind
  end
end
