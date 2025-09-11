class RemoveInvestmentReturnYearsFromPrinters < ActiveRecord::Migration[8.0]
  def change
    remove_column :printers, :investment_return_years, :integer
  end
end
