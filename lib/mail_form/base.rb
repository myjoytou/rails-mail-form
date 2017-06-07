module MailForm
  class Base
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    extend ActiveModel::Translation
    # 1) Add callbacks behavior
    extend ActiveModel::Callbacks
    include ActiveModel::Validations
    include ActiveModel::AttributeMethods  # 1) Attribute method behavior
    attribute_method_prefix 'clear_'       # 2) clear_ is attribute prefix

    include MailForm::Validators
    
    # 2) Define the callbacks. The line below will create both before_deliver
    # and after_deliver callbacks with the same semantics as in Active Record
    define_model_callbacks :deliver

    # 1) Define a class attribute and initialize it
    class_attribute :attribute_names
    self.attribute_names = []

    # 1) Add the attribute suffix
    attribute_method_suffix '?'

    def initialize(attributes = {})
      attributes.each do |attr, value|
        self.public_send("#{attr}=", value)
      end if attributes
    end

    def self.attributes(*names)
      attr_accessor(*names)

      # 3) Ask to define the prefix methods for the given attribute names
      define_attribute_methods(names)

      # 2) Add new names as they are defined
      self.attribute_names += names
    end

    def persisted?
      false
    end

    # 3) Change deliver to run the callbacks
    def deliver
      if valid?
        run_callbacks(:deliver) do
          MailForm::Notifier.contact(self).deliver
        end
      else
        false
      end
    end

    protected

    # 4) Since we declared a "clear_" prefix, it expects to have a 
    # "clear_attribute" method defined, which receives an attribute
    # name and implements the clearing logic
    def clear_attribute(attribute)
      send("#{attribute}=", nil)
    end

    # 2) Implement the logic required by the '?' suffix
    def attribute?(attribute)
      send(attribute).present?
    end
  end
end
