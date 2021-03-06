require 'tempfile'

class GemfileParser
  # [使い方]
  #   GemfileParser.new.parse_gemfile(rubygems_contents)
  #
  # [戻り値]
  #   Array
  #     - [0] boolean - パースに成功したか
  #     - [1] array - Gem Dependenciesのリスト
  #     - [2] object - エラークラス
  def parse_gemfile(rubygems_contents)
    # gemfile がない場合は飛ばす
    if rubygems_contents.present?
      # gemspec を参照している場合、その行は無視する
      gem_lines = rubygems_contents
                  .split("\n")
                  .map(&:strip)
                  .select { |v| v.start_with?('gem') && !v.start_with?('gemspec') }
      file = Tempfile.new('TemporaryGem')

      is_success = false
      error = nil
      gems = []

      begin
        file.puts(gem_lines)
        file.rewind
        gems = Bundler::Definition.build(file.path, nil, nil).dependencies
        is_success = true
      rescue => e
        error = e
      ensure
        file.close
        file.unlink
      end

    else
      is_success = true
      gems = []
      error = nil
    end
    [is_success, gems, error]
  end

  # Gemspecの中からadd_dependency, add_development_dependencyの行だけ抽出
  # そこからgemfile名を推測する
  #
  # [使い方]
  #   GemfileParser.new.parse_gemspec(contents)
  #
  # [戻り値]
  #   Array - Gemfile名のリスト
  def parse_gemspec(gemspec_contents)
    dependencies = gemspec_contents
                   .split("\n")
                   .select { |v| v.include?('add_dependency') }
                   .map { |v| v.scan(/add_dependency\s+(.[^,)]*)/).flatten.first }
                   .map { |v| v.delete("'").delete('"').delete('(').delete(')') }
    dev_dependencies = gemspec_contents
                       .split("\n")
                       .select { |v| v.include?('add_development_dependency') }
                       .map { |v| v.scan(/add_development_dependency\s+(.[^,)]*)/).flatten.first }
                       .map { |v| v.delete("'").delete('"').delete('(').delete(')') }

    dependencies.concat(dev_dependencies)
  end
end
