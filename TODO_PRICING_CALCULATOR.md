# Pricing Calculator Enhancement TODO

## Completed ✅
- [x] Remove /demo route 
- [x] Put quick calculator at top of /3d-print-pricing-calculator
- [x] Update landing page link to point to /3d-print-pricing-calculator
- [x] Replace 'Sign Up To Save Your Projects' header content with quick calculator

## Remaining for Future Implementation 🔄

### 1. Add Responsive Sidebar to Print Pricing Calculator
Add the responsive JavaScript sidebar with live price updates from demo page to the full print pricing calculator (inside the app, not the public calculator page).

### 2. Add Failure Rate and Shipping Costs
- Add failure_rate (%) field to print pricing forms with live calculations
- Add shipping_cost field to print pricing forms
- Update calculations to include these costs

### 3. Add User Profile Defaults
- Add `default_failure_rate` to User model/profile
- Add `default_shipping_cost` to User model/profile
- Create migration for these fields

### 4. Add Currency-Based Defaults to Concern
- Add hard-coded defaults for failure rate in `CurrencyAwareDefaults` concern
- Add hard-coded defaults for shipping cost that change based on selected currency
- Example: USD might have $5 default shipping, JPY might have ¥500, etc.

### 5. Update PrintPricing Model Calculations
- Add `failure_rate` column to print_pricings table (decimal, percentage)
- Add `shipping_cost` column to print_pricings table (decimal)
- Update `total_cost` calculation to include:
  - Cost increase from failure rate: `subtotal * (failure_rate / 100)`
  - Shipping cost added to final total
- Update views to display these new fields
- Update forms to include these fields with defaults from user profile

### 6. Update JavaScript Calculator
- Modify advanced_calculator_controller.js to include failure rate and shipping in calculations
- Add UI elements for these fields in the calculator interface
- Ensure live updates when these values change

## Notes
- These enhancements should be implemented after the current PR is merged and deployed
- Focus on getting all tests passing first for the current changes
- The demo page has good examples of the sidebar implementation to reference
