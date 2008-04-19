require 'test/unit'
require 'rubygems'
require 'activerecord'
require 'actionpack'
require 'action_controller'
require 'action_controller/integration'
$: << "../lib"
require '../init'


ActiveRecord::Base.establish_connection({
      :adapter => "sqlite3", 
      :dbfile => "database.sqlite" 
})

class MigrateMe < ActiveRecord::Migration
  def self.up
    create_table :items, :force => true do |t|
      t.integer :container_id
      t.string :description
    end
    create_table :containers, :force => true do |t|
      t.string :description
    end
    create_table :people, :force => true do |t|
      t.string :description
    end
    create_table :houses, :force => true do |t|
      t.string :description
      t.integer :person_id
    end
    create_table :schools, :force => true do |t|
      t.string :description
    end
    create_table :departments, :force => true do |t|
      t.string :description
      t.integer :school_id
    end
    create_table :teachers, :force => true do |t|
      t.string :description
      t.integer :department_id
    end
  end
end

MigrateMe.up

class Container < ActiveRecord::Base
  has_many :items
end

class Item < ActiveRecord::Base
  belongs_to :container
end

class Person < ActiveRecord::Base
  has_many :houses
end

class House < ActiveRecord::Base
  belongs_to :person
end

class School < ActiveRecord::Base
  has_many :departments
end

class Department < ActiveRecord::Base
  belongs_to :school
end

class Teacher < ActiveRecord::Base
  belongs_to :department
end

ActionController::Routing::Routes.draw do |map|
  map.resources :containers do |c|
    c.resources :items
  end

  map.namespace :admin do |n|
    n.resources :people do |p|
      p.resources :houses
    end
  end

  map.resources :schools do |s|
    s.resources :departments do |d|
      d.resources :teachers
    end
  end

end

class InferredRoutesTest < ActionController::IntegrationTest
  def setup
    @c = Container.create
    @i = Item.create(:container => @c) 
    @i = Item.create(:container => @c) until @i.id != @c.id
    @p = Person.create
    @h = House.create(:person => @p) 
    @h = House.create(:person => @p) until @h.id != @p.id
    @s = School.create
    @d = Department.create(:school => @s)
    @d = Department.create(:school => @s) until @d.id != @s.id
    @t = Teacher.create(:department => @d)
    @t = Teacher.create(:department => @d) until @t.id != @d.id
  end

  def test_plural_items_route
    assert_equal("/containers/#{@c.id}/items",
      container_items_path(@c))
  end

  def test_singular_route
    assert_equal("/containers/#{@c.id}/items/#{@i.id}",
      container_item_path(@c,@i))
    assert_equal("/containers/#{@c.id}/items/#{@i.id}",
      container_item_path(@i))
  end

  def test_edit_route
    assert_equal("/containers/#{@c.id}/items/#{@i.id}/edit",
      edit_container_item_path(@i))
    assert_equal("/containers/#{@c.id}/items/#{@i.id}/edit",
      edit_container_item_path(@c,@i))
  end

  def test_new_route
    assert_equal("/containers/#{@c.id}/items/new",
      new_container_item_path(@c))
  end

  def test_plural_teachers_route
    assert_equal("/schools/#{@s.id}/departments/#{@d.id}/teachers",
      school_department_teachers_path(@d))
    assert_equal("/schools/#{@s.id}/departments/#{@d.id}/teachers",
      school_department_teachers_path(@s,@d))
  end

  def test_singular_teachers_route
    assert_equal("/schools/#{@s.id}/departments/#{@d.id}/teachers/#{@t.id}",
      school_department_teacher_path(@t))
  end

  def test_edit_teachers_route
    assert_equal("/schools/#{@s.id}/departments/#{@d.id}/teachers/#{@t.id}/edit",
      edit_school_department_teacher_path(@t))
  end

  def test_new_teachers_route
    assert_equal("/schools/#{@s.id}/departments/#{@d.id}/teachers/new",
      new_school_department_teacher_path(@d))
  end

  def test_new_teachers_route_inferring_department_from_teacher
    assert_equal("/schools/#{@s.id}/departments/#{@d.id}/teachers/new",
      new_school_department_teacher_path(@t))
  end
end
