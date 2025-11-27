# frozen_string_literal: true

require "test_helper"

module Invoices
  class LineItemsTotalsComponentTest < ViewComponent::TestCase
    # Basic Rendering Tests

    test "renders with required attributes" do
      invoice = invoices(:one)

      render_inline(LineItemsTotalsComponent.new(
        invoice: invoice,
        currency: "USD"
      ))

      assert_selector ".border-top"
      assert_selector "table"
      assert_selector "td", text: /Subtotal/i
      assert_selector "td", text: /Total/i
    end

    test "displays subtotal with formatted currency" do
      invoice = invoices(:one)
      invoice.stub :subtotal, 1000.00 do
        render_inline(LineItemsTotalsComponent.new(
          invoice: invoice,
          currency: "USD"
        ))

        assert_selector "td[data-invoice-form-target='subtotal']", text: "$1,000.00"
      end
    end

    test "displays total with formatted currency" do
      invoice = invoices(:one)
      invoice.stub :total, 1100.00 do
        render_inline(LineItemsTotalsComponent.new(
          invoice: invoice,
          currency: "USD"
        ))

        assert_selector "td[data-invoice-form-target='total']", text: "$1,100.00"
      end
    end

    # Currency Formatting Tests

    test "handles JPY currency (no decimals)" do
      invoice = invoices(:one)
      invoice.stub :subtotal, 1000 do
        invoice.stub :total, 1100 do
          render_inline(LineItemsTotalsComponent.new(
            invoice: invoice,
            currency: "JPY"
          ))

          assert_selector "td[data-invoice-form-target='subtotal']", text: "¥1,000"
          assert_selector "td[data-invoice-form-target='total']", text: "¥1,100"
        end
      end
    end

    test "handles EUR currency" do
      invoice = invoices(:one)
      invoice.stub :subtotal, 1000.00 do
        invoice.stub :total, 1100.00 do
          render_inline(LineItemsTotalsComponent.new(
            invoice: invoice,
            currency: "EUR"
          ))

          assert_selector "td[data-invoice-form-target='subtotal']", text: "€1,000.00"
        end
      end
    end

    # Custom Styling Tests

    test "applies default wrapper class" do
      invoice = invoices(:one)

      render_inline(LineItemsTotalsComponent.new(
        invoice: invoice,
        currency: "USD"
      ))

      assert_selector "div.mt-4.pt-3.border-top"
    end

    test "applies custom wrapper class" do
      invoice = invoices(:one)

      render_inline(LineItemsTotalsComponent.new(
        invoice: invoice,
        currency: "USD",
        wrapper_class: "my-custom-class"
      ))

      assert_selector "div.my-custom-class"
      refute_selector "div.mt-4"
    end

    test "applies default table class" do
      invoice = invoices(:one)

      render_inline(LineItemsTotalsComponent.new(
        invoice: invoice,
        currency: "USD"
      ))

      assert_selector "table.table"
    end

    test "applies custom table class" do
      invoice = invoices(:one)

      render_inline(LineItemsTotalsComponent.new(
        invoice: invoice,
        currency: "USD",
        table_class: "table table-sm"
      ))

      assert_selector "table.table.table-sm"
    end

    # Layout Tests

    test "renders in offset column layout" do
      invoice = invoices(:one)

      render_inline(LineItemsTotalsComponent.new(
        invoice: invoice,
        currency: "USD"
      ))

      assert_selector ".row > .col-md-6.offset-md-6"
    end

    test "displays subtotal before total" do
      invoice = invoices(:one)

      render_inline(LineItemsTotalsComponent.new(
        invoice: invoice,
        currency: "USD"
      ))

      page = page_content
      subtotal_index = page.index("Subtotal")
      total_index = page.index("Total")

      assert subtotal_index < total_index, "Subtotal should appear before Total"
    end

    # Stimulus Data Attributes Tests

    test "includes data attributes for Stimulus targets" do
      invoice = invoices(:one)

      render_inline(LineItemsTotalsComponent.new(
        invoice: invoice,
        currency: "USD"
      ))

      assert_selector "td[data-invoice-form-target='subtotal']"
      assert_selector "td[data-invoice-form-target='total']"
    end

    # Edge Cases

    test "handles zero amounts" do
      invoice = invoices(:one)
      invoice.stub :subtotal, 0.0 do
        invoice.stub :total, 0.0 do
          render_inline(LineItemsTotalsComponent.new(
            invoice: invoice,
            currency: "USD"
          ))

          assert_selector "td[data-invoice-form-target='subtotal']", text: "$0.00"
          assert_selector "td[data-invoice-form-target='total']", text: "$0.00"
        end
      end
    end

    test "handles negative amounts" do
      invoice = invoices(:one)
      invoice.stub :subtotal, -100.00 do
        invoice.stub :total, -110.00 do
          render_inline(LineItemsTotalsComponent.new(
            invoice: invoice,
            currency: "USD"
          ))

          assert_selector "td[data-invoice-form-target='subtotal']", text: "-$100.00"
          assert_selector "td[data-invoice-form-target='total']", text: "-$110.00"
        end
      end
    end

    test "handles large amounts" do
      invoice = invoices(:one)
      invoice.stub :subtotal, 1_234_567.89 do
        invoice.stub :total, 1_357_024.68 do
          render_inline(LineItemsTotalsComponent.new(
            invoice: invoice,
            currency: "USD"
          ))

          assert_selector "td[data-invoice-form-target='subtotal']", text: "$1,234,567.89"
          assert_selector "td[data-invoice-form-target='total']", text: "$1,357,024.68"
        end
      end
    end

    # Translation Tests

    test "uses translations for labels" do
      invoice = invoices(:one)

      I18n.with_locale(:en) do
        render_inline(LineItemsTotalsComponent.new(
          invoice: invoice,
          currency: "USD"
        ))

        assert_selector "td strong", text: /Subtotal/i
        assert_selector "td strong", text: /Total/i
      end
    end

    private

    def page_content
      page.native.to_html
    end
  end
end
