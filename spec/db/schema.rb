ActiveRecord::Schema.define(version: 0) do

  create_table(:blogs, force: true) do |t|
    t.string :name
  end

  create_table(:users, force: true) do |t|
    t.string :name
  end
end

# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Blog < ApplicationRecord
end

class User < ApplicationRecord
end
