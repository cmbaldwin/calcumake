class InitializeNextInvoiceNumberForExistingUsers < ActiveRecord::Migration[8.0]
  def up
    # Initialize next_invoice_number for existing users
    User.find_each do |user|
      # Find the highest invoice number for this user
      last_invoice = Invoice.where(user: user)
                           .where("invoice_number ~ ?", '^INV-[0-9]+$')
                           .order("CAST(SUBSTRING(invoice_number FROM 'INV-([0-9]+)') AS INTEGER) DESC")
                           .first

      if last_invoice && last_invoice.invoice_number =~ /INV-(\d+)/
        next_number = $1.to_i + 1
      else
        next_number = 1
      end

      user.update_column(:next_invoice_number, next_number)
    end
  end

  def down
    # Set all next_invoice_number fields to 1
    User.update_all(next_invoice_number: 1)
  end
end
