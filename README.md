# ModelTranscribers

The gem can help you copy attribute values from a model (**progenitor**) to another model (**transcript**) in real time.

A new record of a transcript will also be created just right after the new record of the progenitor has been created.

If any value of mapped attributes in the progenitor has been changed, the value of the corresponding attributes in the transcript will be updated automatically.

Any updating and creating won't trigger ActiveRecord callbacks.

# Install

Add this line to your applocation's Gemfile:
```
gem 'model_transcribers'
```
And then execute:
```
$ bundle install
```
We also need to add a foreign_key called progenitor_id to the transcript table（For example, let's say the progenitor model is ***Student*** and its transcript is ***User***):
```
$ rails g migration AddProgenitorIdToUser progenitor_id:integer
```

## Usage

In progenitor model:
```ruby
# Student is a progenitor model.
class Student < ActiveRecord::Base

  include ModelTranscribers

  # User is a transcript model.
  sync transcript: User do
    copy_attr from: :id_number, to: :account
    copy_attr from: :phone_number, to: :phone_number
    copy_attr from: :status, to: :status,
              by: lambda {
                case self.status
                when :enrolled then :active
                when :suspension then :inactive
              }
    assign_attr to: :role, by: -> { 'Student' }
    assign_attr to: :name, by: -> { "#{first_name} #{last_name}" }
  end
end
```

Copy value between the same name attributes:
```ruby
copy_attr from: :phone_number, to: :phone_number
```

Copy value from a attribute to another:
```ruby
copy_attr from: :id_number, to: :account
```

Copy value by extra work:
```ruby
copy_attr from: :status, to: :status,
          by: lambda {
            case self.status
            when :enrolled then :active
            when :suspension then :inactive
          }
```

Assign value directly:
```ruby
assign_attr to: :name, by: -> { "#{first_name} #{last_name}" }
```

Use association between a progenitor and its transcript:
```ruby
student = Student.take
student.transcript

user = User.find_by(progenitor: student)
user.progenitor
```

When you create a new record of progenitor, the corresponding transcript will also be created automatically:
```ruby
student = Student.create(first_name: 'Joey', last_name: 'Chung',
                         phone_number: '+88628825252',
                         status: :enrolled)

# Or user = User.find_by(progenitor_id: student.id)
user = student.transcript

puts user.name         # => "Joey Chung"
puts user.phone_number # => "+88628825252"
puts user.satus        # => :active
```

When you update an existing progenitor:
```ruby
student.update(status: :suspension)

user = student.transcript

puts user.status      # => :inactive
```


## Notice
If you mapped the same attribute in the **from:** twice, only the last mapping will be effective:
```ruby
copy_attr from: :name, to: :first_name, by: -> { name.split(' ').first }
copy_attr from: :name, to: :last_name, by: -> { name.split(' ').last } # Only this line will be effective.
```

## Contributing

1. Fork it ( http://github.com/hugtrueme/model_transcribers/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
