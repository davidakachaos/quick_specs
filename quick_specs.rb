#!/usr/bin/env ruby

def init_bundler
  bundle_need  = false
  puts "Checking bundle for needed gems"
  check_gem = `bundle list --no-color`
  needed_gems = [['rspec-rails', true], ['shoulda-matchers', false]]
  needed_gems.each do |gem_name, dev|
    unless check_gem.include?(gem_name)
      # Need to add the factory_girl gem first
      File.open('Gemfile', 'a') do |file|
        file.puts ''
        file.puts "gem '#{gem_name}', group: #{dev ? '[:development, :test]' : ':test'}"
      end
      puts "  Added #{gem_name} gem"
      bundle_need = true
    end
  end
  puts "bundle_need: #{bundle_need}"
  `bundle install` if bundle_need
end

def generate_specs
  require './config/environment.rb'
  files = Dir.glob('./app/models/*.rb')
  files.each do |f|
    name = f.split('/').last.gsub('.rb','')
    if name =~ /ability/i
      puts "Skipping ability file!"
      next
    end
    if ask_overwrite("./spec/models/#{name}_spec.rb")
      puts "Creating spec for #{name.camelize}"
      specfile = File.new("./spec/models/#{name}_spec.rb", File::CREAT|File::TRUNC|File::RDWR, 0644)
      specfile.puts "require 'spec_helper'"
      specfile.puts "# TODO Write a good test for #{name.split('_').join(' ')}"
      #Parse the file so we can fill in a skeleton file...
      specfile.puts
      specfile.puts "describe #{name.camelize} do"
      begin
        m = name.camelize.constantize
        specfile.puts "\t#The relations..."
        specfile.puts "\tdescribe 'relations' do\n\t\tpending 'write correct tests' do"
        if m.reflections
          m.reflections.each{|key, val|
            #assoc kind e.d.
            assoc = m.reflections[key]
            if assoc.macro == :has_many
              specfile.puts "\t\tit { should have_many(:#{key})#{val.options && val.options[:dependent] ? ".dependent(:#{val.options[:dependent]})" : '' }#{val.options && val.options[:through] ? ".through(:#{val.options[:through]})" : '' } }"
            end
            if assoc.macro == :belongs_to
              specfile.puts "\t\tit { should belong_to(:#{key}) }"
            end
            if assoc.macro == :has_and_belongs_to_many
              specfile.puts "\t\tit { should have_and_belong_to_many(:#{key}) }"
            end
            if assoc.macro == :has_one
              specfile.puts "\t\tit { should have_one(:#{key}) }"
            end
          }
        end
        specfile.puts "\t\tend\n\tend"
        specfile.puts "\n\t#The validations. If any."
        specfile.puts "\tdescribe 'validations' do\n\t\tpending 'write correct tests' do"
        if m.validators
          m.validators.each do |val|
            if val.class == ActiveModel::Validations::PresenceValidator
              val.attributes.each do |at|
                specfile.puts "\t\tit { should validate_presence_of(:#{at}) }"
              end
            end
            if val.class == ActiveRecord::Validations::UniquenessValidator
              val.attributes.each do |at|
                specfile.puts "\t\tit { should validate_uniqueness_of(:#{at}) }"
              end
            end
            if val.class == ActiveModel::Validations::ConfirmationValidator
              val.attributes.each do |at|
                specfile.puts "\t\tit { should validate_acceptance_of(#{at}) }"
              end
            end
          end
        end
        specfile.puts "\t\tend\n\tend"

        specfile.puts "\n\t#See to the correct use of the DB..."
        specfile.puts "\tdescribe 'raw table' do\n\t\tpending 'write correct tests' do"
        #Best practices!
        m.attribute_names.each do |att|
          specfile.puts "\t\tit { should have_db_column(:#{att}) }"
          if att.ends_with?("_id")
            specfile.puts "\t\tit { should have_db_index(:#{att}) }"
          end
          if att.end_with?("_type") && !att.end_with?('content_type')
            specfile.puts "\t\tit { should have_db_index(:#{att}) }"
          end
        end
        specfile.puts "\t\tend\n\tend"
      rescue
        puts "There was an error while proccessing #{name.camelize}. Maybe not a ActiveRecord::Base desendent?"
        puts "The error was: #{$!.inspect}"
      ensure
        specfile.puts "end"
        specfile.close
      end
    else
      puts "Spec for #{name} exists! Skipping..."
    end
  end
end

init_bundler
generate_specs